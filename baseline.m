% input: chunk, user trajectory, tiling parameter
% output: PMSE  nQP * 1
%         Size  nQP * 1
function [PSPNR,sumSize,sumViewedTilesArea,viewportQPsizePerGrid] = baseline(set,vid, sec, nGridR, nGridC)
nUser = 10;
% chunkPath = sprintf('videos/%d/%03d/%03d.mp4',set,vid,sec);
% vr = VideoReader(chunkPath);
% tileW = floor(vr.Width / nGridC);
% tileH = floor(vr.Height / nGridR);
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
if ~exist(sprintf('MSE/%d/%03d/%03d_BSL.mat',set,vid,sec))
    [viewedTiles_1,MSE_1] = calcTileMse(set,vid,sec,1,tiling,tileW,tileH,'pred','real',0);
    [viewedTiles_15,MSE_15] = calcTileMse(set,vid,sec,15,tiling,tileW,tileH,'pred','real',0);
    [viewedTiles_29,MSE_29] = calcTileMse(set,vid,sec,29,tiling,tileW,tileH,'pred','real',0);
    % nUser * nTile * nQP
    meanMSE = (MSE_1+MSE_15+MSE_29)/3;
    % nUser * nTile
    viewedTiles = viewedTiles_1 | viewedTiles_15 | viewedTiles_29;
    mkdir(sprintf('MSE/%d/%03d',set,vid));
    save(sprintf('MSE/%d/%03d/%03d_BSL.mat',set,vid,sec),'meanMSE','viewedTiles');
else
    load(sprintf('MSE/%d/%03d/%03d_BSL.mat',set,vid,sec));
end

%整个chunk的所有用户的观看区域之并集的size per grid
viewportQPsizePerGrid = zeros(1,42-22+1);
nViewportGrid = 0;
for i=1:nTiles
    if sum(viewedTiles(:,i))>=1%至少有一个用户看过
        for qp=22:42%累加各qp值对应的总空间大小
            viewportQPsizePerGrid(qp-22+1) = viewportQPsizePerGrid(qp-22+1) + calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW,qp);
        end%计算观看过tile的面积，单位长度
        nViewportGrid = nViewportGrid + ((tiling(i,2)-tiling(i,1)+1) * (tiling(i,4) - tiling(i,3)+1));
    end
end
%平均每个格子、各qp值对应的空间占用
%？除4是为了由6*12转换到12*24？
viewportQPsizePerGrid = viewportQPsizePerGrid/nViewportGrid /4;



PSPNR = zeros(nUser,42-22+1);
sumSize = zeros(nUser,42-22+1);
%sumViewportSize = zeros(nUser,nQP);
sumViewedTilesArea = 0; % 这一秒所有用户的ViewedTiles总面积
coverStat = zeros(nUser,2);
for user=1:nUser
    %% 计算覆盖率
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
    %%
    viewedTilesArea = 0;
    % 用于Pano的viewport区域码率，和算上未观看区域的总码率
    for i=1:nTiles
        if viewedTiles(user,i)==1
            viewedTilesArea = viewedTilesArea + (tiling(i,2)-tiling(i,1)+1)*(tiling(i,4)-tiling(i,3)+1);
            for qp=22:42
                temp = calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW,qp);
                %sumViewportSize(user,qp-22+1) = sumViewportSize(user,qp-22+1) + temp;
                sumSize(user,qp-22+1) = sumSize(user,qp-22+1) + temp;
            end
        else
            temp = calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW,42);
            sumSize(user,:) = sumSize(user,:) + temp;
        end
    end
    sumViewedTilesArea = sumViewedTilesArea +viewedTilesArea;
    % 算PSPNR
    for qp=22:42
        sumMSE = 0;
        for i=1:nTiles
            if viewedTiles(user,i)==1
                sumMSE = sumMSE + meanMSE(user,i,qp-22+1);
            else
                sumMSE = sumMSE + meanMSE(user,i,42-22+1);
            end
        end
        % 注意！840*630 = 529200
        temp = sumMSE / 529200;
        PSPNR(user,qp-22+1) = min(200, 20 * (log(255) - 0.5 * log(temp)) / log(10));
    end
    
end
%% 输出平均覆盖率
disp(mean(coverStat(:,1))/529200);
disp(mean(mean(coverStat))*2);


end