% calculate MSE value for all tiles
clear all;
close all;
clc;

%setenv('PATH', [getenv('PATH') '/usr/local/ffmpeg/bin']);

warning('off','all');

Set=1; % Set=1 or 2
Vid=2; % Vid=[1,2,3,4,5,7,8];
usernum = 1; % usernum range 1-48
for set=Set
    for vid=Vid
        % make a list of seconds that need to be processed
        mkdir(['randSecs/',num2str(set)]);
        if ~exist(['randSecs/',num2str(set),'/',num2str(vid),'.mat'],'file')
            Sec = 20+randperm(40);
            Sec = sort(Sec(1:10));
            save(['randSecs/',num2str(set),'/',num2str(vid),'.mat'],'Sec');
        else
            Sec = cell2mat(struct2cell(load(['randSecs/',num2str(set),'/',num2str(vid),'.mat'])));
        end
        
        for sec=11:1:70 % sec=Sec,randomly processes 10 chunks
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
            
            nGridR = 12;
            nGridC = 24;
            tileW = 2880 / nGridC;
            tileH = 1440 / nGridR;
           %% calculate tile valueness for Pano scheme
            tiling = []; % generate 12*24 basic tiling matrix
            for i=1:nGridR
                for j=1:nGridC
                    tiling=[tiling;i,i,j,j]; % left-top to right-bottom
                end
            end
            
            [~,MSE] = calcTileMse(set, vid, sec,1,tiling,tileW,tileH,'real','real',1); % calculate MSE for each tiles with users' data under Pano scheme
            for user=1:usernum
                mkdir(['ratio/',num2str(set),'/',num2str(vid-1),'/',num2str(user)]);
                userMSE = squeeze(MSE(user,:,:));
                valueness = (userMSE(:,42-22+1)-userMSE(:,22-22+1)) ./ 1;
                for i=1:size(tiling,1)
                    if valueness(i,1)~=0 % calculate size of tiles for QP=22 and 42
                        temp22 = calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW, 22);
                        temp42 = calcTileSize(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW, 42);
                        valueness(i,1) = valueness(i,1)/(temp22-temp42);
                    end
                end
                
                valueness(valueness<0)=0;
                new = zeros(12,24);
                for row=1:12
                    new(row,:) = valueness(row*24-23:row*24);
                end
                new = new .* usernum;
                % store SMSE for all users
                dlmwrite(['ratio/',num2str(set),'/',num2str(vid-1),'/',num2str(user),'/',num2str(sec*30-29),'_Value_SMSE.txt'],new,' '); 
            end
            
           %% calculate tile valueness for OFB-VR scheme
            tiling = []; % regenerate 12*24 basic tiling matrix
            for i=1:nGridR
                for j=1:nGridC
                    tiling=[tiling;i,i,j,j]; % left-top to right-bottom
                end
            end
            
            [~,MSE] = calcTileMseFlow(set, vid, sec,1,tiling,tileW,tileH,'real','real',1); % calculate MSE for each tiles with users' data under OFB-VR scheme
            for user=1:usernum
                mkdir(['ratioF/',num2str(set),'/',num2str(vid-1),'/',num2str(user)]);
                userMSE = squeeze(MSE(user,:,:));
                valueness = (userMSE(:,42-22+1)-userMSE(:,22-22+1)) ./ 1; 
                for i=1:size(tiling,1)
                    if valueness(i,1)~=0 % calculate size of tiles for QP=22 and 42
                        temp22 = calcTileSizeFlow(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW, 22);
                        temp42 = calcTileSizeFlow(set,vid,sec,tiling(i,1),tiling(i,2),tiling(i,3),tiling(i,4),tileH,tileW, 42);
                        valueness(i,1) = valueness(i,1)/(temp22-temp42);
                    end
                end
                
                valueness(valueness<0)=0;
                new = zeros(12,24);
                for row=1:12
                    new(row,:) = valueness(row*24-23:row*24);
                end
                new = new .* usernum;
                % store SMSE for all users
                dlmwrite(['ratioF/',num2str(set),'/',num2str(vid-1),'/',num2str(user),'/',num2str(sec*30-29),'_Value_SMSE.txt'],new,' ');
            end
        end
    end
end
