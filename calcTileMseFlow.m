function [viewedTiles,MSE] = ...
    calcTileMseFlow(set,vid,sec,frame,tiling,tileW,tileH,transRealOrPred,calcMSERealOrPred,only42and22)
% input: original video, a sequence of frames, user's viewpoint at each frame
%        transRealOrPred indicates transmitting real viewpoint data or prediected data, which is related to certain tiles
%        calcMSERealOrPred indicates calculating MSE with real viewpoint data or prediected data
%        only42and22 indicates the QP level
% output: viewedTiles indicates which tile will be seen by users, MSE are error between tiles
if only42and22==0
    QPrange = 22:42;
else
    QPrange = [22,42];
end

usernum = 10; % important parameter, suggested range 10-48; a larger usernum leads to a more accurate calculation result
frameBase = 0; % important parameter, change it according to the optical flow files (eg.20 if OF files generate from 20th second)
frameGap = 15;

frameAbs = (sec-1)*30 + frame; % accurate frame number of a frame in a certain second

orgChunkPath = sprintf('videos/%d/%d/%03d.mp4',set,vid,sec-1);

vr = VideoReader(orgChunkPath);

% JND fitting function from user study
% lumiToJND, depthToJND, speedToJND - cfit structure
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
    W = 2880;
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
    
    %% 3 DepthJND(front/ground) by optical flow
    DepthPath = 'orgFlow/';
    floAbs = frameAbs-frameBase*30;
    DepthPath = strcat(DepthPath,int2str(set),'/',int2str(vid-1),'/','continuesFlo/');
    load([DepthPath,'../orgFlo.mat']); % get basic optical flow data
    for i = 1:6-length(int2str(floAbs))
        DepthPath = strcat(DepthPath,'0');
    end
    DepthPath = strcat(DepthPath,int2str(floAbs-1),'.flo'); % the floAbs of .flo file start from 0
    
    if ~exist([DepthPath,'.mat'],'file')
        % read original .flo files
        orgFlo = 2*readFlowFile(DepthPath);
        % set the size of optical flow files with 720*1440
        Flo = zeros(H/2,W/2,2);
        flowSize = size(orgFlo);
        margin = [(H/2-flowSize(1))/2,(W/2-flowSize(2))/2];
        Flo(margin(1)+1:H/2-margin(1),margin(2)+1:W/2-margin(2),:) = orgFlo;
        % calculate average number according to tiles, downsampling to the size of 12*24
        floU = im2col(Flo(:,:,1),[tileH/2 tileW/2],'distinct');
        floV = im2col(Flo(:,:,2),[tileH/2 tileW/2],'distinct');
        tileFlo = reshape( [mean(floU),mean(floV)],12, 24, 2);
        save([DepthPath,'.mat'],'tileFlo');
    else
        load([DepthPath,'.mat']);
    end
    DepthFlo = sum(abs(tileFlo).^2,3).^(1/2); % calculate modulo of each element in the martix
    DepthFlo = DepthFlo/max(max(DepthFlo)); % normalization
    
    centTile = [floor(transCenter(1)/tileH), floor(transCenter(2)/tileW)];
    for i = 1:H/tileH
        for j = 1:W/tileW
            if abs(centTile(1)-i)>=6 || abs(centTile(2)-j)>=8
                DepthFlo(i,j) = 1;
            end
        end
    end
    
    % upsampling
    DepthJND = zeros(H,W);
    for i = 1:120
        for j = 1:120
            DepthJND(i:120:end,j:120:end) = DepthFlo;
        end
    end
    referenceD = DepthJND(transCenter(1),transCenter(2));
    DepthJND = 1+3*abs(DepthJND - referenceD); % normalize DepthJND within 1~4 to compare with Pano scheme
    
    %% 4 SpeedJND by optical flow
    'speed'
    % calculate the optical flow information of 15 frames before the reference frame
    % consider the rotation direction and speed of a user
    RSpeedPath = sprintf('RotationVector/%s/%d/%03d/%02d.mat',calcMSERealOrPred,set,vid,user);
    if ~exist(RSpeedPath,'file')
        RotationVector=GetRotationVector(vid,user,15);
        mkdir(sprintf('RotationVector/%s/%d/%03d',calcMSERealOrPred,set,vid));
        save(RSpeedPath,'RotationVector');
    else
        RotationVector=cell2mat(struct2cell(load(RSpeedPath)));
    end
    
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
    SpeedJND = ones(H,W) * (2.074*speedLowerBound^0.6374+8)/8;
    
    speedFloBase = 'orgFlow/';
    floAbs = frameAbs-frameBase*30;
    speedFloBase = strcat(speedFloBase,int2str(set),'/',int2str(vid-1),'/','continuesFlo/');
    speedFlo = zeros(12,24,2);
    for i = 1:frameGap
        speedFloPath = speedFloBase;
        for j = 1:6-length(int2str(floAbs))
            speedFloPath = strcat(speedFloPath,'0');
        end
        speedFloPath = strcat(speedFloPath,int2str(floAbs-1),'.flo'); % the floAbs of .flo file start from 0
        load([speedFloPath,'.mat']);
        % add into the total motion vector
        speedFlo = speedFlo + tileFlo/1440*2*pi; % transform into number of degrees
    end
    
    for j=calcMSECenter(1)-314:calcMSECenter(1)+315
        for k=calcMSECenter(2)-419:calcMSECenter(2)+420
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
            tileY = 1+mod(floor(Y/tileH),12);
            tileX = 1+mod(floor(X/tileW),24);
            curFlow = squeeze(speedFlo(tileY,tileX,:))';
            xyzFlow = [cos(curFlow(1))*cos(curFlow(2)), ...
                        sin(curFlow(1))*cos(curFlow(2)), ...
                        sin(curFlow(2))];
            sumRotation = RotationVector(floor(frameAbs/15))-xyzFlow+[1 0 0];
            sumSpeed = 180*acos((2-norm(sumRotation)^2)/2)/pi;
            SpeedJND(X,Y)= (2.074*norm(sumSpeed)^0.6374+8)/8;
        end
    end
    
    %% R - JND matrix of a certain frame
    % TODO
    % SJND 3-28
    % depth 1-4
    % Fresult 1-10
    % SpeedJND 
    R=SJND.*DepthJND.*transFresult_all.*SpeedJND;
    %DEBUG
    R=R * 0.5;
    
    %% Get result of tiles
    'tiles'
    % input: video with different qp, source video, JND matrix (R)
    % output: PMSE of each tile which is viewed
    for i=1:size(tiling,1)
        sr = tiling(i,1);
        er = tiling(i,2);
        sc = tiling(i,3);
        ec = tiling(i,4);
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
    
end

disp(['MSEF set ',num2str(set), ' vid ',num2str(vid), ' sec ',num2str(sec), ' frame ',num2str(frame)]);

end
