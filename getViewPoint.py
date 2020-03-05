import sys
import math
import numpy as np
import pandas as pd

def quart2xyz(x,y,z,w):  
  r = math.atan2(2*(w*x+y*z),1-2*(x*x+y*y))
  p = math.asin(2*(w*y-z*z))
  y = math.atan2(2*(w*z+x*y),1-2*(z*z+y*y))

  angleR = r*180/math.pi
  angleP = p*180/math.pi
  angleY = y*180/math.pi

  print (angleR,angleP,angleY)#翻滚,俯仰,偏航


def getQuartMatrix(x,y,z,w):
  rotateMatrix = np.mat([[1-2*np.square(y)-2*np.square(z), 2*x*y-2*w*z, 2*x*z+2*w*y],
			[2*x*y+2*w*z, 1-2*np.square(x)-2*np.square(z), 2*y*z-2*w*x],
			[2*x*z-2*w*y, 2*y*z+2*w*x, 1-2*np.square(x)-2*np.square(y)]])
  return rotateMatrix

def xyz2lonlat(coord):
  x = coord[0]
  y = coord[1]
  z = coord[2]
  lon = math.atan2(y,x)/math.pi
  lat = math.atan2(z,np.sqrt(np.square(x)+np.square(y)))/math.pi
  lat = (lat%1)/2
  lon = (lon%1)/2
  return [lon,lat]


import csv
import os
import numpy as np
import random
import requests
import pandas as pd

if __name__ == '__main__':
  csvHome = 'traj/Experiment_1/'
  for uid in range(1,11):
    for vid in range(1,2):
      print('processing user:'+str(uid)+' video:'+str(vid))
      data_list = []
      csvPath = csvHome + str(uid) + '/video_' + str(vid) + '.csv'
      if os.path.exists(csvPath):
        csv_data = pd.read_csv(csvPath, usecols = ['Timestamp',
						'UnitQuaternion.x',
						'UnitQuaternion.y',
						'UnitQuaternion.z',
						'UnitQuaternion.w']) 
        time = csv_data.iloc[0,0]
        time_stamp = time.split(':',2)
        time_base = 60*float(time_stamp[1])+float(time_stamp[2])
        time_stamp_idx = 0
        for i in range(csv_data.shape[0]):
          time_temp = csv_data.iloc[i,0]
          time_stamp_temp = time_temp.split(':',2)
          time_delta = 60*float(time_stamp_temp[1])+float(time_stamp_temp[2])-time_base
          if time_delta <= 1/30:
            continue
          else:
            temp = csv_data.iloc[time_stamp_idx:i,1:]
            quart_data = temp.mean()
            rot_matrix = getQuartMatrix(quart_data[0],quart_data[1],quart_data[2],quart_data[3])
            data_list.append(xyz2lonlat(rot_matrix*[[1],[0],[0]]))
            time_base = time_base + 1/30
            time_stamp_idx = i
        traj_data = pd.DataFrame(data_list)
        traj_data.to_csv('test'+str(vid)+'.txt', sep = '\t', header=False)
	









        
