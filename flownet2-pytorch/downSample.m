clear
file_path =  'video2/';% 图像文件夹路径  
img_path_list = dir(strcat(file_path,'*.png'));%获取该文件夹中所有png格式的图像  
img_num = length(img_path_list);%获取图像总数量 
if img_num > 0 %有满足条件的图像  
        for j = 1:img_num %逐一读取图像  
            image_name = img_path_list(j).name;% 图像名  
            image =  imread(strcat(file_path,image_name));  
            fprintf('%d %d %s\n',i,j,strcat(file_path,image_name));% 显示正在处理的图像名  
            %图像处理过程 省略  
            [rows,cols] = size(image);
            data_sum = image(1:2:rows,1:2:cols);%每隔一行一列抽样
            r = data_sum(:,1:cols/6);
            g = data_sum(:,1+cols/6:cols/3);
            b = data_sum(:,1+cols/3:cols/2);
            data_sum = cat(3,r,g,b);
            imwrite(data_sum,strcat('video2_re/re',image_name));
            %这里直接可以访问细胞元数据的方式访问数据
        end  
end  
