function [MSEr,Sizer] = PanoForPlato(set,vid, sec)
% sizeLmt   nUser * nQP
nUser = 1; tileW=2880/24; tileH=1440/12;
% get tiling infomation list
% vid - 1 instead of vid
% all users read the same tiling scheme because of using SMSE
tiling = load(sprintf('tilingDP/Project1/tiling1004/%d/%d/%d/1.txt',set,vid-1,(sec-1)*30+1));
tiling = tiling(:,2:5);
nTiles = size(tiling,1);


[viewedTiles_1,MSE_1] = calcTileMseForPlato(set,vid,sec,1,tiling,tileW,tileH,'pred','pred',0);
for user=1:nUser
    TileMSE_Pano(:,:)=MSE_1(user,:,:);
    [MSEr,~]=size(TileMSE_Pano);
    mkdir(['ForPlato/',num2str(set),'/',num2str(vid),'/',num2str(user),'/Pano_pred']);
    save(sprintf('ForPlato/%d/%d/%d/Pano_pred/%d.mat',set,vid,user,(sec-1)*3+1),'TileMSE_Pano');
end
%     fid=fopen(sprintf('ForPlato/%d/%d/%d/Pano_pred/%d.txt',set,vid,user,sec),'wt');%写入文件路径
%     fprintf(fid,'%g\n',(sec-1)*30+1);
%     [m,n]=size(TileMSE_Pano);
%     for i=1:1:m
%         for j=1:1:n
%             if j==n
%                 fprintf(fid,'%g\n',TileMSE_Pano(i,j));
%             else
%                 fprintf(fid,'%g\t',TileMSE_Pano(i,j));
%             end
%         end
%     end
%     fprintf(fid,'\n');
%     %fclose(fid);
% end

[viewedTiles_15,MSE_15] = calcTileMseForPlato(set,vid,sec,15,tiling,tileW,tileH,'pred','pred',0);
for user=1:nUser
    TileMSE_Pano(:,:)=MSE_15(user,:,:);
    save(sprintf('ForPlato/%d/%d/%d/Pano_pred/%d.mat',set,vid,user,(sec-1)*3+2),'TileMSE_Pano');
end

[viewedTiles_29,MSE_29] = calcTileMseForPlato(set,vid,sec,29,tiling,tileW,tileH,'pred','pred',0);
for user=1:nUser
    TileMSE_Pano(:,:)=MSE_29(user,:,:);
    save(sprintf('ForPlato/%d/%d/%d/Pano_pred/%d.mat',set,vid,user,(sec-1)*3+3),'TileMSE_Pano');
end

meanMSE = (MSE_1+MSE_15+MSE_29)/3;
viewedTiles = viewedTiles_1 | viewedTiles_15 | viewedTiles_29;
mkdir(sprintf('MSE/%d/%03d',set,vid));
save(sprintf('MSE/%d/%03d/%03d_Pano_pred.mat',set,vid,sec),'meanMSE','viewedTiles');

[viewedTiles_1,MSE_1] = calcTileMseForPlato(set,vid,sec,1,tiling,tileW,tileH,'pred','real',0);
for user=1:nUser
    TileMSE_Pano(:,:)=MSE_1(user,:,:);
    mkdir(['ForPlato/',num2str(set),'/',num2str(vid),'/',num2str(user),'/Pano_real']);
    save(sprintf('ForPlato/%d/%d/%d/Pano_real/%d.mat',set,vid,user,(sec-1)*3+1),'TileMSE_Pano');
end
%     fid=fopen(sprintf('ForPlato/%d/%d/%d/Pano_real/%d.txt',set,vid,user,sec),'wt');%写入文件路径
%     fprintf(fid,'%g\n',(sec-1)*30+1);
%     [m,n]=size(TileMSE_Pano);
%     for i=1:1:m
%         for j=1:1:n
%             if j==n
%                 fprintf(fid,'%g\n',TileMSE_Pano(i,j));
%             else
%                 fprintf(fid,'%g\t',TileMSE_Pano(i,j));
%             end
%         end
%     end
%     fprintf(fid,'\n');
%     %fclose(fid);
% end

[viewedTiles_15,MSE_15] = calcTileMseForPlato(set,vid,sec,15,tiling,tileW,tileH,'pred','real',0);
for user=1:nUser
    TileMSE_Pano(:,:)=MSE_15(user,:,:);
    save(sprintf('ForPlato/%d/%d/%d/Pano_real/%d.mat',set,vid,user,(sec-1)*3+2),'TileMSE_Pano');
end

[viewedTiles_29,MSE_29] = calcTileMseForPlato(set,vid,sec,29,tiling,tileW,tileH,'pred','real',0);
for user=1:nUser
    TileMSE_Pano(:,:)=MSE_29(user,:,:);
    save(sprintf('ForPlato/%d/%d/%d/Pano_real/%d.mat',set,vid,user,(sec-1)*3+3),'TileMSE_Pano');
end

meanMSEreal = (MSE_1+MSE_15+MSE_29)/3;
mkdir(sprintf('MSE/%d/%03d',set,vid));
save(sprintf('MSE/%d/%03d/%03d_Pano_real.mat',set,vid,sec),'meanMSEreal');

viewportQPsizePerGrid = zeros(1,7);
nViewportGrid = 0;
% 所有用户的并集的size per grid；顺便存好后面会用到的tile size
tileSize = zeros(nTiles,7);
for i=1:nTiles
    if sum(viewedTiles(:,i))>=1
        for qp=22:4:42
            tileSize(i,(qp-22)/4+1) = calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW,qp);
            viewportQPsizePerGrid((qp-22)/4+1) = viewportQPsizePerGrid((qp-22)/4+1) + tileSize(i,(qp-22)/4+1);
        end
        nViewportGrid = nViewportGrid + ((tiling(i,2)-tiling(i,1)+1) * (tiling(i,4) - tiling(i,3)+1));
    else
        % no need to encode not-viewed tiles at QP 22-41
        tileSize(i,7) = calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW,42);
    end
end

[Sizer,~]=size(tileSize);
mkdir(['ForPlato/',num2str(set),'/',num2str(vid),'/size/Pano_size']);
save(sprintf('ForPlato/%d/%d/size/Pano_size/%d.mat',set,vid,sec),'tileSize');

% fid=fopen(sprintf('ForPlato/%d/%d/size/Pano_size/%d_%d.txt',set,vid,sec,(sec-1)*30+1),'wt');%写入文件路径
% fprintf(fid,'%g\n',(sec-1)*30+1);
% [m,n]=size(tileSize);
% for i=1:1:m
%     for j=1:1:n
%         if j==n
%             fprintf(fid,'%g\n',tileSize(i,j));
%         else
%             fprintf(fid,'%g\t',tileSize(i,j));
%         end
%     end
% end
% fclose(fid);
end