function [MSEr,Sizer] = BSLForPlato(set,vid, sec, nGridR, nGridC)
nUser = 1;
tileW = floor(2880/nGridC);
tileH = floor(1440/nGridR);

tiling = [];
for i=1:nGridR
    for j=1:nGridC
        tiling=[tiling;i,i,j,j];
    end
end
nTiles = nGridR*nGridC;

[viewedTiles_1,MSE_1] = calcTileMseForPlato(set,vid,sec,1,tiling,tileW,tileH,'pred','real',0);
for user=1:nUser
    TileMSE_BSL(:,:)=MSE_1(user,:,:);
    [MSEr,~]=size(TileMSE_BSL);
    mkdir(['ForPlato/',num2str(set),'/',num2str(vid),'/',num2str(user),'/BSL']);
    save(sprintf('ForPlato/%d/%d/%d/BSL/%d.mat',set,vid,user,(sec-1)*3+1),'TileMSE_BSL');
end
    %fid=fopen(sprintf('ForPlato/%d/%d/%d/BSL/%d.txt',set,vid,user,sec),'wt');%写入文件路径
    %fprintf(fid,'%g\n',(sec-1)*30+1);
%     [m,n]=size(TileMSE_BSL);
%     for i=1:1:m
%         for j=1:1:n
%             if j==n
%                 fprintf(fid,'%g\n',TileMSE_BSL(i,j));
%             else
%                 fprintf(fid,'%g\t',TileMSE_BSL(i,j));
%             end
%         end
%     end
%     fprintf(fid,'\n');
    %fclose(fid);
% end

[viewedTiles_15,MSE_15] = calcTileMseForPlato(set,vid,sec,15,tiling,tileW,tileH,'pred','real',0);
for user=1:nUser
    TileMSE_BSL(:,:)=MSE_15(user,:,:);
    save(sprintf('ForPlato/%d/%d/%d/BSL/%d.mat',set,vid,user,(sec-1)*3+2),'TileMSE_BSL');
end

[viewedTiles_29,MSE_29] = calcTileMseForPlato(set,vid,sec,29,tiling,tileW,tileH,'pred','real',0);
for user=1:nUser
    TileMSE_BSL(:,:)=MSE_29(user,:,:);
    save(sprintf('ForPlato/%d/%d/%d/BSL/%d.mat',set,vid,user,(sec-1)*3+3),'TileMSE_BSL');
end

meanMSE = (MSE_1+MSE_15+MSE_29)/3;
viewedTiles = viewedTiles_1 | viewedTiles_15 | viewedTiles_29;
mkdir(sprintf('MSE/%d/%03d',set,vid));
save(sprintf('MSE/%d/%03d/%03d_BSL.mat',set,vid,sec),'meanMSE','viewedTiles');

%整个chunk的所有用户的观看区域之并集的size per grid42-22+1
viewportQPsizePerGrid = zeros(1,7);
nViewportGrid = 0;
for i=1:nTiles
    if sum(viewedTiles(:,i))>=1%至少有一个用户看过
        for qp=22:4:42%累加各qp值对应的总空间大小
            viewportQPsizePerGrid((qp-22)/4+1) = viewportQPsizePerGrid((qp-22)/4+1) + calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW,qp);
        end%计算观看过tile的面积，单位长度
        nViewportGrid = nViewportGrid + ((tiling(i,2)-tiling(i,1)+1) * (tiling(i,4) - tiling(i,3)+1));
    end
end

[Sizer,~]=size(viewportQPsizePerGrid);
mkdir(['ForPlato/',num2str(set),'/',num2str(vid),'/size/BSL_size']);
save(sprintf('ForPlato/%d/%d/size/BSL_size/%d.mat',set,vid,sec),'viewportQPsizePerGrid');

% fid=fopen(sprintf('ForPlato/%d/%d/size/BSL_size/%d.txt',set,vid,sec),'wt');%写入文件路径
% fprintf(fid,'%g\n',(sec-1)*30+1);
% [m,n]=size(viewportQPsizePerGrid);
% for i=1:1:m
%     for j=1:1:n
%         if j==n
%             fprintf(fid,'%g\n',viewportQPsizePerGrid(i,j));
%         else
%             fprintf(fid,'%g\t',viewportQPsizePerGrid(i,j));
%         end
%     end
% end
% fclose(fid);
end