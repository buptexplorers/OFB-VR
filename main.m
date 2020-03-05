clear all;
close all;
clc;

setenv('PATH', [getenv('PATH') '/usr/local/sbin:/usr/local/opt/qt/bin:/usr/local/opt/opencv@3/bin:/usr/local/bin:/opt/local/bin:/opt/local/sbin:/opt/local/sbin:/opt/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin:/Library/Apple/bin']);
warning('off','all');

Set=1;
Vid=[2]%,2,3,4,5,7,8];
%Sec=20:1:60;
calTileVal = 0;
flow = 1;

% for baseline
nGridR = 6;
nGridC = 12;

usernum = 10;

nExtra = 10; % 除了baseline的22-42 QP作为Pano的限制外，还可以增加size更大的限制
%nExtraBSL = 1;
% sumSize_PanoAve = zeros(1,42-22+1+nExtraPano);
% PSPNR_PanoAve = zeros(1,42-22+1+nExtraPano);
% sumSize_BSLAve = zeros(1,42-22+1);
% PSPNR_BSLAve = zeros(1,42-22+1);
AllSumSize_Pano = [];
AllPSPNR_Pano = [];
AllSumSize_PanoFlow = [];
AllPSPNR_PanoFlow = [];
AllSumSize_BSL = [];
AllPSPNR_BSL = [];
%viewportQPsizePerGrid_PanoAve = zeros(1,42-22+1);
%viewportQPsizePerGrid_BSLAve = zeros(1,42-22+1);
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
        for sec=Sec
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
    
            if ~exist(['baselineResult/',num2str(nGridR),'_',num2str(nGridC),'/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'])
                [PSPNR_BSL,sumSize_BSL,sumViewedTilesArea_BSL,viewportQPsizePerGrid_BSL] = baseline(set,vid, sec, nGridR, nGridC);
                save(['baselineResult/',num2str(nGridR),'_',num2str(nGridC),'/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'],'PSPNR_BSL','sumSize_BSL','sumViewedTilesArea_BSL','viewportQPsizePerGrid_BSL');
            else
                load(['baselineResult/',num2str(nGridR),'_',num2str(nGridC),'/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat']);
            end
            
            %DEBUG
            %continue;
            
            if ~exist(['PanoResult/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'])
                % PSPNR_Pano = zeros(48,42-22+1);
                % sumSize_Pano = zeros(48,42-22+1);
                [PSPNR_Pano, sumSize_Pano,sumViewedTilesArea_Pano,viewportQPsizePerGrid_Pano] = Pano(set,vid,sec,2880/24,1440/12,sumSize_BSL,nExtra);
                %                 PSPNR_Pano(:,qp-22+1) = tempPSPNR';
                %                 sumSize_Pano(:,qp-22+1) = tempSumSize';
                
                save(['PanoResult/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'],'PSPNR_Pano','sumSize_Pano','sumViewedTilesArea_Pano','viewportQPsizePerGrid_Pano');
            else
                load(['PanoResult/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat']);
            end
            
            if flow
            if ~exist(['PanoFlowResult/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'])
                [PSPNR_PanoFlow, sumSize_PanoFlow,sumViewedTilesArea_PanoFlow,viewportQPsizePerGrid_PanoFlow] = PanoFlow(set,vid,sec,2880/24,1440/12,sumSize_BSL,nExtra);
                
                save(['PanoFlowResult/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'],'PSPNR_PanoFlow','sumSize_PanoFlow','sumViewedTilesArea_PanoFlow','viewportQPsizePerGrid_PanoFlow');
            else
                load(['PanoFlowResult/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat']);
            end
            end
            
            
            %             plot(22:42,viewportQPsizePerGrid_Pano,'g');
            %             hold on;
            %             plot(22:42,viewportQPsizePerGrid_BSL,'r');
            
            %viewportQPsizePerGrid_PanoAve(qp-22+1) = viewportQPsizePerGrid_PanoAve(qp-22+1)+viewportQPsizePerGrid_Pano(qp-22+1);
            %viewportQPsizePerGrid_BSLAve(qp-22+1) = viewportQPsizePerGrid_BSLAve(qp-22+1)+viewportQPsizePerGrid_BSL(qp-22+1);
            if flow
            for user=1:usernum
                [sumSize_BSL_user,index] = sort(sumSize_BSL(user,:),'ascend');
                AllSumSize_BSL=[AllSumSize_BSL;sumSize_BSL_user];
                AllPSPNR_BSL=[AllPSPNR_BSL;PSPNR_BSL(user,index)];
                
                [sumSize_Pano_user,index] = sort(sumSize_Pano(user,:),'ascend');
                AllSumSize_Pano=[AllSumSize_Pano;sumSize_Pano_user];
                AllPSPNR_Pano=[AllPSPNR_Pano;PSPNR_Pano(user,index)];
                
                [sumSize_PanoFlow_user,index] = sort(sumSize_PanoFlow(user,:),'ascend');
                AllSumSize_PanoFlow=[AllSumSize_PanoFlow;sumSize_PanoFlow_user];
                AllPSPNR_PanoFlow=[AllPSPNR_PanoFlow;PSPNR_PanoFlow(user,index)];
            end
            end
        end
    end
end

%% DEBUG
% sumSize_PanoAve = sumSize_PanoAve(1:21);
% PSPNR_PanoAve = PSPNR_PanoAve(1:21);
% sumSize_BSLAve = sumSize_BSLAve(1:21);
% PSPNR_BSLAve = PSPNR_BSLAve(1:21);

%%
if 0
    ssBS = mean(AllSumSize_BSL(:,1));
    ssBE = mean(AllSumSize_BSL(:,42-22+1));
    ssPS = mean(AllSumSize_Pano(:,1));
    ssPE = mean(AllSumSize_Pano(:,42-22+1+nExtra));
    ssPFS = mean(AllSumSize_PanoFlow(:,1));
    ssPFE = mean(AllSumSize_PanoFlow(:,42-22+1+nExtra));
    pB=zeros(1,20);
    pBn=zeros(1,20);
    pP=zeros(1,20);
    pPn=zeros(1,20);
    pPF=zeros(1,20);
    pPFn=zeros(1,20);
    for i=1:size(AllSumSize_BSL,1)
        for j=1:42-22+1
            range=max(1,ceil((AllSumSize_BSL(i,j)-AllSumSize_BSL(i,1))/(AllSumSize_BSL(i,42-22+1)-AllSumSize_BSL(i,1))*20));
            pB(range) = pB(range)+AllPSPNR_BSL(i,j);
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
    for i=1:size(AllSumSize_PanoFlow,1)
        for j=1:42-22+1+nExtra
            range=max(1,ceil((AllSumSize_PanoFlow(i,j)-AllSumSize_PanoFlow(i,1))/(AllSumSize_PanoFlow(i,42-22+1+nExtra)-AllSumSize_PanoFlow(i,1))*20));
            pPF(range) = pPF(range)+AllPSPNR_PanoFlow(i,j);
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
    plot(mean(AllSumSize_BSL),mean(AllPSPNR_BSL),'r');
    hold on;
    plot(mean(AllSumSize_Pano),mean(AllPSPNR_Pano),'g');
    if flow
    hold on;
    plot(mean(AllSumSize_PanoFlow),mean(AllPSPNR_PanoFlow),'b');
    end
    xlabel('Bandwidth Consumption / bps');%x轴标记
	ylabel('PSNR-F / dB');%y轴标记
    legend('fixed tiling with traditional JND(Flare)',...
        'variable tiling with traditional JND(Pano)',...
        'variable tiling with flow JND(ours)');
end
%xlim([500 5000]);

%viewportQPsizePerGrid_PanoAve = viewportQPsizePerGrid_PanoAve/nAve;
%viewportQPsizePerGrid_BSLAve = viewportQPsizePerGrid_BSLAve/nAve;
% plot(22:42,viewportQPsizePerGrid_PanoAve,'g');
% hold on;
% plot(22:42,viewportQPsizePerGrid_BSLAve,'r');