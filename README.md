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
```
# get flownet2-pytorch source
git clone https://github.com/NVIDIA/flownet2-pytorch.git
cd flownet2-pytorch

# install custom layers
bash install.sh

#
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
```

### PSNR-OF Calculation and Tile Grouping

### 

## Acknowledgement
Parts of codes in this project is based on the solid work of [Pano](https://github.com/louisqw/PanoProject) and [Plato](https://github.com/federerjiang/Plato). Our scheme is inspired by those two papers to apply JND and reinforcement learning in VR streaming. Besides, our optical flow estimation takes advantage of the state-of-the-art real-time optical flow detection model [FlowNet2.0](https://github.com/NVIDIA/flownet2-pytorch). 

Tanks to the selflessness and contribution of the projects mentioned above. We won't be able to achieve this project without them.
