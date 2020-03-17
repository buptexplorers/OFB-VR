function [PSNRF,sumSize,sumViewedTilesArea,viewportQPsizePerGrid] = Plato(set,vid, sec, nGridR, nGridC)
% input: chunk, user trajectory, tiling parameter
% output: PMSE  nQP * 1
%         Size  nQP * 1
nUser = 10; % usernum range 1-48
tileW = floor(2880/nGridC);
tileH = floor(1440/nGridR);

% generate tiling list
tiling = [];
for i=1:nGridR
    for j=1:nGridC
        tiling=[tiling;i,i,j,j];
    end
end
nTiles = nGridR*nGridC;

%DEBUG
if ~exist(sprintf('MSE/%d/%03d/%03d_Plato.mat',set,vid,sec))
    % get MSE and tile in three frames in one chunk(second)
    [viewedTiles_1,MSE_1] = calcTileMse(set,vid,sec,1,tiling,tileW,tileH,'pred','real',0);
    [viewedTiles_15,MSE_15] = calcTileMse(set,vid,sec,15,tiling,tileW,tileH,'pred','real',0);
    [viewedTiles_29,MSE_29] = calcTileMse(set,vid,sec,29,tiling,tileW,tileH,'pred','real',0);

    % calculate average MSE and tile to represent the whole chunk
    meanMSE = (MSE_1+MSE_15+MSE_29)/3;
    viewedTiles = viewedTiles_1 | viewedTiles_15 | viewedTiles_29;
    mkdir(sprintf('MSE/%d/%03d',set,vid));
    save(sprintf('MSE/%d/%03d/%03d_Plato.mat',set,vid,sec),'meanMSE','viewedTiles');
else
    load(sprintf('MSE/%d/%03d/%03d_Plato.mat',set,vid,sec));
end

% size per grid considered all users, and get total size of tiles
viewportQPsizePerGrid = zeros(1,42-22+1);
nViewportGrid = 0;
for i=1:nTiles
    if sum(viewedTiles(:,i))>=1 % at least one user views the tile
        for qp=22:42 % get total size in different QP level
            viewportQPsizePerGrid(qp-22+1) = viewportQPsizePerGrid(qp-22+1) + calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW,qp);
        end % calculate total area of viewed size and the unit length
        nViewportGrid = nViewportGrid + ((tiling(i,2)-tiling(i,1)+1) * (tiling(i,4) - tiling(i,3)+1));
    end
end

% average value of each basic tile with different QP level
viewportQPsizePerGrid = viewportQPsizePerGrid/nViewportGrid /4;

PSNRF = zeros(nUser,42-22+1);
sumSize = zeros(nUser,42-22+1);
sumViewedTilesArea = 0; % total area of viewed tiles, considered all users
coverStat = zeros(nUser,2);
for user=1:nUser
    %% calculate coverage
    pixels = zeros(1440,2880);
    for i=1:nTiles
        if viewedTiles(user,i)==1
            pixels(tiling(i,1)*240-239:tiling(i,2)*240,tiling(i,3)*240-239:tiling(i,4)*240)=1;
        end
    end
    realViewpoint = load(['viewpoint/','real','/',num2str(set),'/',num2str(user),'_',num2str(vid-1),'.txt']);
    frameAbs = (sec-1)*30+1;
    H=1440;
    W=2880;
    Center = [floor(H * realViewpoint(frameAbs,3)), floor(W * realViewpoint(frameAbs,2))];
    coveredPixels = 0;
    uncoveredPixels = 0;
    for j=Center(1)-314:Center(1)+315
        for k=Center(2)-419:Center(2)+420
            X=j;
            Y=k;
            if j<=0
                X=H+j;
            end
            if k<=0
                Y=W+k;
            end
            if j>H
                X=(j-H);
            end
            if k>W
                Y=(k-W);
            end
            if pixels(X,Y)>=1                
                coveredPixels = coveredPixels + 1;
            else
                uncoveredPixels = uncoveredPixels + 1;
            end
        end
    end
    coverStat(user,1) = coveredPixels;
    coverStat(user,2) = uncoveredPixels;
    disp(coveredPixels/529200);
    %% calculate PSNR-OF
    viewedTilesArea = 0;
    % get bitrate of viewed tiles
    for i=1:nTiles
        if viewedTiles(user,i)==1
            viewedTilesArea = viewedTilesArea + (tiling(i,2)-tiling(i,1)+1)*(tiling(i,4)-tiling(i,3)+1);
            for qp=22:42
                temp = calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW,qp);
                sumSize(user,qp-22+1) = sumSize(user,qp-22+1) + temp;
            end
        else
            temp = calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW,42);
            sumSize(user,:) = sumSize(user,:) + temp;
        end
    end
    sumViewedTilesArea = sumViewedTilesArea +viewedTilesArea;
    % get PSNR-OF
    for qp=22:42
        sumMSE = 0;
        for i=1:nTiles
            if viewedTiles(user,i)==1
                sumMSE = sumMSE + meanMSE(user,i,qp-22+1);
            else
                sumMSE = sumMSE + meanMSE(user,i,42-22+1);
            end
        end
        % 840*630 = 529200
        temp = sumMSE / 529200;
        PSNRF(user,qp-22+1) = min(200, 20 * (log(255) - 0.5 * log(temp)) / log(10));
    end
    
end
%% display average coverage
disp(mean(coverStat(:,1))/529200);
disp(mean(mean(coverStat))*2);

end