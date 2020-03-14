function [MSEr,Sizer] = PanoForRL(set,vid,sec)
% input: video information, output: MSE and size of tile in Pano scheme
nUser = 1; tileW=2880/24; tileH=1440/12; % usernum range 1-48
% get tiling infomation list
% vid-1 instead of vid
% all users read the same tiling scheme because of using SMSE
tiling = load(sprintf('tilingDP/Project1/tiling1004/%d/%d/%d/1.txt',set,vid-1,(sec-1)*30+1));
tiling = tiling(:,2:5);
nTiles = size(tiling,1);

% get MSE and tile in three frames in one chunk(second) with predicted data
[viewedTiles_1,MSE_1] = calcTileMseForRL(set,vid,sec,1,tiling,tileW,tileH,'pred','pred',0);
[viewedTiles_15,MSE_15] = calcTileMseForRL(set,vid,sec,15,tiling,tileW,tileH,'pred','pred',0);
[viewedTiles_29,MSE_29] = calcTileMseForRL(set,vid,sec,29,tiling,tileW,tileH,'pred','pred',0);

% calculate average MSE and tile to represent the whole chunk
meanMSE = (MSE_1+MSE_15+MSE_29)/3;
viewedTiles = viewedTiles_1 | viewedTiles_15 | viewedTiles_29;
mkdir(sprintf('MSE/%d/%03d',set,vid));
save(sprintf('MSE/%d/%03d/%03d_Pano_pred.mat',set,vid,sec),'meanMSE','viewedTiles');

for user=1:nUser % store data of different user in different folder
    TileMSE_Pano(:,:)=meanMSE(user,:,:);
    [MSEr,~]=size(TileMSE_Pano);
    mkdir(['ForRL/',num2str(set),'/',num2str(vid),'/',num2str(user),'/Pano_pred']);
    save(sprintf('ForRL/%d/%d/%d/Pano_pred/%d.mat',set,vid,user,sec),'TileMSE_Pano');
end

% get MSE and tile in three frames in one chunk(second) with real data
[~,MSE_1] = calcTileMseForRL(set,vid,sec,1,tiling,tileW,tileH,'pred','real',0);
[~,MSE_15] = calcTileMseForRL(set,vid,sec,15,tiling,tileW,tileH,'pred','real',0);
[~,MSE_29] = calcTileMseForRL(set,vid,sec,29,tiling,tileW,tileH,'pred','real',0);

% calculate average MSE and tile to represent the whole chunk
meanMSEreal = (MSE_1+MSE_15+MSE_29)/3;
mkdir(sprintf('MSE/%d/%03d',set,vid));
save(sprintf('MSE/%d/%03d/%03d_Pano_real.mat',set,vid,sec),'meanMSEreal');

for user=1:nUser % store data of different user in different folder
    TileMSE_Pano(:,:)=meanMSEreal(user,:,:);
    mkdir(['ForRL/',num2str(set),'/',num2str(vid),'/',num2str(user),'/Pano_real']);
    save(sprintf('ForRL/%d/%d/%d/Pano_real/%d.mat',set,vid,user,sec),'TileMSE_Pano');
end

viewportQPsizePerGrid = zeros(1,7);
nViewportGrid = 0;
% size per grid considered all users, and get total size of tiles
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

% store data of the size of tiles
[Sizer,~]=size(tileSize);
mkdir(['ForRL/',num2str(set),'/',num2str(vid),'/size/Pano_size']);
save(sprintf('ForRL/%d/%d/size/Pano_size/%d.mat',set,vid,sec),'tileSize');

end