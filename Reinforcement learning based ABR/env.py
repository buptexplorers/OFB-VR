#coding=utf-8
#Please set the value of MSEfile, Sizefile according to the model type
import numpy as np
import torch
from torch.autograd import Variable
import math
import scipy.io as scio
from args import Args


class Environment:
    def __init__(self, args, all_cooked_time, all_cooked_bw, all_vp_time, all_vp_unit, random_seed=1):
        np.random.seed(random_seed)
        self.args = args

        self.MSEfile='BSL'          #Pano       OFB
        self.Sizefile='BSL_size'    #Pano_size  OFB_size
        self.MSE=self.readMSE()
        self.Size=self.readSize()
        self.tile_size = np.zeros(72, dtype = np.int16)
        self.size_per_tile = np.zeros((self.args.tile_row, self.args.tile_column, 7))
        self.MSE_per_tile = np.zeros((self.args.tile_row, self.args.tile_column, 7))
 
        self.all_vp_time = all_vp_time      
        self.all_vp_unit = all_vp_unit 
        self.vp_window_len = args.vp_window_len 

        self.all_cooked_time = all_cooked_time
        self.all_cooked_bw = all_cooked_bw

        self.video_seg_counter = 10 #start from the 11th second
        self.buffer_size = 0

        # pick a random viewport trace file, and a random start point in a file
        self.vp_idx = np.random.randint(len(self.all_vp_time))
        self.vp_time = self.all_vp_time[self.vp_idx]
        self.vp_unit = self.all_vp_unit[self.vp_idx]
        self.vp_sim_ptr = np.random.randint(40, len(self.vp_time)-100)
        self.vp_sim_ptr_max = len(self.vp_time) - 100
        self.vp_history = self._init_vp_history() 
        self.vp_real_future = self._real_vp_future()
        self.vp_playback_time = 0
        self.vp_preq_future = self._real_vp_future_noise

        # pick a random bandwidth trace file
        self.trace_idx = np.random.randint(len(self.all_cooked_time))
        self.cooked_time = self.all_cooked_time[self.trace_idx]
        self.cooked_bw = self.all_cooked_bw[self.trace_idx]
        # randomize the start point of the bandwidth trace
        self.mahimahi_ptr = np.random.randint(1, len(self.cooked_bw))
        self.last_mahimahi_time = self.cooked_time[self.mahimahi_ptr - 1]

        #self.video_size = self._get_video_size(args)  # in bytes, each tile size in a segment
        self.pred_tile_map = self._update_tile_map([[0.0, 0.0, 0.0]])
        self.real_tile_map = self._update_tile_map([[0.0, 0.0, 0.0]])
        if(self.args.versatile):
            self.real_tile_map = self._update_versaTile_map()#exp_num, video_num, sec c.c.
        self.action_map = self._set_action_map()
        #self.vp_sizes, self.ad_sizes, self.out_sizes = self._get_tile_area_sizes()
        self.state = np.zeros((args.s_info, args.s_len))

        self.last_real_vp_bitrate = 1  # should be the default quality for viewport

        # normalize state
        self.state_mean = 0
        self.state_std = 0
        self.alpha = 0.999
        self.num_steps = 0

    def readMSE(self):
        dataFile = './MatData/'+self.MSEfile+'.mat'
        data = scio.loadmat(dataFile)
        print(type(data))
        print(data.keys())
        MSE = data[self.MSEfile] 
        # print(size)
        return MSE

    def readSize(self):
        dataFile = './MatData/'+self.Sizefile+'.mat'
        data = scio.loadmat(dataFile)
        print(type(data))
        print(data.keys())
        size = data[self.Sizefile]/8000  #K byte
        if(self.args.versatile == 0):
            re_size = np.ones((70,72,7))
            for i in range(size.shape[0]):
                re_size[i,:,:] = size[i,:,:]/72
            size = re_size
        return size

    #initialize historic viewpoint track
    def _init_vp_history(self):
        self.vp_idx = np.random.randint(len(self.all_vp_time))
        self.vp_time = self.all_vp_time[self.vp_idx]
        self.vp_unit = self.all_vp_unit[self.vp_idx]
        self.vp_sim_ptr = np.random.randint(40, len(self.vp_time)-100)
        self.vp_sim_ptr_max = len(self.vp_time) - 100
        self.vp_playback_time = 0
        vp_history = self.vp_unit[self.vp_sim_ptr - self.vp_window_len: self.vp_sim_ptr]
        return vp_history

    #update historic viewpoint trajacity
    def _update_vp_history(self, delay, rebuffer, sleep):
        self.vp_playback_time = delay - rebuffer + sleep
        self.vp_sim_ptr += math.floor(self.vp_playback_time / 33.3)
        if self.vp_sim_ptr <= self.vp_sim_ptr_max:
            self.vp_history = self.vp_unit[self.vp_sim_ptr - self.vp_window_len: self.vp_sim_ptr]
        else:
            self.vp_history = self._init_vp_history()

    #get real future viewpoint trajacity
    def _real_vp_future(self):
        buffer_frame_len = math.floor(self.buffer_size / 33.3)
        start = self.vp_sim_ptr + buffer_frame_len
        end = start + 30
        return self.vp_unit[start: end]

    # @staticmethod
    # def _load_predictor(args):
    #     def init_hidden(num_layers, hidden_size):
    #         hx = torch.nn.init.xavier_normal(torch.randn(num_layers, 1, hidden_size))
    #         cx = torch.nn.init.xavier_normal(torch.randn(num_layers, 1, hidden_size))
    #         hidden = (Variable(hx, volatile=True), Variable(cx, volatile=True))  # convert to Variable as late as possible
    #         return hidden
    #     model = torch.load(args.predictor_path, map_location='cpu')
    #     model.hidden = init_hidden(1, 128)
    #     return model

    #get noised real future viewpoint trajacity to simulate viewpoint pridiction
    def _real_vp_future_noise(self):
        buffer_frame_len = math.floor(self.buffer_size / 33.3)
        start = self.vp_sim_ptr + buffer_frame_len
        end = start + 30
        res = self.vp_unit[start:end] + np.random.uniform(-0.3, 0.3,(30,3))#可能有越界问题？
        res = np.mod(res+1,2)-1
        # print('real vp future', buffer_frame_len, start, end)
        return res

    #update tiling group of the current second for Pano and OFB-VR
    #when using fixed size tiling, load a default grouping scheme instead
    def _update_versaTile_map(self):
        def versaTile_visualize(tile_data):
            tile_map = np.zeros((12,24), dtype=int)
            i = 0
            for tile in tile_data:
                i += 1
                for x in range(tile[1]-tile[0]+1):
                    for y in range(tile[3]-tile[2]+1):
                        tile_map[tile[0]+x-1][tile[2]+y-1] = i
            return tile_map


        frame = self.video_seg_counter * 30 + 1
        if(self.args.versatile == 0):
            path = './MatData/BSL.txt'
        else: 
            path = self.args.versaTilePath + str(self.video_seg_counter*30+331)+'/1.txt'
        
        tile_data = np.loadtxt(path, dtype = np.int)
        tile_data = tile_data[:, [1,2,3,4,0]]
        pred_done = False
        real_done = False
        for tile in tile_data:
            self.args.tile_size[tile[4]-1] = (tile[1]-tile[0]+1)*(tile[3]-tile[2]+1)
            for x in range(tile[1]-tile[0]+1):
                if(pred_done & real_done): break
                for y in range(tile[3]-tile[2]+1):
                    if(pred_done & real_done): break
                    # if part of a versaTile get involved in adjacent area, count it as adjacent
                    if self.pred_tile_map[tile[0]+x-1][tile[2]+y-1] == 2:
                        self.pred_tile_map[tile[0]-1:tile[1],tile[2]-1:tile[3]] = 2
                        pred_done = True
                    if self.real_tile_map[tile[0]+x-1][tile[2]+y-1] == 2:
                        self.real_tile_map[tile[0]-1:tile[1],tile[2]-1:tile[3]] = 2
                        real_done = True
            # update average MSE and bandwidth distribution accordingly
            MSE_tuple = self.MSE[self.video_seg_counter+1][tile[4]-1]
            self.MSE_per_tile[tile[0]-1:tile[1],tile[2]-1:tile[3]] = MSE_tuple
            tile_size = (tile[0]-1-tile[1])*(tile[2]-1-tile[3])
            size_tuple = self.Size[self.video_seg_counter+1][tile[4]-1]/tile_size
            self.size_per_tile[tile[0]-1:tile[1],tile[2]-1:tile[3]] = size_tuple

    # calculate vp, ad and out area respectively according to current viewpoint
    def _update_tile_map(self, vp_future):
        def rotation_to_vp_tile(yaw, pitch, tile_column, tile_row, vp_length, vp_height, tile_map, tag):
            tile_length = 360 / tile_column
            tile_height = 180 / tile_row

            vp_pitch = pitch + 90
            vp_up = vp_pitch + vp_height / 2
            if vp_up > 180:
                vp_up = 179
            vp_down = vp_pitch - vp_height / 2
            if vp_down < 0:
                vp_down = 0

            vp_yaw = yaw + 180
            vp_part = 1
            vp_left = vp_yaw - vp_length / 2
            vp_right = vp_yaw + vp_length / 2
            if vp_left < 0:
                vp_part = 2
                vp_left_1 = 0
                vp_left_2 = vp_left + 360
                vp_right_1 = vp_right
                vp_right_2 = 359
            if vp_right > 360:
                vp_part = 2
                vp_right_1 = vp_right - 360
                vp_right_2 = 359
                vp_left_1 = 0
                vp_left_2 = vp_left

            def get_tiles(left, right, up, down, tag):
                col_start = math.floor(left / tile_length)
                col_end = math.floor(right / tile_length)
                row_start = math.floor(down / tile_height)
                row_end = math.floor(up / tile_height)
                count = 0
                for row in range(row_start, row_end + 1):
                    for col in range(col_start, col_end + 1):
                        count += 1
                        if tile_map[row][col] != 1:  # if tile is not vp, then is set tag
                            tile_map[row][col] = tag
                return count

            tile_count = 0
            if vp_part == 1:
                tile_count = get_tiles(vp_left, vp_right, vp_up, vp_down, tag)
            if vp_part == 2:
                tile_count = get_tiles(vp_left_1, vp_right_1, vp_up, vp_down, tag)
                tile_count += get_tiles(vp_left_2, vp_right_2, vp_up, vp_down, tag)

        args = self.args
        tile_map = np.zeros((args.tile_row, args.tile_column), dtype=int)
        for rotation in vp_future:  # set vp tile tag
            pitch = rotation[1] * 180 / math.pi
            yaw = rotation[2] * 180 / math.pi
            rotation_to_vp_tile(yaw, pitch, args.tile_column, args.tile_row, args.vp_length, args.vp_height,
                                tile_map, 1)
        for rotation in vp_future:  # set ad tile tag
            pitch = rotation[1] * 180 / math.pi #c.c.
            yaw = rotation[2] * 180 / math.pi
            rotation_to_vp_tile(yaw, pitch, args.tile_column, args.tile_row, args.ad_length, args.ad_height,
                                tile_map, 2)
        return tile_map

    # action space initialization
    @staticmethod
    def _set_action_map():
        vp_levels = [0, 1, 2, 3, 4, 5]
        ad_levels = out_levels = [0, 1, 2, 3, 4, 5]
        action_map = []
        for vp in range(len(vp_levels)):
            for ad in range(len(ad_levels)):
                for out in range(len(out_levels)):
                    action_map.append((vp_levels[vp], ad_levels[ad], out_levels[out]))
        return action_map

    # get reward scores of the current action
    def _get_states_rewards(self, vp, ad, out):
        q = [out, vp, ad]
        # get the average real-viewport bitrate according to the downloaded three areas.
        args = self.args
        sum_bitrate = [0, 0, 0]
        for row in range(args.tile_row):
            for column in range(args.tile_column):
                if self.pred_tile_map[row][column] != 0:
                    sum_bitrate[self.pred_tile_map[row][column]] += self.size_per_tile[row][column][q[self.pred_tile_map[row][column]]]
        out_bitrate, vp_bitrate, ad_bitrate = sum_bitrate[0], sum_bitrate[1], sum_bitrate[2]
        # get the average MSE according of the user's viewport.
        count = [0, 0, 0]
        sumMSE = 0
        for row in range(args.tile_row):
            for column in range(args.tile_column):
                if self.real_tile_map[row][column] != 0:
                    count[self.pred_tile_map[row][column]] += 1
                    sumMSE += self.MSE_per_tile[row][column][q[self.pred_tile_map[row][column]]]
        out_count, vp_count, ad_count = count[0], count[1], count[2]

        real_vp_bitrate = 8*(vp_bitrate + ad_bitrate + out_bitrate) # change to Mbps
        
        # get accuracy
        total_count = vp_count + ad_count + out_count
        #calculate average PSNR-OF
        meanMSE = min(200, 20 * (np.log(255) - 0.5 * np.log(sumMSE/total_count/14400)) / np.log(10));
        vp_acc = vp_count / total_count
        ad_acc = ad_count / total_count
        out_acc = out_count / total_count

        # get spatial quality variance
        mean = real_vp_bitrate / total_count
        sum_pow = vp_count * ((vp_bitrate - mean)**2) + ad_count * ((ad_bitrate - mean)**2) + out_count * ((out_bitrate - mean)**2)
        std = math.sqrt(sum_pow / (total_count - 1))
        cv = std / mean

        # get blank area percentage
        blank_count = 0
        if ad_bitrate == 0:
            blank_count += ad_count
        if out_bitrate == 0:
            blank_count += out_count
        blank_ratio = blank_count / total_count

        return real_vp_bitrate, vp_acc, ad_acc, out_acc, cv, blank_ratio, meanMSE

    # update the environment according to the current action
    def step(self, action):
        vp_quality, ad_quality, out_quality = self.action_map[action]
        vp_quality =  vp_quality
        ad_quality = ad_quality
        out_quality = out_quality
        q = [out_quality, vp_quality, ad_quality]
        sum_bitrate = [0, 0, 0]
        # calculate the total size that need to be downloaded
        for row in range(self.args.tile_row):
            for column in range(self.args.tile_column):
                if self.pred_tile_map[row][column] != 0:
                    sum_bitrate[self.pred_tile_map[row][column]] += self.size_per_tile[row][column][q[self.pred_tile_map[row][column]]]
        out_bitrate, vp_bitrate, ad_bitrate = sum_bitrate[0], sum_bitrate[1], sum_bitrate[2]
        video_seg_size = 1000000*(out_bitrate + vp_bitrate + ad_bitrate)#Bps
        # use the delivery opportunity of mahimahi
        delay = 0.0  # seconds
        video_seg_counter_sent = 0.0  # bytes

        while True:  # download onw video segment
            throughput = 1/2*self.cooked_bw[self.mahimahi_ptr] * self.args.b_in_mb / self.args.bits_in_byte  # change to Bps
            duration = self.cooked_time[self.mahimahi_ptr] - self.last_mahimahi_time  # seconds
            packet_load = throughput * duration * self.args.packet_payload_portion # actual network throughput

            if video_seg_counter_sent + packet_load > video_seg_size:
                fractional_time = (video_seg_size - video_seg_counter_sent) / throughput / self.args.packet_payload_portion
                delay += fractional_time
                self.last_mahimahi_time += fractional_time
                break

            video_seg_counter_sent += packet_load
            delay += duration
            self.last_mahimahi_time = self.cooked_time[self.mahimahi_ptr]
            self.mahimahi_ptr += 1

            if self.mahimahi_ptr >= len(self.cooked_bw):
                self.mahimahi_ptr = 1
                self.last_mahimahi_time = 0

        delay *= self.args.milliseconds_in_second  # ms
        delay += self.args.link_rtt
        # add a multiplicative noise to the delay
        delay *= np.random.uniform(self.args.noise_low, self.args.noise_high)

        # rebuffer time
        rebuf = np.maximum(delay - self.buffer_size, 0.0) #单位毫秒

        # update the buffer
        self.buffer_size = np.maximum(self.buffer_size - delay, 0.0)

        # add in the new seg in the buffer
        self.buffer_size += self.args.video_seg_len

        # sleep if the buffer gets too large
        sleep_time = 0
        if self.buffer_size > (self.args.buffer_thresh - 1000.0):
            # exceed 2 seconds
            # then predict the 3rd second viewport to download
            # we need to skip some network bandwidth here
            # but do not add up the delay
            drain_buffer_time = self.buffer_size - (self.args.buffer_thresh - 1000.0)
            sleep_time = np.ceil(drain_buffer_time / self.args.drain_buffer_sleep_time) * self.args.drain_buffer_sleep_time
            self.buffer_size -= sleep_time

            while True:
                duration = self.cooked_time[self.mahimahi_ptr] - self.last_mahimahi_time
                if duration > sleep_time / self.args.milliseconds_in_second:
                    self.last_mahimahi_time += sleep_time / self.args.milliseconds_in_second
                    break
                sleep_time -= duration * self.args.milliseconds_in_second
                self.last_mahimahi_time = self.cooked_time[self.mahimahi_ptr]
                self.mahimahi_ptr += 1

                if self.mahimahi_ptr >= len(self.cooked_bw):
                    self.mahimahi_ptr = 1
                    self.last_mahimahi_time = 0

        # one segment finished
        self.video_seg_counter += 1
        video_seg_remain = self.args.total_video_seg - self.video_seg_counter
        done = False
        if self.video_seg_counter >= self.args.total_video_seg:# if all segments are finished
            done = True
            self.reset()

        self._update_vp_history(delay=delay, rebuffer=rebuf, sleep=sleep_time)  # update viewpoint trajectory
        pred_vp_future = self._real_vp_future_noise()                           # simulated viewpoint prediction
        self.pred_tile_map = self._update_tile_map(pred_vp_future)              # load the next second's versaTile map

        real_vp_future = self._real_vp_future()                                 # load real viewpoint
        self.real_tile_map = self._update_tile_map(real_vp_future)              # load real tile map of the next second       
        self._update_versaTile_map()
        real_vp_bitrate, vp_acc, ad_acc, out_acc, cv, blank_ratio, MSE = self._get_states_rewards(vp_quality, ad_quality,out_quality)

        
        uMSE = (MSE-55)/5
        # dequeue history
        self.state = np.roll(self.state, -1, axis=1)
        # this should be S_INFO number of terms
        self.state[0, -1] = uMSE  # last quality (not normalized !!)
        self.state[1, -1] = self.buffer_size / 1000 / self.args.buffer_norm_factor  # (buffer size)
        self.state[2, -1] = float(video_seg_size) / float(delay) / 1000  # kilo byte / ms (throughput)
        self.state[3, -1] = float(delay) / 1000 / self.args.buffer_norm_factor  # (delay time s)
        self.state[4, :self.args.qp_levels] = np.array(vp_bitrate) / 1000 / 1000  # mega byte (vp)
        self.state[5, :self.args.qp_levels] = np.array(ad_bitrate) / 1000 / 1000  # mega byte (ad)
        self.state[6, :self.args.qp_levels] = np.array(out_bitrate) / 1000 / 1000  # mega byte (out)
        self.state[7, -1] = video_seg_remain / self.args.total_video_seg
        self.state[8, -1] = vp_acc  # pred_vp accuracy
        self.state[9, -1] = ad_acc  # pred_ad accuracy
        self.state[10, -1] = out_acc  # pred_out accuracy

        # reward is PSNR-OF - rebuffer penalty - blank tiles percentage
        # the reward function is not complete now, needed to be modified later
        reward = self.args.quality_penalty * real_vp_bitrate \
                 + self.args.MSE_penalty * uMSE \
                 - self.args.rebuf_penalty * rebuf / 1000 \
                 - self.args.blank_penalty * blank_ratio \
                 - self.args.smooth_penalty * np.abs(real_vp_bitrate - self.last_real_vp_bitrate) \
                 - self.args.cv_penalty * cv 

        self.last_real_vp_bitrate = real_vp_bitrate
        return self.state, reward, done, (action, vp_quality, ad_quality, out_quality, rebuf, MSE, blank_ratio, reward, real_vp_bitrate)

    def reset(self):
        self.buffer_size = 0
        self.video_seg_counter = 10
        self.last_real_vp_bitrate = 1
        self.vp_playback_time = 0

        # pick a random bandwidth trace file
        self.trace_idx = np.random.randint(1,len(self.all_cooked_time))
        self.cooked_time = self.all_cooked_time[self.trace_idx]
        self.cooked_bw = self.all_cooked_bw[self.trace_idx]

        # randomize the start point of the bandwidth trace
        self.mahimahi_ptr = np.random.randint(1, len(self.cooked_bw))
        self.last_mahimahi_time = self.cooked_time[self.mahimahi_ptr - 1]

        self.state = np.zeros((self.args.s_info, self.args.s_len))
        self.vp_history = self._init_vp_history()
        self.pred_tile_map = self._update_tile_map([[0.0, 0.0, 0.0]])
        self.real_tile_map = self._update_tile_map([[0.0, 0.0, 0.0]])

        # normalize state
        self.state_mean = 0
        self.state_std = 0
        self.alpha = 0.999
        self.num_steps = 0

        return self.state

    @staticmethod
    def sample_action():
        return np.random.randint(0, 150)
