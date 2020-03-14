# OFB-VR
## Introduction

## System Requirements
### FlowNet2.0 -- python 3
* numpy
* PyTorch
* scipy
* scikit-image
* tensorboardX
* colorama, tqdm, setproctitle

## Runing

### Optical Flow Estimation


#### 1)Installation
Install basic version of FlowNet2.
```
cd flownet2-pytorch
# install custom layers
bash install.sh
```

download the [pre-trained model](https://drive.google.com/file/d/1hF8vS6YeHkx3j2pfCeQqqZGwA_PJq_Da/view?usp=sharing) and place it in the flownet2-pytorch directory.

#### 2)Dataset Preperation
To get optical flow estimation of each frame, the frist thing to do is cutting original video into 1 second chunks and extracting image of each frame.
```
# run extracting script
matlab -nodesktop -nosplash cutChunk
matlab -nodesktop -nosplash extractFrame
```
For cutChunk.m, you may set the correct parameters 'set' (Line 10), 'vid' (Line 11) according to the needs of the experiment.

For extractFrame.m, you may set the correct parameters 'set' (Line 5), 'vid' (Line 6), 'sec' (Line 10) according to the needs of the experiment.

Since FlowNet2 can not run detection on raw images of 2880*1440 resolution, we need to downsample the input images first.
```
# return to OFV-VR project root
cd ..
# run the downsample script
matlab -nodesktop -nosplash downSample
```
#### 3)Inference
download the [pre-trained model](https://drive.google.com/file/d/1hF8vS6YeHkx3j2pfCeQqqZGwA_PJq_Da/view?usp=sharing) and place it in the same directory of FlowNet2 code.

If you want to use other datasets as input, please modify your command according to the detailed instruction in the official [FlowNet2.0](https://github.com/NVIDIA/flownet2-pytorch) documentation. Following the command attached below can merely work in the given dataset.
```
python3 main.py --inference --model FlowNet2 
    --save_flow \
    --inference_dataset ImagesFromFolder \
    --inference_dataset_root video2_re \
    --resume FlowNet2_checkpoint.pth.tar \
    --save result
# move result to PSNR-OF calculation module
mv flownet2-pytorch/result/inference/run.epoch-0-flow-field/*.flo XXXX/orgFlow/1/1/continuesFlo/
```

### PSNR-OF Calculation and Tile Grouping


#### 1)Quantify Tiles
Run matlab file to calculate JND value for all basic tiles according to static image, relative speed and velocity depth of each pixel. Combining JND with trace of users, we can get ratio value as the quantification result of the awareness of quality distortion from all tiles.
```
# run calculation script
matlab -nodesktop -nosplash AllTileValueness
```
Before running, check the following parameters if they are correct.

  'set' (Line 10), 'vid' (Line 11), 'sec' (Line 24) - Match the value in extractFrame.m mentioned in 2)
  
  'usernum' (Line 12) - Decide how many calculation results will be stored, ranged 1-48
  
Parameters in related file:

  'usernum' (calcTileMse.m Line 14; calcTileMseFlow.m Line 14) - A larger usernum leads to a more accurate calculation result, suggested range 10-48
  
  'frameBase' (calcTileMseFlow.m Line 15) - Change it according to the optical flow files, e.g. 20 if optical files generate from the 20th second

#### 2)Tile Grouping
Run a C++ code to generate a versatile-size tiling scheme for videos. This process is similar to a 2-dimensions clustering.
```
# run tiling script
g++ tilingDP/main_ori.cpp -o temp
./temp
```
Before running, check the following parameters if they are correct.

  'SumUser' (Line 19), 'set' (Line 245), 'video' (Line 247) - Match the value in AllTileValueness.m
  
  'i' (Line 250) - Set the correct parameters according to total time in reinforcement learning, refer to frameAbs in file like ‘calcTileMse.m’ or output folder like ‘ratio’
  
  'filename' (Line 254) - For Pano set ‘ratio’, OFB-VR set ‘ratioF’
  
  'dir' (Line 358), 'outputfile' (Line 381) - For Pano set ‘tiling1004’, OFB-VR set ‘tiling1003’

#### 3)Get PSNR-OF
Combining data of users' traces and tiling schemes, run another matlab code to calculate and store MSE value and size of tiles. These data are actually normalized PSNR-OF data and are prepared for reinforcement learning evaluation.
```
matlab -nodesktop -nosplash TransToRL
```
Before running, check the following parameters if they are correct.

  'set' (Line 10), 'vid' (Line 11), 'usernum' (Line 19), 'sec' (Line 36) - Match the value in AllTileValueness.m
  
  zeros(70,~,~) (Line 59-67), 'SecNo' (Line 70,77,84,91,98,111,117,123) - 70 match the total time in reinforcement learning
  
Parameters in related file:

  'nUser' (PlatoForRL.m Line 5; PanoForRL.m Line 3; OFB_VRForRL.m Line 3) - Match the number in TransToRL.m
  
  'usernum' (calcTileMseForRL.m Line 14; calcTileMseFlowForRL.m Line 14) - A larger usernum leads to a more accurate calculation result, suggested range 10-48
  
  'frameBase' (calcTileMseFlowForRL.m Line 15) - Match the number in AllTileValueness.m

### Reinforcement Learning
Before running, please set parameters in args.py, line 59 - 63, accordingly at first.
```python
        self.tile_column = 12       # change to 24 while using Pano and OFB-VR
        self.tile_row = 6           # change to 12 while using Pano and OFB-VR
        self.MSEfile='BSL'          #Pano       OFB
        self.Sizefile='BSL_size'    #Pano_size  OFB_size
        self.versatile = 0          #30         30
```
#### Test
Pre-trained models of our scheme and two baselines, Pano and Plato, are given in the "saved/" directory. If you want to test the result of existing models, run "main_test.py". 
```
python3 main_test.py
```
#### train
```
python3 main_train.py
```

## Acknowledgement
Parts of codes in this project is based on the solid work of [Pano](https://github.com/louisqw/PanoProject) and [Plato](https://github.com/federerjiang/Plato). Our scheme is inspired by those two papers to apply JND and reinforcement learning in VR streaming. Besides, our optical flow estimation takes advantage of the state-of-the-art real-time optical flow detection model [FlowNet2.0](https://github.com/NVIDIA/flownet2-pytorch). 

Tanks to the selflessness and contribution of the projects mentioned above. We won't be able to achieve this project without them.
