rm -rf result/

python3 main.py --inference --model FlowNet2 --save_flow \
--inference_dataset ImagesFromFolder \
--inference_dataset_root video2_re/ \
--resume FlowNet2_checkpoint.pth.tar \
--save result/ 
