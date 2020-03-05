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
AllSumSize_BSLF = [];
AllPSPNR_BSLF = [];
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
        
        mkdir(['baselineFlowResult/',num2str(nGridR),'_',num2str(nGridC),'/',num2str(set),'/',num2str(vid)]);
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
    
            if ~exist(['baselineFlowResult/',num2str(nGridR),'_',num2str(nGridC),'/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'])
                [PSPNR_BSLF,sumSize_BSLF,sumViewedTilesArea_BSLF,viewportQPsizePerGrid_BSLF] = baselineFlow(set,vid, sec, nGridR, nGridC);
                save(['baselineFlowResult/',num2str(nGridR),'_',num2str(nGridC),'/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'],'PSPNR_BSLF','sumSize_BSLF','sumViewedTilesArea_BSLF','viewportQPsizePerGrid_BSLF');
            else
                load(['baselineFlowResult/',num2str(nGridR),'_',num2str(nGridC),'/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat']);
            end
            
            %DEBUG
            %continue;
            
            if ~exist(['PanoFlowResult/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'])
                [PSPNR_PanoFlow, sumSize_PanoFlow,sumViewedTilesArea_PanoFlow,viewportQPsizePerGrid_PanoFlow] = PanoFlow(set,vid,sec,2880/24,1440/12,sumSize_BSLF,nExtra);
                
                save(['PanoFlowResult/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat'],'PSPNR_PanoFlow','sumSize_PanoFlow','sumViewedTilesArea_PanoFlow','viewportQPsizePerGrid_PanoFlow');
            else
                load(['PanoFlowResult/',num2str(set),'/',num2str(vid),'/',num2str(sec),'.mat']);
            end
            

            for user=1:usernum
                [sumSize_BSL_user,index] = sort(sumSize_BSL(user,:),'ascend');
                AllSumSize_BSL=[AllSumSize_BSL;sumSize_BSL_user];
                AllPSPNR_BSL=[AllPSPNR_BSL;PSPNR_BSL(user,index)];
                
                [sumSize_BSLF_user,index] = sort(sumSize_BSLF(user,:),'ascend');
                AllSumSize_BSLF=[AllSumSize_BSLF;sumSize_BSLF_user];
                AllPSPNR_BSLF=[AllPSPNR_BSLF;PSPNR_BSLF(user,index)];
                
                [sumSize_PanoFlow_user,index] = sort(sumSize_PanoFlow(user,:),'ascend');
                AllSumSize_PanoFlow=[AllSumSize_PanoFlow;sumSize_PanoFlow_user];
                AllPSPNR_PanoFlow=[AllPSPNR_PanoFlow;PSPNR_PanoFlow(user,index)];

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
    plot(mean(AllSumSize_BSL),mean(AllPSPNR_BSL),'r');
    hold on;
    plot(mean(AllSumSize_BSLF),mean(AllPSPNR_BSLF),'g');
    hold on;
    plot(mean(AllSumSize_PanoFlow),mean(AllPSPNR_PanoFlow),'b');
    hold on;
    xlabel('Bandwidth Consumption / bps');%x轴标记
	ylabel('PSPNR-F / dB');%y轴标记
    legend('fixed tiling with traditional JND(Flare)',...
        'fixed tiling with flow JND',...
        'variable tiling with flow JND(ours)');

%xlim([500 5000]);

%viewportQPsizePerGrid_PanoAve = viewportQPsizePerGrid_PanoAve/nAve;
%viewportQPsizePerGrid_BSLFAve = viewportQPsizePerGrid_BSLFAve/nAve;
% plot(22:42,viewportQPsizePerGrid_PanoAve,'g');
% hold on;
% plot(22:42,viewportQPsizePerGrid_BSLFAve,'r');