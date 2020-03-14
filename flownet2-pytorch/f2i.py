import numpy as np
import scipy.io as sio
import os

path = 'result/inference/run.epoch-0-flow-field/'

files =os.listdir(path)

for _file in files:
  __file = os.path.splitext(_file)
  if __file[1] == '.flo':
    with open(path + _file, 'r') as flo:
      tag = np.fromfile(flo, np.float32, count=1)[0]
      width = np.fromfile(flo, np.int32, count=1)[0]
      height = np.fromfile(flo, np.int32, count=1)[0]
      tmp = np.fromfile(flo, np.float32, count= 2 * width * height)
      flow = np.resize(tmp, (int(height), int(width), 2))
      sio.savemat(path + __file[0] + '.mat', {'flow':flow})
