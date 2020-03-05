clear all;
close all;
clc;

%setenv('PATH', [getenv('PATH') '/usr/local/sbin:/usr/local/opt/qt/bin:/usr/local/opt/opencv@3/bin:/usr/local/bin:/opt/local/bin:/opt/local/sbin:/opt/local/sbin:/opt/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin:/Library/Apple/bin']);
setenv('PATH', [getenv('PATH') '/usr/local/ffmpeg/bin']);

warning('off','all');

Set=1;
Vid=[2]%,2,3,4,5,7,8];
for set=Set
    for vid=Vid
        %make a list of seconds that need to be processed
        mkdir(['randSecs/',num2str(set)]);
        if ~exist(['randSecs/',num2str(set),'/',num2str(vid),'.mat'],'file')
            Sec = (3:70);
            save(['randSecs/',num2str(set),'/',num2str(vid),'.mat'],'Sec');
        else
            Sec = cell2mat(struct2cell(load(['randSecs/',num2str(set),'/',num2str(vid),'.mat'])));
        end
        
        for sec=11:1:70
            %% ���chunk�������⣬����
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
            
            calcTileValueness(set,vid,sec);
            calcTileValuenessFlow(set,vid,sec);
        end
    end
end
