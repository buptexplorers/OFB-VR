#this is the script to run the actor network 

import time
from collections import deque

import torch
import torch.nn.functional as F
from torch.autograd import Variable

from env import Environment
from model import ActorCritic


def test(rank, args, shared_model, counter,
         all_cooked_time, all_cooked_bw, all_vp_time, all_vp_unit):
    torch.manual_seed(args.seed + rank)

    env = Environment(args, all_cooked_time, all_cooked_bw, all_vp_time, all_vp_unit, random_seed=args.seed + rank)

    model = ActorCritic()

    model.eval()

    state = env.reset()
    reward_sum = 0
    done = True

    state_time = time.time()

    actions = deque(maxlen=100)
    episode_length = 0
    update = False
    log = open('log-2.txt', 'w')
    load = False
    while True:
        episode_length += 1
        if done or load:
            model.load_state_dict(shared_model.state_dict())
            load = False
            time.sleep(1)
            print('update model parameters')

        state = Variable(torch.FloatTensor(state))
        # print('state', state)
        logit, value = model(state.view(-1, 11, 8))
        prob = F.softmax(logit, dim=1)
        _, action = torch.max(prob, 1)
        state, reward, done, (action, vp_quality, ad_quality, out_quality, rebuf, cv, blank_ratio, reward, real_vp_bitrate) \
            = env.step(action.data.numpy()[0])
        update = True
        load = (episode_length % args.max_episode_length == 0)
        reward_sum = reward

        if update:
            print("Time {}, action {}, ({},{},{}), bitrate {:.3f}, rebuf {:.3f}, cv {:.3f}, black_ratio {:.3f}, reward {:.3f}, episode {}".format(
                time.strftime("%Hh %Mm %Ss", time.gmtime(time.time() - state_time)),
                action, vp_quality, ad_quality, out_quality, real_vp_bitrate, rebuf, cv, blank_ratio,
                reward_sum, episode_length))
            log.write(str(episode_length)+'\t'+ str(real_vp_bitrate)+ '\t' + str(rebuf) + '\t' + str(cv) + '\t' + str(reward) + '\n')
            if episode_length % 500 == 0:
                # pass
                path = 'result-1/actor.pt-' + str(episode_length)
                torch.save(model.state_dict(), path)
                print('saved one model in epoch:', episode_length)

            # episode_length = 0
            actions.clear()
        if done:
            state = env.reset()
