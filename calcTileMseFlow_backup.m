function [viewedTiles,MSE] = ...
    calcTileMseFlowOP(set, vid,sec,frame,tiling,tileW,tileH,transRealOrPred,calcMSERealOrPred,only42and22)
% transRealOrPred表示传输用什么视点，唯一的作用是确定传哪些块，calcMSERealOrPred表示算MSE用什么
% only42and22为0则只计算QP=22和42两档
if only42and22==0
    QPrange = 22:42;
else
    QPrange = [22,42];
end
% input: original video, a sequence of frames, user's viewpoint at each frame
usernum = 10;
frameBase = 20;
frameGap = 15;

frameAbs = (sec-1)*30 + frame;

orgChunkPath = sprintf('videos/%d/%d/%03d.mp4',set,vid,sec-1);
%orgVideoPath = sprintf('videos/%d/%03d.mp4',set,vid);
%orgChunkPath = sprintf('videos/%d/%03d/%03d.mp4',set,vid,sec);
% if ~exist(orgChunkPath,'file')
%     mkdir(sprintf('videos/%d/%03d',set,vid));
%     command=['ffmpeg -y -ss ',num2str(sec-1),' -t 1 -r 30 -i ',orgVideoPath,' -r 30 -c:v libx264 -preset medium -c:a copy ',orgChunkPath];
%     system(command);
% end
vr = VideoReader(orgChunkPath);

% JND fitting function from user study
% lumiToJND, depthToJND, speedToJND
load('fitted.mat');

% get original video frame image
% nine frame before this frame are also needed for the luminance calculation.
orgFrameImgFolderPath = sprintf('image/%d/%03d',set,vid);
mkdir(orgFrameImgFolderPath);
%lastSecVr = -1;
for f=frameAbs-29:frameAbs
    if ~exist(sprintf('%s/%04d_org.png', orgFrameImgFolderPath, f),'file')
        %the frame may be at the last second.
%          try
        if f <= (sec-1)*30
           % if lastSecVr == -1
%                 if ~exist(sprintf('videos/%d/%03d/%03d.mp4',set,vid,sec-1))
%                     command=['ffmpeg -y -ss ',num2str(sec-2),' -t 1 -r 30 -i ',orgVideoPath,' -r 30 -c:v libx264 -preset superfast -c:a copy ',sprintf('videos/%d/%03d/%03d.mp4',set,vid,sec-1)];
%                     system(command);
%                 end
%                 lastSecVr = VideoReader(sprintf('videos/%d/%03d/%03d.mp4',set,vid,sec-1));
         %       lastSecVr = VideoReader(sprintf('videos/%d/%d/%03d.mp4',set,vid,sec-2));
           % end
         %   tempImg = read(lastSecVr, f - (sec-2)*30);
            command = ['ffmpeg -i ',sprintf('videos/%d/%d/%03d.mp4',set,vid,sec-2),' -vf "select=eq(n\,',num2str(f - (sec-2)*30-1),')" -vframes 1 ',sprintf('%s/%04d_org.png', orgFrameImgFolderPath, f)];
            system(command);
            %tempImg = imread(sprintf('%s/%04d_org.png', orgFrameImgFolderPath, f));
        else
%             vr = VideoReader(orgChunkPath);
%             tempImg = read(vr, f - (sec-1)*30);
            command = ['ffmpeg -i ',sprintf('videos/%d/%d/%03d.mp4',set,vid,sec-1),' -vf "select=eq(n\,',num2str(f - (sec-1)*30-1),')" -vframes 1 ',sprintf('%s/%04d_org.png', orgFrameImgFolderPath, f)];
            system(command);
            %tempImg = imread(sprintf('%s/%04d_org.png', orgFrameImgFolderPath, f));
        end
%          catch
%              1
%          end
        % imwrite(orgFrameImg, orgFrameImgPath);
        %save(sprintf('%s/%04d_org.mat',orgFrameImgFolderPath, f),'tempImg');
    end
end

orgFrameImg = imread(sprintf('%s/%04d_org.png', orgFrameImgFolderPath, frameAbs));
orgFrameImg = rgb2gray(orgFrameImg);


% make sure the qpVideo exists and get frame images with different qp
qpFrameImgs = {};
for qp=QPrange
    try
        test = qpFrameImgs{qp - 22 + 1};
    catch % 表示qpFrameImgs{qp - 22 + 1}不存在
        qpChunkPath = sprintf('videos/%d/%d/%03d_%02d.mp4',set,vid,sec,qp);
        qpFrameImgPath = sprintf('image/%d/%03d/%03d/%02d_%02d.png',set,vid,sec,frame,qp);
        if ~exist(qpFrameImgPath, 'file')
            mkdir(sprintf('image/%d/%03d/%03d',set,vid,sec));
            if ~exist(qpChunkPath,'file')
                command = sprintf('ffmpeg -r 30 -i %s -r 30 -c:v libx264 -qp %d %s', orgChunkPath, qp, qpChunkPath);
                system(command);
            end
%             qpFrameImg = read(VideoReader(qpChunkPath), frame);
%             save(qpFrameImgPath,'qpFrameImg');
            command = ['ffmpeg -i ',qpChunkPath,' -vf "select=eq(n\,',num2str(frame-1),')" -vframes 1 ',qpFrameImgPath];
            system(command);
        end
        qpFrameImg = imread(qpFrameImgPath);
        qpFrameImgs{qp - 22 + 1} = rgb2gray(qpFrameImg);
    end
end

%disp('chunks & images prepared.');

%% 0 R - the JND of static image (calculate if it doesn't exist)
%TODO ~exist
if exist(sprintf('SJND/%d/%03d/%04d.mat',set,vid,frameAbs),'file')
    SJND = cell2mat(struct2cell(load(sprintf('SJND/%d/%03d/%04d.mat',set,vid,frameAbs))));
else
    SJND = CalSJND_FAST_GPU2(double(orgFrameImg));
    mkdir(sprintf('SJND/%d/%03d',set,vid));
    save(sprintf('SJND/%d/%03d/%04d.mat',set,vid,frameAbs),'SJND');
end

MSE = zeros(usernum,size(tiling,1),42-22+1); % nUser * nubmer of tiles * (42 - 22 + 1)
viewedTiles = zeros(usernum,size(tiling,1)); % nUser * nubmer of tiles

for user=1:usernum%%%DEBUG
    disp(['user ', num2str(user)]);
    %% 2 Fresult_all - a factor referring to distance from viewpoint
    H = vr.Height;
    W = 2880;
    transFresult_all=ones(H,W)*10;
    calcMSEFresult_all=ones(H,W)*10;
    
    %viewpoint = cell2mat(struct2cell(load(sprintf('viewpoint/%03d/%04d.mat',vid,frameAbs))));
    realViewpoint = load(['viewpoint/','real','/',num2str(set),'/',num2str(user),'_',num2str(vid-1),'.txt']);
    % Center=[vertical index, horizontal index]
    if strcmp(transRealOrPred,'real')==1
        transCenter = [floor(H * realViewpoint(frameAbs,3)), floor(W * realViewpoint(frameAbs,2))];
    else
        transCenter = [floor(H * realViewpoint(frameAbs-30,3)), floor(W * realViewpoint(frameAbs-30,2))];
    end
    transCenter = max(transCenter, [1,1]);
    
    % Center=[vertical index, horizontal index]
    if strcmp(calcMSERealOrPred,'real')==1
        calcMSECenter = [floor(H * realViewpoint(frameAbs,3)), floor(W * realViewpoint(frameAbs,2))];
    else
        calcMSECenter = [floor(H * realViewpoint(frameAbs-30,3)), floor(W * realViewpoint(frameAbs-30,2))];
    end
    calcMSECenter = max(calcMSECenter, [1,1]);
    
    % all user's viewpoint at this frame. ? * 2
    
    % 固定视口范围为840*630
    for j=transCenter(1)-314:transCenter(1)+315
        for k=transCenter(2)-419:transCenter(2)+420
            x=[j,k];
            d=sqrt((x(1)-transCenter(1))^2+(x(2)-transCenter(2))^2);%到参照中心的距离
            N=840;% 视口宽度
            v=0.43; %圆区域
            e=(atan(d/(N*v))/pi)*180;%圆形方程 半径N*v/2
            transFresult_temp=0.06*max(0,(e-30))+1;%0.06*max(0,(e-30))+1;
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
            calcMSEFresult_all(X,Y)= transFresult_temp;%louis
        end
    end
    
    Ttrans=zeros(H,W);
    % 表示传的区域
    Ttrans(transFresult_all<9) = 1;
    
    TcalcMSE=zeros(H,W);
    TcalcMSE(calcMSEFresult_all<9) = 1;
    %% 4 DepthJND(front/ground):1~4
    DepthPath = 'orgFlow/';
    floAbs = frameAbs-frameBase*30;
    DepthPath = strcat(DepthPath,int2str(set),'/',int2str(vid-1),'/','continuesFlo/');
    load([DepthPath,'../orgFlo.mat']);
    for i = 1:6-length(int2str(floAbs))
        DepthPath = strcat(DepthPath,'0');
    end
    DepthPath = strcat(DepthPath,int2str(floAbs),'.flo');
    
    orgDepthFlo = 2*readFlowFile(DepthPath);
    DepthFlo = zeros(H/2,W/2,2);
    flowSize = size(orgDepthFlo);
    margin = [(H/2-flowSize(1))/2,(W/2-flowSize(2))/2];
    DepthFlo(margin(1)+1:H/2-margin(1),margin(2)+1:W/2-margin(2),:) = orgDepthFlo;
    DepthFlo = sum(abs(DepthFlo).^2,3).^(1/2);%逐位求模
    DepthFlo = DepthFlo/max(max(DepthFlo));%归一化
    %上采样
    DepthJND = zeros(H,W);
    for i = 1:2
        for j = 1:2
            DepthJND(i:2:end,j:2:end) = DepthFlo;
        end
    end
    %
    referenceD = DepthJND(transCenter(1),transCenter(2));
    DepthJND = 1+3*abs(DepthJND - referenceD); %将DepthJND限制在1~4范围内，与Pano对标
    
    
    'speed'
    %% 5 SpeedJND
    % 计算参考帧前15帧的光流信息
    %
    %
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
    if strcmp(calcMSERealOrPred,'real')==1 % 等于real
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
        speedFloPath = strcat(speedFloPath,int2str(floAbs),'.flo');
        if ~exist([speedFloPath,'.mat'],'file')
            %读取原始flo
            orgSpeedFlo = 2*readFlowFile(speedFloPath);
            %填充至720*1440
            SpeedFlo = zeros(H/2,W/2,2);
            flowSize = size(orgDepthFlo);
            margin = [(H/2-flowSize(1))/2,(W/2-flowSize(2))/2];
            SpeedFlo(margin(1)+1:H/2-margin(1),margin(2)+1:W/2-margin(2),:) = orgSpeedFlo;
            %分块求均值，下采样至12*24
            floU = im2col(SpeedFlo(:,:,1),[tileH/2 tileW/2],'distinct');
            floV = im2col(SpeedFlo(:,:,2),[tileH/2 tileW/2],'distinct');
            floMean = [mean(floU),mean(floV)];
            %计入总运动向量中
            speedFlo = speedFlo + reshape(floMean, 12, 24, 2);   
            speedFlo = speedFlo/1440*2*pi;%换为度数角速度
            save([speedFloPath,'.mat'],'speedFlo');
        else
            load([speedFloPath,'.mat']);
        end
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
    
    %%
    % TODO
    % SJND 3-28
    % depth 1-4
    % Fresult 1-10
    % SpeedJND 
    R=SJND.*DepthJND.*transFresult_all.*SpeedJND;
    %DEBUG
    R=R * 0.5;
    
    %%
    % input: video with different qp, source video, JND matrix (R)
    % output: PMSE of each tile which is viewed
    'tiles'
    for i=1:size(tiling,1)
        sr = tiling(i,1);
        er = tiling(i,2);
        sc = tiling(i,3);
        ec = tiling(i,4);
        srP = tileW * (sr-1) + 1; % ffmpeg position start from 1
        erP = tileW * er;
        scP = tileH * (sc-1) + 1;
        ecP = tileH * ec;
        % 不能直接用tile位置，需计算tile与T的交集
        % 纵向
        vtcTile = zeros(1,H);
        vtcTile(srP:erP)=1;
        vtcIntscTrans = max(Ttrans')==1 & vtcTile==1;
        vtcIntscCalcMSE = max(TcalcMSE')==1 & vtcTile==1;
        % 横向
        hrzTile = zeros(1,W);
        hrzTile(scP:ecP)=1;
        hrzIntscTrans = max(Ttrans)==1 & hrzTile==1;
        hrzIntscCalcMSE = max(TcalcMSE)==1 & hrzTile==1;
        if sum(vtcIntscTrans(:))*sum(hrzIntscTrans(:))>0
            %会传
            %viewedTilesIndex = viewedTilesIndex + 1;
            viewedTiles(user,i) = 1;
        end
        if sum(vtcIntscCalcMSE(:))*sum(hrzIntscCalcMSE(:))==0 % 如果和calcMSEviewport没有交集，不管传不传都是零
            MSE(user,i,:) = zeros(1,42-22+1);
        else
            
            oneTileMSE = zeros(1,42-22+1);
            
            if sum(vtcIntscTrans(:))*sum(hrzIntscTrans(:))>0
                for qp = QPrange
                    % calc PMSE
                    %oneTileMSE(qp-22+1)=CalPMSEPerTileGra(Center,orgFrameImg(scP:ecP,srP:erP),qpFrameImgs{qp-22+1}(scP:ecP,srP:erP),R(scP:ecP,srP:erP),T(scP:ecP,srP:erP));
                    
                    oneTileMSE(qp-22+1)=CalPMSEPerTileGra(orgFrameImg(vtcIntscCalcMSE,hrzIntscCalcMSE),qpFrameImgs{qp-22+1}(vtcIntscCalcMSE,hrzIntscCalcMSE),R(vtcIntscCalcMSE,hrzIntscCalcMSE),TcalcMSE(vtcIntscCalcMSE,hrzIntscCalcMSE));
                end
            else
                oneTileMSE(42-22+1)=CalPMSEPerTileGra(orgFrameImg(vtcIntscCalcMSE,hrzIntscCalcMSE),qpFrameImgs{42-22+1}(vtcIntscCalcMSE,hrzIntscCalcMSE),R(vtcIntscCalcMSE,hrzIntscCalcMSE),TcalcMSE(vtcIntscCalcMSE,hrzIntscCalcMSE));
                
                %BandWidth_static(k,qp)=Function2{i,j}(qp);
            end
            MSE(user,i,:) = oneTileMSE;
        end
    end
    
end


disp(['MSE set ',num2str(set), ' vid ',num2str(vid), ' sec ',num2str(sec), ' frame ',num2str(frame)]);

end
