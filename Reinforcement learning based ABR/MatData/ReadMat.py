# coding:UTF-8

import scipy.io as scio

class Environment:
    def __init__(self):
        self.MSEfile = 'BSL'
        self.Sizefile = 'BSL_size'
        self.MSE = self.readMSE()
        self.Size = self.readSize()

    def readMSE(self):
        dataFile = './' + self.MSEfile + '.mat'
        data = scio.loadmat(dataFile)
        print(type(data))
        print(data.keys())
        MSE = data[self.MSEfile]  # 注意维度相反qp×tile×time
        # print(size)
        return MSE

    def readSize(self):
        dataFile = './' + self.Sizefile + '.mat'
        data = scio.loadmat(dataFile)
        print(type(data))
        print(data.keys())
        size = data[self.Sizefile]  # 注意维度相反qp×tile×time
        # print(size)
        return size

if __name__ == "__main__":
    bw_trace_folder = '../../datasets/bw_trace/sim_belgium/'
    vp_trace_folder = '../../datasets/viewport_trace/new_cooked_train_dataset/'

    env = Environment()
    print(env.Size)
"""
dataFile = './'+'BSL_size'+'.mat'
data = scio.loadmat(dataFile)
print(type(data))
print(data.keys())
size = data['BSL_size'] #注意维度相反qp×tile×time
print(size)
"""