function [PSPNR, sumSize, sumViewedTilesArea, viewportQPsizePerGrid] = Pano(set,vid,sec,tileW, tileH, sizeLmt,nExtra) % 与baseline.m对称
% sizeLmt   nUser * nQP
nUser = 10;
% get tiling infomation list
% vid - 1 instead of vid
% all users read the same tiling scheme because of using SMSE
tiling = load(sprintf('tilingDP/Project1/tiling1004/%d/%d/%d/1.txt',set,vid-1,(sec-1)*30+1));
tiling = tiling(:,2:5);
% result=VisualizeTiling(tiling);
% val=load(['ratio/',num2str(set),'/',num2str(vid-1),'/',num2str(1),'/',num2str(sec*30-29),'_Value_SMSE.txt']);
% val
% result
nTiles = size(tiling,1);


if ~exist(sprintf('MSE/%d/%03d/%03d_Pano_pred.mat',set,vid,sec))
    [viewedTiles_1,MSE_1] = calcTileMse(set,vid,sec,1,tiling,tileW,tileH,'pred','pred',0);
    [viewedTiles_15,MSE_15] = calcTileMse(set,vid,sec,15,tiling,tileW,tileH,'pred','pred',0);
    [viewedTiles_29,MSE_29] = calcTileMse(set,vid,sec,29,tiling,tileW,tileH,'pred','pred',0);
    % nUser * nTile * nQP
    meanMSE = (MSE_1+MSE_15+MSE_29)/3;
    % nUser * nTile
    viewedTiles = viewedTiles_1 | viewedTiles_15 | viewedTiles_29;
    mkdir(sprintf('MSE/%d/%03d',set,vid));
    save(sprintf('MSE/%d/%03d/%03d_Pano_pred.mat',set,vid,sec),'meanMSE','viewedTiles');
else
    load(sprintf('MSE/%d/%03d/%03d_Pano_pred.mat',set,vid,sec));
end

if ~exist(sprintf('MSE/%d/%03d/%03d_Pano_real.mat',set,vid,sec))
    [viewedTiles_1,MSE_1] = calcTileMse(set,vid,sec,1,tiling,tileW,tileH,'pred','real',0);
    [viewedTiles_15,MSE_15] = calcTileMse(set,vid,sec,15,tiling,tileW,tileH,'pred','real',0);
    [viewedTiles_29,MSE_29] = calcTileMse(set,vid,sec,29,tiling,tileW,tileH,'pred','real',0);
    % nUser * nTile * nQP
    meanMSEreal = (MSE_1+MSE_15+MSE_29)/3;
    % nUser * nTile
    % viewedTiles = viewedTiles_1 | viewedTiles_15 | viewedTiles_29;
    mkdir(sprintf('MSE/%d/%03d',set,vid));
    save(sprintf('MSE/%d/%03d/%03d_Pano_real.mat',set,vid,sec),'meanMSEreal');
else
    load(sprintf('MSE/%d/%03d/%03d_Pano_real.mat',set,vid,sec));
end

viewportQPsizePerGrid = zeros(1,42-22+1);
nViewportGrid = 0;
% 所有用户的并集的size per grid；顺便存好后面会用到的tile size
tileSize = zeros(nTiles,42-22+1);
for i=1:nTiles
    if sum(viewedTiles(:,i))>=1
        for qp=22:42
            tileSize(i,qp-22+1) = calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW,qp);
            viewportQPsizePerGrid(qp-22+1) = viewportQPsizePerGrid(qp-22+1) + tileSize(i,qp-22+1);
        end
        nViewportGrid = nViewportGrid + ((tiling(i,2)-tiling(i,1)+1) * (tiling(i,4) - tiling(i,3)+1));
    else
        % no need to encode not-viewed tiles at QP 22-41
        tileSize(i,42-22+1) = calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW,42);
    end
end

viewportQPsizePerGrid = viewportQPsizePerGrid/nViewportGrid;


PSPNR = zeros(nUser,42-22+1+nExtra);
sumSize = zeros(nUser,42-22+1+nExtra);
sumViewedTilesArea = 0;
coverStat = zeros(nUser,2);
for user=1:nUser
    %% 计算覆盖率
    pixels = zeros(1440,2880);
    for i=1:nTiles
        if viewedTiles(user,i)==1
            pixels(tiling(i,1)*120-119:tiling(i,2)*120,tiling(i,3)*120-119:tiling(i,4)*120)=1;
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
    % 检查viewedTiles是否准确
%     CenterPred = [floor(H * realViewpoint(frameAbs-30,3)), floor(W * realViewpoint(frameAbs-30,2))];
%     coveredPixels = 0;
%     uncoveredPixels = 0;
%     for j=CenterPred(1)-314:CenterPred(1)+315
%         for k=CenterPred(2)-419:CenterPred(2)+420
%             X=j;
%             Y=k;
%             if j<=0
%                 X=H+j;
%             end
%             if k<=0
%                 Y=W+k;
%             end
%             if j>H
%                 X=(j-H);
%             end
%             if k>W
%                 Y=(k-W);
%             end
%             pixels(X,Y) = pixels(X,Y)+2;
%         end
%     end
%     imshow(pixels,[]);
    %% 
    
    viewed = viewedTiles(user,:)==1;
    
    % 每个用户会传的区域的面积\size
    sumSizeOutOfViewportQP42=0;
    maxSizeLmt = 0;
    minSizeLmt = 0;
    for i=1:nTiles
        if viewed(i)
            maxSizeLmt = maxSizeLmt + tileSize(i,22-22+1);
            minSizeLmt = minSizeLmt + tileSize(i,42-22+1);
            sumViewedTilesArea = sumViewedTilesArea + (tiling(i,2)-tiling(i,1)+1) * (tiling(i,4) - tiling(i,3)+1);
        else
            sumSizeOutOfViewportQP42 = sumSizeOutOfViewportQP42 + tileSize(i,42-22+1);
        end
    end
    for qp=22:42+nExtra
        if qp>42
            if qp-42 <= ceil(nExtra/2)
                newSizeLmt = minSizeLmt + (sizeLmt(user,42-22+1) - minSizeLmt)/ceil(nExtra/2)*(qp-42 - 1);
            else
                newSizeLmt = sizeLmt(user,22-22+1) + (maxSizeLmt-sizeLmt(user,1))/(nExtra - ceil(nExtra/2))*(qp-42 - ceil(nExtra/2));
            end
        else
            newSizeLmt = sizeLmt(user,qp-22+1) - sumSizeOutOfViewportQP42;
        end
        %         if user==34 && qp==27
        %             1
        %         end
        try
            msepred = squeeze(meanMSE(user,:,:));
            msereal = squeeze(meanMSEreal(user,:,:));
            %%%% DEBUG meanMSE meanMSEreal
            QP = dpForBestPSPNR(squeeze(meanMSE(user,viewed,:)), tileSize(viewed',:), newSizeLmt);
            %VisualizeTileDistribution(viewed,tiling,QP);
            Size = 0;
            %viewedTilesArea = 0;
            sumMSEreal = 0;
            for i=1:nTiles
                if viewed(i)
                    iViewed = sum(viewed(1,1:i));
                    sumMSEreal = sumMSEreal + meanMSEreal(user,i,QP(iViewed)-22+1);
                    Size = Size + tileSize(i,QP(iViewed)-22+1);
                    %viewedTilesArea = viewedTilesArea + (tiling(i,2)-tiling(i,1)+1) * (tiling(i,4) - tiling(i,3)+1);
                else
                    sumMSEreal = sumMSEreal + meanMSEreal(user,i,42-22+1);
                    Size = Size + tileSize(i,42-22+1);
                end
            end
            sumSize(user,qp-22+1) = Size;
            
            % 注意！840*630 = 529200
            temp = sumMSEreal / 529200;
            PSPNR(user,qp-22+1) = min(200, 20 * (log(255) - 0.5 * log(temp)) / log(10));
        catch
            disp(['DP ERROR set ',num2str(set), ' ',num2str(vid), ' sec ',num2str(sec), ' user ',num2str(user), ' QP ',num2str(qp)]);
            temp=tileSize(viewed',:)';
            disp(['Pano ',num2str(sum(min(temp))),' Limit ',num2str(newSizeLmt)]);
        end
    end
end
end