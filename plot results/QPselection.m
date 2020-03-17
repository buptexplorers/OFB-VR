function [QP] = QPselection(allMSE, allTileSize, sizeLmt)
% max PSPNR => min sum(PMSE)
% s.t. sum(bitrate) < S
% solve this problem by DP algorithm, find out QP level

% allMSE   nViewedTiles * (42-22+1)
% allTileSize   nViewedTiles * (42-22+1)
nTile = size(allTileSize, 1);
for t=1:nTile
    sizeLmt = sizeLmt - min(allTileSize(t,:));
    allTileSize(t,:) = allTileSize(t,:) - min(allTileSize(t,:));
end

% set a minimal interval of size
% DEBUG
minIntv = 1;

sizeLmtDsc = floor(sizeLmt / minIntv);
allTileSize = floor(allTileSize / minIntv);
state = zeros(sizeLmtDsc+1,nTile);
qpChoice = zeros(sizeLmtDsc+1,nTile);
% t=1 - the left bound of DP state matrix
for u=1:sizeLmtDsc+1
    minMSE = 1e12;
    minMSEQP = -1;
    for qp = 22:42
        if allTileSize(1,qp-22+1)>u-1
            continue;
        else
            if allMSE(1,qp-22+1) < minMSE
                minMSE = allMSE(1,qp-22+1);
                minMSEQP = qp;
            end
        end
    end
    state(u,1)=minMSE;
    qpChoice(u,1)=minMSEQP;
end
for t=2:nTile
    for u=1:sizeLmtDsc+1
        minSumMSE = 1e12;
        minMSEQP = -1;
        for qp=22:42
            if (u-1)-allTileSize(t,qp-22+1) >= 0 && state(u-allTileSize(t,qp-22+1),t-1)+allMSE(t,qp-22+1) < minSumMSE
                minSumMSE = state(u-allTileSize(t,qp-22+1),t-1)+allMSE(t,qp-22+1);
                minMSEQP = qp;
            end
        end
        state(u,t) = minSumMSE;
        qpChoice(u,t)=minMSEQP;
    end
end

% find best global scheme
QP = zeros(1, nTile);

temp = sizeLmtDsc+1;
for t=nTile:-1:1
    QP(t) = qpChoice(temp,t);
    temp = temp - allTileSize(t,QP(t)-22+1);
end

end