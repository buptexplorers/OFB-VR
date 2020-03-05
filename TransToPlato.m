clear all;
close all;
clc;

%setenv('PATH', [getenv('PATH') '/usr/local/sbin:/usr/local/opt/qt/bin:/usr/local/opt/opencv@3/bin:/usr/local/bin:/opt/local/bin:/opt/local/sbin:/opt/local/sbin:/opt/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin:/Library/Apple/bin']);
warning('off','all');

Set=1;
Vid=[2]%,2,3,4,5,7,8];
%Sec=20:1:60;
calTileVal = 0;
flow = 1;

% for baseline
nGridR = 6;
nGridC = 12;

usernum = 1;

nExtra = 10; % 除了baseline的22-42 QP作为Pano的限制外，还可以增加size更大的限制
%nExtraBSL = 1;

for set=Set
    for vid=Vid
        mkdir(['randSecs/',num2str(set)]);
        if ~exist(['randSecs/',num2str(set),'/',num2str(vid),'.mat'],'file')
            Sec = (22:26);
            save(['randSecs/',num2str(set),'/',num2str(vid),'.mat'],'Sec');
        else
            Sec = cell2mat(struct2cell(load(['randSecs/',num2str(set),'/',num2str(vid),'.mat'])));
        end
        
        mkdir(['baselineResult/',num2str(nGridR),'_',num2str(nGridC),'/',num2str(set),'/',num2str(vid)]);
        mkdir(['PanoResult/',num2str(set),'/',num2str(vid)]);
        mkdir(['PanoFlowResult/',num2str(set),'/',num2str(vid)]);%
        for sec=11:1:70 %Sec[23,26,31, 36,42,50,52,54,55,60]
            %% 如果chunk存在问题，跳过
            try
                secString=sprintf('%03d',sec-1);
                vr=VideoReader(['videos/',num2str(set),'/',num2str(vid),'/',secString,'.mp4']);
                if vr.Duration~=1
                    continue;
                end
                secString=sprintf('%03d',sec-2);
                vr=VideoReader(['videos/',num2str(set),'/',num2str(vid),'/',secString,'.mp4']);
                if vr.Duration~=1
                    continue;
                end
            catch
                continue;
            end
            
            [MSEB,SizeB]=BSLForPlato(set,vid, sec, nGridR, nGridC);
            [MSEP,SizeP]=PanoForPlato(set,vid, sec);
            [MSEPF,SizePF]=PanoFlowForPlato(set,vid, sec); 
        end
        BSL=zeros(210,MSEB,7);
        Pano_pred=zeros(210,MSEP,7);
        Pano_real=zeros(210,MSEP,7);
        Pano_Flow_pred=zeros(210,MSEPF,7);
        Pano_Flow_real=zeros(210,MSEPF,7);
        
        BSL_size=zeros(70,SizeB,7);
        Pano_size=zeros(70,SizeP,7);        
        Pano_Flow_size=zeros(70,SizePF,7);

        for user=1:usernum
            for frameNo=1:210
                if exist(sprintf('ForPlato/%d/%d/%d/BSL/%d.mat',set,vid,user,frameNo))
                    load(sprintf('ForPlato/%d/%d/%d/BSL/%d.mat',set,vid,user,frameNo));
                    BSL(frameNo,:,:)=TileMSE_BSL(:,:);
                end
            end

            for frameNo=1:210
                if exist(sprintf('ForPlato/%d/%d/%d/Pano_pred/%d.mat',set,vid,user,frameNo))
                    load(sprintf('ForPlato/%d/%d/%d/Pano_pred/%d.mat',set,vid,user,frameNo));
                    Pano_pred(frameNo,:,:)=TileMSE_Pano(:,:);
                end
            end

            for frameNo=1:210
                if exist(sprintf('ForPlato/%d/%d/%d/Pano_real/%d.mat',set,vid,user,frameNo))
                    load(sprintf('ForPlato/%d/%d/%d/Pano_real/%d.mat',set,vid,user,frameNo));
                    Pano_real(frameNo,:,:)=TileMSE_Pano(:,:);
                end
            end

            for frameNo=1:210
                if exist(sprintf('ForPlato/%d/%d/%d/Pano_Flow_pred/%d.mat',set,vid,user,frameNo))
                    load(sprintf('ForPlato/%d/%d/%d/Pano_Flow_pred/%d.mat',set,vid,user,frameNo));
                    Pano_Flow_pred(frameNo,:,:)=TileMSE_PanoF(:,:);
                end
            end

            for frameNo=1:210
                if exist(sprintf('ForPlato/%d/%d/%d/Pano_Flow_real/%d.mat',set,vid,user,frameNo))
                    load(sprintf('ForPlato/%d/%d/%d/Pano_Flow_real/%d.mat',set,vid,user,frameNo));
                    Pano_Flow_real(frameNo,:,:)=TileMSE_PanoF(:,:);
                end
            end
        
            save(sprintf('ForPlato/%d/%d/%d/BSL.mat',set,vid,user),'BSL');
            save(sprintf('ForPlato/%d/%d/%d/Pano_pred.mat',set,vid,user),'Pano_pred');
            save(sprintf('ForPlato/%d/%d/%d/Pano_real.mat',set,vid,user),'Pano_real');
            save(sprintf('ForPlato/%d/%d/%d/Pano_Flow_pred.mat',set,vid,user),'Pano_Flow_pred');
            save(sprintf('ForPlato/%d/%d/%d/Pano_Flow_real.mat',set,vid,user),'Pano_Flow_real');
            
            for SecNo=1:70
                if exist(sprintf('ForPlato/%d/%d/size/BSL_size/%d.mat',set,vid,SecNo))
                    load(sprintf('ForPlato/%d/%d/size/BSL_size/%d.mat',set,vid,SecNo));
                    BSL_size(SecNo,:,:)=viewportQPsizePerGrid(:,:);
                end
            end
            for SecNo=1:70
                if exist(sprintf('ForPlato/%d/%d/size/Pano_size/%d.mat',set,vid,SecNo))
                    load(sprintf('ForPlato/%d/%d/size/Pano_size/%d.mat',set,vid,SecNo));
                    Pano_size(SecNo,:,:)=tileSize(:,:);
                end
            end
            for SecNo=1:70
                if exist(sprintf('ForPlato/%d/%d/size/Pano_Flow_size/%d.mat',set,vid,SecNo))
                    load(sprintf('ForPlato/%d/%d/size/Pano_Flow_size/%d.mat',set,vid,SecNo));
                    Pano_Flow_size(SecNo,:,:)=tileSize(:,:);
                end
            end
            save(sprintf('ForPlato/%d/%d/size/BSL_size.mat',set,vid),'BSL_size');
            save(sprintf('ForPlato/%d/%d/size/Pano_size.mat',set,vid),'Pano_size');
            save(sprintf('ForPlato/%d/%d/size/Pano_Flow_size.mat',set,vid),'Pano_Flow_size');
        end
        
        %merge('ForPlato\1\2\1');
        %merge('ForPlato\1\2\size');
    end
end