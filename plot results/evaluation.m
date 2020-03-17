% Draw QoE-Bandwidth Consumption graph, read NotesForevaluation.txt for more help
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

usernum = 10; % usernum range 1-48

nExtra = 10; % constraint of size
AllSumSize_Pano = [];
AllPSNRF_Pano = [];
AllSumSize_OFB_VR = [];
AllPSNRF_OFB_VR = [];
AllSumSize_Plato = [];
AllPSNRF_Plato = [];

for set=Set
    for vid=Vid
        mkdir(['randSecs/',num2str(set)]);
        if ~exist(['randSecs/',num2str(set),'/',num2str(vid),'.mat'],'file')
            Sec = 20+randperm(40);
            Sec = sort(Sec(1:10));
            save(['randSecs/',num2str(set),'/',num2str(vid),'.mat'],'Sec');
        else
            Sec = cell2mat(struct2cell(load(['randSecs/',num2str(set),'/',num2str(vid),'.mat'])));
        end
        
        mkdir(['PlatoResult/',num2str(nGridR),'_',num2str(nGridC),'/',num2str(set),'/',num2str(vid)]);
        mkdir(['PanoResult/',num2str(set),'/',num2str(vid)]);
        mkdir(['OFB_VRResult/',num2str(set),'/',num2str(vid)]);
        for sec=Sec % sec=Sec,randomly processes 10 chunks
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
           %% get data of PSNR-OF and tile size for the graph
            if ~exist(['PlatoResult/',num2str(nGridR),'_',num2str(nGridC),'/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'])
                [PSNRF_Plato,sumSize_Plato,sumViewedTilesArea_Plato,viewportQPsizePerGrid_Plato] = Plato(set, vid, sec, nGridR, nGridC);
                save(['PlatoResult/',num2str(nGridR),'_',num2str(nGridC),'/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'],'PSNRF_Plato','sumSize_Plato','sumViewedTilesArea_Plato','viewportQPsizePerGrid_Plato');
            else
                load(['PlatoResult/',num2str(nGridR),'_',num2str(nGridC),'/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat']);
            end
            
            if ~exist(['PanoResult/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'])
                [PSNRF_Pano, sumSize_Pano,sumViewedTilesArea_Pano,viewportQPsizePerGrid_Pano] = Pano(set,vid,sec,2880/24,1440/12,sumSize_Plato,nExtra);                
                save(['PanoResult/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'],'PSNRF_Pano','sumSize_Pano','sumViewedTilesArea_Pano','viewportQPsizePerGrid_Pano');
            else
                load(['PanoResult/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat']);
            end
            
            if flow
            if ~exist(['OFB_VRResult/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'])
                [PSNRF_OFB_VR, sumSize_OFB_VR,sumViewedTilesArea_OFB_VR,viewportQPsizePerGrid_OFB_VR] = OFB_VR(set,vid,sec,2880/24,1440/12,sumSize_Plato,nExtra);
                save(['OFB_VRResult/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'],'PSNRF_OFB_VR','sumSize_OFB_VR','sumViewedTilesArea_OFB_VR','viewportQPsizePerGrid_OFB_VR');
            else
                load(['OFB_VRResult/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat']);
            end
            end
            
            % merge data from different users
            if flow
            for user=1:usernum
                [sumSize_Plato_user,index] = sort(sumSize_Plato(user,:),'ascend');
                AllSumSize_Plato=[AllSumSize_Plato;sumSize_Plato_user];
                AllPSNRF_Plato=[AllPSNRF_Plato;PSNRF_Plato(user,index)];
                
                [sumSize_Pano_user,index] = sort(sumSize_Pano(user,:),'ascend');
                AllSumSize_Pano=[AllSumSize_Pano;sumSize_Pano_user];
                AllPSNRF_Pano=[AllPSNRF_Pano;PSNRF_Pano(user,index)];
                
                [sumSize_OFB_VR_user,index] = sort(sumSize_OFB_VR(user,:),'ascend');
                AllSumSize_OFB_VR=[AllSumSize_OFB_VR;sumSize_OFB_VR_user];
                AllPSNRF_OFB_VR=[AllPSNRF_OFB_VR;PSNRF_OFB_VR(user,index)];
            end
            end
        end
    end
end
%% draw the graph for comparison
if 0
    ssBS = mean(AllSumSize_Plato(:,1));
    ssBE = mean(AllSumSize_Plato(:,42-22+1));
    ssPS = mean(AllSumSize_Pano(:,1));
    ssPE = mean(AllSumSize_Pano(:,42-22+1+nExtra));
    ssPFS = mean(AllSumSize_OFB_VR(:,1));
    ssPFE = mean(AllSumSize_OFB_VR(:,42-22+1+nExtra));
    pB=zeros(1,20);
    pBn=zeros(1,20);
    pP=zeros(1,20);
    pPn=zeros(1,20);
    pPF=zeros(1,20);
    pPFn=zeros(1,20);
    for i=1:size(AllSumSize_Plato,1)
        for j=1:42-22+1
            range=max(1,ceil((AllSumSize_Plato(i,j)-AllSumSize_Plato(i,1))/(AllSumSize_Plato(i,42-22+1)-AllSumSize_Plato(i,1))*20));
            pB(range) = pB(range)+AllPSPNR_Plato(i,j);
            pBn(range) = pBn(range)+1;
        end
    end
    for i=1:size(AllSumSize_Pano,1)
        for j=1:42-22+1+nExtra
            range=max(1,ceil((AllSumSize_Pano(i,j)-AllSumSize_Pano(i,1))/(AllSumSize_Pano(i,42-22+1+nExtra)-AllSumSize_Pano(i,1))*20));
            pP(range) = pP(range)+AllPSPNR_Pano(i,j);
            pPn(range) = pPn(range)+1;
        end
    end
    for i=1:size(AllSumSize_OFB_VR,1)
        for j=1:42-22+1+nExtra
            range=max(1,ceil((AllSumSize_OFB_VR(i,j)-AllSumSize_OFB_VR(i,1))/(AllSumSize_OFB_VR(i,42-22+1+nExtra)-AllSumSize_OFB_VR(i,1))*20));
            pPF(range) = pPF(range)+AllPSPNR_OFB_VR(i,j);
            pPFn(range) = pPFn(range)+1;
        end
    end
    pB = pB./pBn;
    pP = pP./pPn;
    pPF = pPF./pPFn;
    
    plot(ssBS+(0.5:1:19.5)*(ssBE-ssBS)/20,pB,'r');
    hold on;
    plot(ssPS+(0.5:1:19.5)*(ssPE-ssPS)/20,pP,'g');
    hold on;
    plot(ssPFS+(0.5:1:19.5)*(ssPFE-ssPFS)/20,pPF,'b');
else
    plot(mean(AllSumSize_Plato),mean(AllPSNRF_Plato),'r');
    hold on;
    plot(mean(AllSumSize_Pano),mean(AllPSNRF_Pano),'g');
    if flow
    hold on;
    plot(mean(AllSumSize_OFB_VR),mean(AllPSNRF_OFB_VR),'b');
    end
    xlabel('Bandwidth Consumption / bps'); % label of X axis
	ylabel('PSNR-OF / dB'); % label of Y axis
    legend('fixed tiling with traditional JND(Plato)',...
        'variable tiling with traditional JND(Pano)',...
        'variable tiling with flow JND(OFB-VR)');
end
