#this is the script to carry on A3C training
import torch
import torch.multiprocessing as mp
import os

from model import ActorCritic
from args import Args
from train import train
from test import test


if __name__ == '__main__':
    os.environ['OMP_NUM_THREADS'] = '1'
    torch.set_num_threads(1)

    import sys, inspect

    current_dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
    parent_dir = os.path.dirname(current_dir)
    sys.path.insert(0, parent_dir)
    from load_bw_traces import load_trace
    from load_viewport_trace import load_viewport_unit

    test_bw_trace_folder = './datasets/bw_trace/sim_belgium/'
    bw_trace_folder = './datasets/bw_trace/train_sim_traces_10-25_norway/'
    vp_trace_folder = './datasets/viewport_trace/Pano_test/'
    print(vp_trace_folder)
    
    args = Args()
    torch.manual_seed(args.seed)
    all_cooked_time, all_cooked_bw, _ = load_trace(bw_trace_folder)
    test_all_cooked_time, test_all_cooked_bw, _ = load_trace(test_bw_trace_folder)
    all_vp_time, all_vp_unit = load_viewport_unit(vp_trace_folder)
    model = ActorCritic()
    model_path = 'result-1/base'        #default checkpoit to resume training
    model.load_state_dict(torch.load(model_path))
    model.share_memory()
    print(model)
    processes = []

    counter = mp.Value('i', 0)
#    test(args.num_processes, args, model, counter,test_all_cooked_time, test_all_cooked_bw, all_vp_time, all_vp_unit)
    lock = mp.Lock()
    #initialize one actor network and several critic networks to perform A3C training
    p = mp.Process(target=test, args=(args.num_processes, args, model, counter,
                                      test_all_cooked_time, test_all_cooked_bw, all_vp_time, all_vp_unit))
    p.start()
    processes.append(p)

    for rank in range(0, args.num_processes):
        p = mp.Process(target=train, args=(rank, args, model, counter, lock,
                                           all_cooked_time, all_cooked_bw, all_vp_time, all_vp_unit))
        p.start()
        processes.append(p)
    for p in processes:
        p.join()
