function [MSEr,Sizer] = PlatoForRL(set,vid,sec,nGridR,nGridC)
% input: chunk, user trajectory, tiling parameter
% output: PMSE  nQP * 1
%         Size  nQP * 1
nUser = 1; % usernum range 1-48
tileW = floor(2880/nGridC);
tileH = floor(1440/nGridR);

tiling = [];
for i=1:nGridR
    for j=1:nGridC
        tiling=[tiling;i,i,j,j];
    end
end
nTiles = nGridR*nGridC;

% get MSE and tile in three frames in one chunk(second)
[viewedTiles_1,MSE_1] = calcTileMseForRL(set,vid,sec,1,tiling,tileW,tileH,'pred','real',0);
[viewedTiles_15,MSE_15] = calcTileMseForRL(set,vid,sec,15,tiling,tileW,tileH,'pred','real',0);
[viewedTiles_29,MSE_29] = calcTileMseForRL(set,vid,sec,29,tiling,tileW,tileH,'pred','real',0);

% calculate average MSE and tile to represent the whole chunk
meanMSE = (MSE_1+MSE_15+MSE_29)/3;
viewedTiles = viewedTiles_1 | viewedTiles_15 | viewedTiles_29;
mkdir(sprintf('MSE/%d/%03d',set,vid));
save(sprintf('MSE/%d/%03d/%03d_Plato.mat',set,vid,sec),'meanMSE','viewedTiles');

for user=1:nUser % store data of different user in different folder
    TileMSE_Plato(:,:)=meanMSE(user,:,:);
    [MSEr,~]=size(TileMSE_Plato);
    mkdir(['ForRL/',num2str(set),'/',num2str(vid),'/',num2str(user),'/Plato']);
    save(sprintf('ForRL/%d/%d/%d/Plato/%d.mat',set,vid,user,sec),'TileMSE_Plato');
end

% size per grid considered all users, and get total size of tiles
viewportQPsizePerGrid = zeros(1,7);
nViewportGrid = 0;
for i=1:nTiles
    if sum(viewedTiles(:,i))>=1 % at least one user views the tile
        for qp=22:4:42 % get total size in different QP level
            viewportQPsizePerGrid((qp-22)/4+1) = viewportQPsizePerGrid((qp-22)/4+1) + calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW,qp);
        end % calculate total area of viewed size and the unit length
        nViewportGrid = nViewportGrid + ((tiling(i,2)-tiling(i,1)+1) * (tiling(i,4) - tiling(i,3)+1));
    end
end

% store data of the size of tiles
[Sizer,~]=size(viewportQPsizePerGrid);
mkdir(['ForRL/',num2str(set),'/',num2str(vid),'/size/Plato_size']);
save(sprintf('ForRL/%d/%d/size/Plato_size/%d.mat',set,vid,sec),'viewportQPsizePerGrid');

end