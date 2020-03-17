function [PSPNR, sumSize, sumViewedTilesArea, viewportQPsizePerGrid] = OFB_VR(set,vid,sec,tileW,tileH,sizeLmt,nExtra)
% input: data of tiling and video information, output: PSPNR and total size of tile in OFB-VR scheme
nUser = 10; % usernum range 1-48
% get tiling infomation list
% vid-1 instead of vid
% all users read the same tiling scheme because of using SMSE
tiling = load(sprintf('tilingDP/Project1/tiling1003/%d/%d/%d/1.txt',set,vid-1,(sec-1)*30+1));
tiling = tiling(:,2:5);
nTiles = size(tiling,1);

if ~exist(sprintf('MSE/%d/%03d/%03d_OFB_VR_pred.mat',set,vid,sec))    
    % get MSE and tile in three frames in one chunk(second) with predicted data
    [viewedTiles_1,MSE_1] = calcTileMseFlow(set,vid,sec,1,tiling,tileW,tileH,'pred','pred',0);
    [viewedTiles_15,MSE_15] = calcTileMseFlow(set,vid,sec,15,tiling,tileW,tileH,'pred','pred',0);
    [viewedTiles_29,MSE_29] = calcTileMseFlow(set,vid,sec,29,tiling,tileW,tileH,'pred','pred',0);

    % calculate average MSE and tile to represent the whole chunk
    meanMSE = (MSE_1+MSE_15+MSE_29)/3;
    viewedTiles = viewedTiles_1 | viewedTiles_15 | viewedTiles_29;
    mkdir(sprintf('MSE/%d/%03d',set,vid));
    save(sprintf('MSE/%d/%03d/%03d_OFB_VR_pred.mat',set,vid,sec),'meanMSE','viewedTiles');
else
    load(sprintf('MSE/%d/%03d/%03d_OFB_VR_pred.mat',set,vid,sec));
end

if ~exist(sprintf('MSE/%d/%03d/%03d_OFB_VR_real.mat',set,vid,sec))
    % get MSE and tile in three frames in one chunk(second) with real data
    [viewedTiles_1,MSE_1] = calcTileMseFlow(set,vid,sec,1,tiling,tileW,tileH,'pred','real',0);
    [viewedTiles_15,MSE_15] = calcTileMseFlow(set,vid,sec,15,tiling,tileW,tileH,'pred','real',0);
    [viewedTiles_29,MSE_29] = calcTileMseFlow(set,vid,sec,29,tiling,tileW,tileH,'pred','real',0);
    
    % calculate average MSE and tile to represent the whole chunk
    meanMSEreal = (MSE_1+MSE_15+MSE_29)/3;
    mkdir(sprintf('MSE/%d/%03d',set,vid));
    save(sprintf('MSE/%d/%03d/%03d_OFB_VR_real.mat',set,vid,sec),'meanMSEreal');
else
    load(sprintf('MSE/%d/%03d/%03d_OFB_VR_real.mat',set,vid,sec));
end

viewportQPsizePerGrid = zeros(1,42-22+1);
nViewportGrid = 0;
% size per grid considered all users, and get total size of tiles
tileSize = zeros(nTiles,42-22+1);
for i=1:nTiles
    if sum(viewedTiles(:,i))>=1
        for qp=22:42
            tileSize(i,qp-22+1) = calcTileSizeFlow(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW,qp);
            viewportQPsizePerGrid(qp-22+1) = viewportQPsizePerGrid(qp-22+1) + tileSize(i,qp-22+1);
        end
        nViewportGrid = nViewportGrid + ((tiling(i,2)-tiling(i,1)+1) * (tiling(i,4) - tiling(i,3)+1));
    else
        % no need to encode not-viewed tiles at QP 22-41
        tileSize(i,42-22+1) = calcTileSizeFlow(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW,42);
    end
end

viewportQPsizePerGrid = viewportQPsizePerGrid/nViewportGrid;

PSPNR = zeros(nUser,42-22+1+nExtra);
sumSize = zeros(nUser,42-22+1+nExtra);
sumViewedTilesArea = 0;
coverStat = zeros(nUser,2);
for user=1:nUser
    %% calculate coverage
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
    %% calculate PSNR-OF    
    viewed = viewedTiles(user,:)==1;
    
    % transmitting area\size
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
        
        try
            msepred = squeeze(meanMSE(user,:,:));
            msereal = squeeze(meanMSEreal(user,:,:));
            %%%% DEBUG meanMSE meanMSEreal
            QP = QPselection(squeeze(meanMSE(user,viewed,:)), tileSize(viewed',:), newSizeLmt);
            Size = 0;
            sumMSEreal = 0;
            for i=1:nTiles
                if viewed(i)
                    iViewed = sum(viewed(1,1:i));
                    sumMSEreal = sumMSEreal + meanMSEreal(user,i,QP(iViewed)-22+1);
                    Size = Size + tileSize(i,QP(iViewed)-22+1);
                else
                    sumMSEreal = sumMSEreal + meanMSEreal(user,i,42-22+1);
                    Size = Size + tileSize(i,42-22+1);
                end
            end
            sumSize(user,qp-22+1) = Size;
            
            % 840*630 = 529200
            temp = sumMSEreal / 529200;
            PSPNR(user,qp-22+1) = min(200, 20 * (log(255) - 0.5 * log(temp)) / log(10));
        catch
            disp(['DP ERROR set ',num2str(set), ' ',num2str(vid), ' sec ',num2str(sec), ' user ',num2str(user), ' QP ',num2str(qp)]);
            temp=tileSize(viewed',:)';
            disp(['OFB_VR ',num2str(sum(min(temp))),' Limit ',num2str(newSizeLmt)]);
        end
    end
end
end