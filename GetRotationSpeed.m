function [result]=GetRotationSpeed(videoId,userId,framegap)
% input: videoId userId whose frame interval is framegap
% output: the corresponding rotation speed
% eg.videoId=1;userId=1;framegap=15;
speed=[];
for j=videoId:videoId % number of video
    % one image for a video
    for num=userId:userId  % number of user
        m=readtable(['traj/Experiment_',num2str(1),'/',num2str(num),'/video_',num2str(j-1),'.csv']);
        Map=cell(48,1); % store X,Y,Z location of each user in every frame
        data_list=table2array(m(1:end,3:6));
        time_list=table2array(m(1:end,2));
        [x,y]=size(data_list);
        TXYZ=[];
        for i=1:48
            Map{i}=containers.Map();
        end
        % get time_list and correspond TXYZ
        for i=1:x
            q2=data_list(i,:);
            tempTimexyz=[2*q2(1)*q2(3)+2*q2(2)*q2(4),2*q2(2)*q2(3)-2*q2(1)*q2(4),1-2*q2(1)*q2(1)-2*q2(2)*q2(2)]; % quaternion to XYZ
            TXYZ=[TXYZ;tempTimexyz];
        end
        
        % initialize data storage matrix        
        for i=1:x % convert the data to the coordinates of each frame, and store in Map
            frame=floor(time_list(i,1)/0.033);
            Map{userId}(num2str(frame))=[TXYZ(i,1),TXYZ(i,2),TXYZ(i,3)];
        end
        
        % add Map into dataToBeHandled by the interval of framegap, and calculate the rotation speed
        for i=1:framegap:floor(time_list(x,1)/0.033)
            Start=i;
            End=i+framegap;
            dataToBeHandled=[];
            for k=Start:End
                if Map{num}.isKey(num2str(k))
                    dataToBeHandled=[dataToBeHandled;Map{num}(num2str(k))];
                end
            end
            [mx my]=size(dataToBeHandled);
            sum=0;
            for i=1:mx-1
                A=dataToBeHandled(i,:);
                B=dataToBeHandled(i+1,:);
                tempsum=(acos(dot(A,B)/(norm(A)*norm(B))))*180/pi;
                sum=tempsum+sum;
            end
            Angle=sum;
            Rotationspeed=abs(Angle*1.0/(framegap*1.0/30));
            speed=[speed;Rotationspeed];
        end
    end
    
end
result=speed;

end


