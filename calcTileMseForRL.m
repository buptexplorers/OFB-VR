function [viewedTiles,PMSE] = ...
    calcTileMseForRL(set,vid,sec,frame,tiling,tileW,tileH,transRealOrPred,calcMSERealOrPred,only42and22)
% input: original video, a sequence of frames, user's viewpoint at each frame
%        transRealOrPred indicates transmitting real viewpoint data or prediected data, which is related to certain tiles
%        calcMSERealOrPred indicates calculating MSE with real viewpoint data or prediected data
%        only42and22 indicates the QP level
% output: viewedTiles indicates which tile will be seen by users, MSE are error between tiles
if only42and22==0
    QPrange = [22,26,30,34,38,42];
else
    QPrange = [22,42];
end

usernum = 10; % important parameter, suggested range 10-48; a larger usernum leads to a more accurate calculation result

frameAbs = (sec-1)*30 + frame; % accurate frame number of a frame in a certain second

orgChunkPath = sprintf('videos/%d/%d/%03d.mp4',set,vid,sec-1);

vr = VideoReader(orgChunkPath);

% JND fitting function from user study
% lumiToJND, depthToJND, speedToJND
load('fitted.mat');

% get original video frame image
% nine frame before this frame are also needed for the luminance calculation.
orgFrameImgFolderPath = sprintf('image/%d/%03d',set,vid);
mkdir(orgFrameImgFolderPath);

for f=frameAbs-29:frameAbs
    if ~exist(sprintf('%s/%04d_org.png', orgFrameImgFolderPath, f),'file')
        % the frame may be at the last second.
        if f <= (sec-1)*30
            command = ['ffmpeg -i ',sprintf('videos/%d/%d/%03d.mp4',set,vid,sec-2),' -vf "select=eq(n\,',num2str(f - (sec-2)*30-1),')" -vframes 1 ',sprintf('%s/%04d_org.png', orgFrameImgFolderPath, f)];
            system(command);
        else
            command = ['ffmpeg -i ',sprintf('videos/%d/%d/%03d.mp4',set,vid,sec-1),' -vf "select=eq(n\,',num2str(f - (sec-1)*30-1),')" -vframes 1 ',sprintf('%s/%04d_org.png', orgFrameImgFolderPath, f)];
            system(command);
        end
    end
end

orgFrameImg = imread(sprintf('%s/%04d_org.png', orgFrameImgFolderPath, frameAbs));
orgFrameImg = rgb2gray(orgFrameImg);


% make sure the qpVideo exists and get frame images with different qp
qpFrameImgs = {};
for qp=QPrange
    try
        test = qpFrameImgs{qp - 22 + 1};
    catch % when qpFrameImgs{qp - 22 + 1} do not exist, generate it with ffmpeg
        qpChunkPath = sprintf('videos/%d/%d/%03d_%02d.mp4',set,vid,sec,qp);
        qpFrameImgPath = sprintf('image/%d/%03d/%03d/%02d_%02d.png',set,vid,sec,frame,qp);
        if ~exist(qpFrameImgPath, 'file')
            mkdir(sprintf('image/%d/%03d/%03d',set,vid,sec));
            if ~exist(qpChunkPath,'file')
                command = sprintf('ffmpeg -r 30 -i %s -r 30 -c:v libx264 -qp %d %s', orgChunkPath, qp, qpChunkPath);
                system(command);
            end
            command = ['ffmpeg -i ',qpChunkPath,' -vf "select=eq(n\,',num2str(frame-1),')" -vframes 1 ',qpFrameImgPath];
            system(command);
        end
        qpFrameImg = imread(qpFrameImgPath);
        qpFrameImgs{qp - 22 + 1} = rgb2gray(qpFrameImg);
    end
end

%% 1 the JND of static image (calculate if it doesn't exist)
%TODO ~exist
if exist(sprintf('SJND/%d/%03d/%04d.mat',set,vid,frameAbs),'file')
    SJND = cell2mat(struct2cell(load(sprintf('SJND/%d/%03d/%04d.mat',set,vid,frameAbs))));
else
    SJND = GetSJND(double(orgFrameImg));
    mkdir(sprintf('SJND/%d/%03d',set,vid));
    save(sprintf('SJND/%d/%03d/%04d.mat',set,vid,frameAbs),'SJND');
end

MSE = zeros(usernum,size(tiling,1),42-22+1); % nUser * nubmer of tiles * (42 - 22 + 1)
viewedTiles = zeros(usernum,size(tiling,1)); % nUser * nubmer of tiles

for user=1:usernum
    disp(['user ', num2str(user)]);
    %% 2 Fresult_all - a factor referring to distance from viewpoint
    H = vr.Height;
    W = 2880; % vr.Width;
    transFresult_all=ones(H,W)*10;
    calcMSEFresult_all=ones(H,W)*10;
    
    realViewpoint = load(['viewpoint/','real','/',num2str(set),'/',num2str(user),'_',num2str(vid-1),'.txt']);
    if strcmp(transRealOrPred,'real')==1
        transCenter = [floor(H * realViewpoint(frameAbs,3)), floor(W * realViewpoint(frameAbs,2))];
    else
        transCenter = [floor(H * realViewpoint(frameAbs-30,3)), floor(W * realViewpoint(frameAbs-30,2))];
    end
    transCenter = max(transCenter, [1,1]);
    
    if strcmp(calcMSERealOrPred,'real')==1
        calcMSECenter = [floor(H * realViewpoint(frameAbs,3)), floor(W * realViewpoint(frameAbs,2))];
    else
        calcMSECenter = [floor(H * realViewpoint(frameAbs-30,3)), floor(W * realViewpoint(frameAbs-30,2))];
    end
    calcMSECenter = max(calcMSECenter, [1,1]);
    
    % all user's viewpoint at this frame.
    % a static viewport with the size of 840*630
    for j=transCenter(1)-314:transCenter(1)+315
        for k=transCenter(2)-419:transCenter(2)+420
            x=[j,k];
            d=sqrt((x(1)-transCenter(1))^2+(x(2)-transCenter(2))^2); % distance between a pixel and the viewpoint(center of viewport)
            N=840; % width of viewport
            v=0.43; % a circle area
            e=(atan(d/(N*v))/pi)*180; % formula of the circle area, radius=N*v/2
            transFresult_temp=0.06*max(0,(e-30))+1;
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
            transFresult_all(X,Y)= transFresult_temp;
            calcMSEFresult_all(X,Y)= transFresult_temp;
        end
    end
    
    Ttrans=zeros(H,W);
    % store data of the area that will be transmitted
    Ttrans(transFresult_all<9) = 1;
    
    TcalcMSE=zeros(H,W);
    TcalcMSE(calcMSEFresult_all<9) = 1;
    
    %% 3 LuminanceJND
    LuminanceJND = 1;
    
    %% 4 DepthJND
    DepthJND=zeros(H,W);
    
    % size of DepthMap = 12 * 24
    % depthMap video index start from 0 instead of 1
    % only one frame has depthMap per second.
    depthMap = cell2mat(struct2cell(load(['DepthMap/',num2str(set),'/',num2str(vid-1),'/',num2str(sec*30-29),'.mat'])));
    depthTileH = floor(H/12);
    depthTileW = floor(W/24);
    for i=1:12
        for j=1:24
            % calculate by location of viewpoints, which may not equal to the transmitted area
            depthDiff = 10 * abs(1/depthMap(ceil(calcMSECenter(1)/depthTileH),ceil(calcMSECenter(2)/depthTileW)) - 1/depthMap(i,j));

            DepthJND((i-1)*depthTileH+1:i*depthTileH,(j-1)*depthTileW+1:j*depthTileW)=feval(depthToJND,depthDiff)/feval(depthToJND,0);
        end
    end
    
    %% 5 SpeedJND
    'speed'
    % the calculating area JND is 1, while other area is the JND of the speed lowerbound or no speed
    % only consider the rotation speed without applying object detection
    RSpeedPath = sprintf('RotationSpeed/%s/%d/%03d/%02d.mat',calcMSERealOrPred,set,vid,user);
    if ~exist(RSpeedPath,'file')
        RotationSpeed=GetRotationSpeed(vid,user,15);
        mkdir(sprintf('RotationSpeed/%s/%d/%03d',calcMSERealOrPred,set,vid));
        save(RSpeedPath,'RotationSpeed');
    else
        RotationSpeed=cell2mat(struct2cell(load(RSpeedPath)));
    end
    
    if strcmp(calcMSERealOrPred,'real')==1 % when calculating real data
        speedLowerBound = min(RotationSpeed((sec*2+round(frame/15)-4):(sec*2+round(frame/15)-1)));
    else
        speedLowerBound = min(RotationSpeed((sec*2+round(frame/15)-4-2):(sec*2+round(frame/15)-1-2)));
    end
    SpeedJND = ones(H,W) * feval(speedToJND,speedLowerBound)/feval(speedToJND,0);
    for j=calcMSECenter(1)-80:calcMSECenter(1)+80
        for k=calcMSECenter(2)-80:calcMSECenter(2)+80
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
            SpeedJND(X,Y)= 1;
        end
    end
    
    %% R - JND matrix of a certain frame
    % TODO
    % SJND 3-28
    % depth 1-4
    % Fresult 1-10
    % SpeedJND 
    % LuminaceJND 1
    R=SJND.*DepthJND.*transFresult_all.*SpeedJND.*LuminanceJND;
    %DEBUG
    R=R * 0.5;
    
    %% Get result of tiles
    'tiles'
    % input: video with different qp, source video, JND matrix (R)
    % output: PMSE of each tile which is viewed
    for i=1:size(tiling,1)
        sr = tiling(i,1); % start_row
        er = tiling(i,2); % end_row
        sc = tiling(i,3); % start_colum
        ec = tiling(i,4); % end_colum
        srP = tileW * (sr-1) + 1; % ffmpeg position start from 1
        erP = tileW * er;
        scP = tileH * (sc-1) + 1;
        ecP = tileH * ec;
        % find out the viewed tiles
        % vertical
        vtcTile = zeros(1,H);
        vtcTile(srP:erP)=1;
        vtcIntscTrans = max(Ttrans')==1 & vtcTile==1;
        vtcIntscCalcMSE = max(TcalcMSE')==1 & vtcTile==1;
        % horizontal
        hrzTile = zeros(1,W);
        hrzTile(scP:ecP)=1;
        hrzIntscTrans = max(Ttrans)==1 & hrzTile==1;
        hrzIntscCalcMSE = max(TcalcMSE)==1 & hrzTile==1;
        if sum(vtcIntscTrans(:))*sum(hrzIntscTrans(:))>0
            viewedTiles(user,i) = 1;
        end
        if sum(vtcIntscCalcMSE(:))*sum(hrzIntscCalcMSE(:))==0 % set MSE=0 if the tiles not being viewed by users
            MSE(user,i,:) = zeros(1,42-22+1);
        else            
            oneTileMSE = zeros(1,42-22+1);            
            if sum(vtcIntscTrans(:))*sum(hrzIntscTrans(:))>0
                for qp = QPrange
                    % calculate within a specific image but not a whole one, so the data is downsampled
                    img_raw=orgFrameImg(vtcIntscCalcMSE,hrzIntscCalcMSE);
                    img_target=qpFrameImgs{qp-22+1}(vtcIntscCalcMSE,hrzIntscCalcMSE);
                    R0=R(vtcIntscCalcMSE,hrzIntscCalcMSE);
                    T=TcalcMSE(vtcIntscCalcMSE,hrzIntscCalcMSE);
                    
                    D_JND=double(abs(double(img_target)-double(img_raw)));
                    C=D_JND-R0;
                    temp=(C>0).*(T==1).*(C.^2);
                    
                    oneTileMSE(qp-22+1)=sum(temp(:));
                end
            else
                img_raw=orgFrameImg(vtcIntscCalcMSE,hrzIntscCalcMSE);
                img_target=qpFrameImgs{42-22+1}(vtcIntscCalcMSE,hrzIntscCalcMSE);
                R0=R(vtcIntscCalcMSE,hrzIntscCalcMSE);
                T=TcalcMSE(vtcIntscCalcMSE,hrzIntscCalcMSE);
                
                D_JND=double(abs(double(img_target)-double(img_raw)));
                C=D_JND-R0;
                temp=(C>0).*(T==1).*(C.^2);
                
                oneTileMSE(42-22+1)=sum(temp(:));
             end
            MSE(user,i,:) = oneTileMSE;
        end
    end
    % fetch MSE value of 7 specific QP level
    PMSE=zeros(usernum,size(tiling,1),7);
    for i=22:4:42
        level=i-22+1;
        k=(i-22)/4+1;
        PMSE(:,:,k)=MSE(:,:,level);
    end
end

disp(['MSE set ',num2str(set), ' vid ',num2str(vid), ' sec ',num2str(sec), ' frame ',num2str(frame)]);

end
