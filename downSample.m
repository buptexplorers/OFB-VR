% since FlowNet can not run detection on raw image of 2880*1440 resulution
% we downsample the input images first

clear
file_path =  'flownet2-pytorch/video2/';% Path to original images 
img_path_list = dir(strcat(file_path,'*.png'));
img_num = length(img_path_list);%the total number of images
if img_num > 0  
        for j = 1:img_num   
            image_name = img_path_list(j).name;  
            image =  imread(strcat(file_path,image_name));  
            fprintf('%d %d %s\n',i,j,strcat(file_path,image_name));  
             
            [rows,cols] = size(image);
            data_sum = image(1:2:rows,1:2:cols);
            r = data_sum(:,1:cols/6);
            g = data_sum(:,1+cols/6:cols/3);
            b = data_sum(:,1+cols/3:cols/2);
            data_sum = cat(3,r,g,b);
            imwrite(data_sum,strcat('flownet2-pytorch/video2_re/re',image_name));
        end  
end  
