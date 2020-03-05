clear;
setenv('PATH', [getenv('PATH') '/usr/local/ffmpeg/bin']);

set = 1;
vid = 2;
orgFrameImgFolderPath = sprintf('image/%d/%03d',set,vid);
mkdir(orgFrameImgFolderPath);

for sec = 1:70
    frameAbs = (sec-1)*30;
    for f=frameAbs:frameAbs+29
        if ~exist(sprintf('%s/%04d_org.png', orgFrameImgFolderPath, f),'file')
            if f <= (sec-1)*30
                command = ['ffmpeg -i ',sprintf('videos/%d/%d/%03d.mp4',set,vid,sec-2),' -vf "select=eq(n\,',num2str(f - (sec-2)*30-1),')" -vframes 1 ',sprintf('%s/%04d_org.png', orgFrameImgFolderPath, f)];
                system(command);
            else
                command = ['ffmpeg -i ',sprintf('videos/%d/%d/%03d.mp4',set,vid,sec-1),' -vf "select=eq(n\,',num2str(f - (sec-1)*30-1),')" -vframes 1 ',sprintf('%s/%04d_org.png', orgFrameImgFolderPath, f)];
                system(command);
            end
        end
    end
end
