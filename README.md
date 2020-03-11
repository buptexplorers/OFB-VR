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

#### Installation
Install basic version of FlowNet2.
```
cd flownet2-pytorch
# install custom layers
bash install.sh
```
download the [pre-trained model](https://drive.google.com/file/d/1hF8vS6YeHkx3j2pfCeQqqZGwA_PJq_Da/view?usp=sharing) and place it in the flownet2-pytorch directory.

#### Dataset Preperation
To get optical flow estimation of each frame, the frist thing to do is extracting image of each frame.
```
# run extracting script

```
Since FlowNet2 can not run detection on raw images of 2880*1440 resolution, we need to downsample the input images first.
```
# return to OFV-VR project root
cd ..
# run the downsample script
matlab -nodesktop -nosplash downSample
```
#### Inference
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
