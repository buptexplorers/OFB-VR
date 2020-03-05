% input: video, tiling infomation
% output: bitrate of videos with different qp
function [tileSize] = calcTileSizeFlow(set, vid,sec,sr,er,sc,ec,tileH,tileW,qp) %TODO 调整其他程序

chunkPath = sprintf('videos/%d/%d/%03d.mp4',set,vid,sec-1);
%chunkPath = sprintf('videos/%d/%03d/%03d.mp4',set,vid,sec);

%tileSizePath = sprintf('..\tileSize\%03d\%03d.mat',vid,sec);

%get the pixel-scale boundary
srP = tileH * (sr-1) + 1; % ffmpeg position start from 1
scP = tileW * (sc-1) + 1;
hP = tileH * (er-sr+1);
wP = tileW * (ec-sc+1);
tilePath = sprintf('tilesF/%d/%03d/%03d/%04d_%04d_%04d_%04d_%04d.mp4',set,vid,sec,wP,hP,scP,srP,qp);
%check if it exists
if ~exist(tilePath,'file')
    mkdir(sprintf('tilesF/%d/%03d/%03d',set,vid,sec));
    command = sprintf('ffmpeg -r 30 -i %s -r 30 -vf crop=%d:%d:%d:%d -c:v libx264 -qp %d %s', ...
        chunkPath, wP, hP, scP, srP, qp, tilePath);
    system(command);
end

fid = fopen(tilePath);
fseek(fid,0,'eof');
fsize = ftell(fid);
fclose(fid);
fsize = fsize /1024;
fsize = fsize*8; % Kbit
tileSize = fsize;

%save(tileSizePath,'tileSize');
end