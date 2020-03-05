function calcTileValueness(set,vid,sec)
% set=1;
% vid=2;
% Sec=[10,20,30,40,50,60];
usernum = 1;

nGridR = 12;
nGridC = 24;
tileW = 2880 / nGridC;%2880
tileH = 1440 / nGridR;

% 生成12*24的PMSE
tiling = [];
for i=1:nGridR
    for j=1:nGridC
        tiling=[tiling;i,i,j,j]; % left-top to right-bottom?
    end
end

% nUser * nubmer of tiles * (42 - 22 + 1)
[~,MSE] = calcTileMse(set, vid, sec,1,tiling,tileW,tileH,'real','real',1);
for user=1:usernum
    mkdir(['ratio/',num2str(set),'/',num2str(vid-1),'/',num2str(user)]);
    userMSE = squeeze(MSE(user,:,:));%squeeze(mean(MSE(:,i,qp-22+1)));
    valueness = (userMSE(:,42-22+1)-userMSE(:,22-22+1)) ./ 1; % 48
    % MSE的差有了，还需要qp=22和42的码率
    for i=1:size(tiling,1)
        if valueness(i,1)~=0
            temp22 = calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW, 22);
            temp42 = calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW, 42);
            valueness(i,1) = valueness(i,1)/(temp22-temp42);
        end
    end
    %save(['tileVal/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'],'valueness');
    
    valueness(valueness<0)=0;
    % reshape
    new = zeros(12,24);
    for row=1:12
        new(row,:) = valueness(row*24-23:row*24);
    end
    %DEBUG
    new = new .* usernum;
    %写到user里
    dlmwrite(['ratio/',num2str(set),'/',num2str(vid-1),'/',num2str(user),'/',num2str(sec*30-29),'_Value_SMSE.txt'],new,' ');
    
end

end
