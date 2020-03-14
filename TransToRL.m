% calculate and store data for reinforcement learning evaluation
clear all;
close all;
clc;

%setenv('PATH', [getenv('PATH') '/usr/local/ffmpeg/bin']);

warning('off','all');

Set=1; % Set=1 or 2
Vid=2; % Vid=[1,2,3,4,5,7,8];
calTileVal = 0;
flow = 1;

% for baseline
nGridR = 6;
nGridC = 12;

usernum = 1; % usernum range 1-48

nExtra = 10; % constraint of size

for set=Set
    for vid=Vid
        mkdir(['randSecs/',num2str(set)]);
        if ~exist(['randSecs/',num2str(set),'/',num2str(vid),'.mat'],'file')
            Sec = (22:26);
            save(['randSecs/',num2str(set),'/',num2str(vid),'.mat'],'Sec');
        else
            Sec = cell2mat(struct2cell(load(['randSecs/',num2str(set),'/',num2str(vid),'.mat'])));
        end
        
        mkdir(['PlatoResult/',num2str(nGridR),'_',num2str(nGridC),'/',num2str(set),'/',num2str(vid)]);
        mkdir(['PanoResult/',num2str(set),'/',num2str(vid)]);
        mkdir(['OFB_VRResult/',num2str(set),'/',num2str(vid)]);%
        for sec=11:1:70 % sec=Sec,randomly processes 10 chunks, eg.Sec=[23,26,31,36,42,50,52,54,55,60]
            try % if the length of a chunk is not 1 sec, skip to avoid error
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
           %% get MSE and tile size data for each user
            [MSEB,SizeB]=PlatoForRL(set,vid, sec, nGridR, nGridC);
            [MSEP,SizeP]=PanoForRL(set,vid, sec);
            [MSEF,SizeF]=OFB_VRForRL(set,vid, sec); 
        end
        % 70 - total time in reinforcement learning
        % MSE/Size - matrix size of MSE and tile size data, related to tile mumber
        % 7 - total number of typical QP level between 22-42
        Plato=zeros(70,MSEB,7);
        Pano_pred=zeros(70,MSEP,7);
        Pano_real=zeros(70,MSEP,7);
        OFB_VR_pred=zeros(70,MSEF,7);
        OFB_VR_real=zeros(70,MSEF,7);
        
        Plato_size=zeros(70,SizeB,7);
        Pano_size=zeros(70,SizeP,7);        
        OFB_VR_size=zeros(70,SizeF,7);
       %% merge all data of each user separately into above 3-dimension matrixs
        for user=1:usernum
            for SecNo=1:70
                if exist(sprintf('ForRL/%d/%d/%d/Plato/%d.mat',set,vid,user,SecNo))
                    load(sprintf('ForRL/%d/%d/%d/Plato/%d.mat',set,vid,user,SecNo));
                    Plato(SecNo,:,:)=TileMSE_Plato(:,:);
                end
            end

            for SecNo=1:70
                if exist(sprintf('ForRL/%d/%d/%d/Pano_pred/%d.mat',set,vid,user,SecNo))
                    load(sprintf('ForRL/%d/%d/%d/Pano_pred/%d.mat',set,vid,user,SecNo));
                    Pano_pred(SecNo,:,:)=TileMSE_Pano(:,:);
                end
            end

            for SecNo=1:70
                if exist(sprintf('ForRL/%d/%d/%d/Pano_real/%d.mat',set,vid,user,SecNo))
                    load(sprintf('ForRL/%d/%d/%d/Pano_real/%d.mat',set,vid,user,SecNo));
                    Pano_real(SecNo,:,:)=TileMSE_Pano(:,:);
                end
            end

            for SecNo=1:70
                if exist(sprintf('ForRL/%d/%d/%d/OFB_VR_pred/%d.mat',set,vid,user,SecNo))
                    load(sprintf('ForRL/%d/%d/%d/OFB_VR_pred/%d.mat',set,vid,user,SecNo));
                    OFB_VR_pred(SecNo,:,:)=TileMSE_OFB_VR(:,:);
                end
            end

            for SecNo=1:70
                if exist(sprintf('ForRL/%d/%d/%d/OFB_VR_real/%d.mat',set,vid,user,SecNo))
                    load(sprintf('ForRL/%d/%d/%d/OFB_VR_real/%d.mat',set,vid,user,SecNo));
                    OFB_VR_real(SecNo,:,:)=TileMSE_OFB_VR(:,:);
                end
            end
        
            save(sprintf('ForRL/%d/%d/%d/Plato.mat',set,vid,user),'Plato');
            save(sprintf('ForRL/%d/%d/%d/Pano_pred.mat',set,vid,user),'Pano_pred');
            save(sprintf('ForRL/%d/%d/%d/Pano_real.mat',set,vid,user),'Pano_real');
            save(sprintf('ForRL/%d/%d/%d/OFB_VR_pred.mat',set,vid,user),'OFB_VR_pred');
            save(sprintf('ForRL/%d/%d/%d/OFB_VR_real.mat',set,vid,user),'OFB_VR_real');
            
            for SecNo=1:70
                if exist(sprintf('ForRL/%d/%d/size/Plato_size/%d.mat',set,vid,SecNo))
                    load(sprintf('ForRL/%d/%d/size/Plato_size/%d.mat',set,vid,SecNo));
                    Plato_size(SecNo,:,:)=viewportQPsizePerGrid(:,:);
                end
            end
            for SecNo=1:70
                if exist(sprintf('ForRL/%d/%d/size/Pano_size/%d.mat',set,vid,SecNo))
                    load(sprintf('ForRL/%d/%d/size/Pano_size/%d.mat',set,vid,SecNo));
                    Pano_size(SecNo,:,:)=tileSize(:,:);
                end
            end
            for SecNo=1:70
                if exist(sprintf('ForRL/%d/%d/size/OFB_VR_size/%d.mat',set,vid,SecNo))
                    load(sprintf('ForRL/%d/%d/size/OFB_VR_size/%d.mat',set,vid,SecNo));
                    OFB_VR_size(SecNo,:,:)=tileSize(:,:);
                end
            end
            save(sprintf('ForRL/%d/%d/size/Plato_size.mat',set,vid),'Plato_size');
            save(sprintf('ForRL/%d/%d/size/Pano_size.mat',set,vid),'Pano_size');
            save(sprintf('ForRL/%d/%d/size/OFB_VR_size.mat',set,vid),'OFB_VR_size');
        end
    end
end