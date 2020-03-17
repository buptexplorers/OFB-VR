clear;

circle = [[0.280357142857143 0.126190476190476 0.0714285714285714 0.528571428571429];...
        [0.262942675159236 0.110456553755523 0.135146496815287 0.0765832106038292];...
        [0.380503144654088 0.148425787106447 0.0859538784067086 0.304347826086956];...
        [0.34965034965035 0.107511045655376 0.117882117882118 0.0957290132547865];...
        [0.576519916142558 0.226386806596702 0.119496855345912 0.11544227886057];...
        [0.572327044025157 0.140929535232384 0.171907756813417 0.0764617691154423]];



% 
BSL_high = load('BSL_high.txt');
% rowrank = randperm(size(BSL_high, 1)); % 随机打乱的数字，从1~行数打乱
% BSL_high = BSL_high(rowrank, :);%%按照rowrank打乱矩阵的行数
% 
BSL_low = load('BSL_low.txt');
% rowrank = randperm(size(BSL_low, 1)); % 随机打乱的数字，从1~行数打乱
% BSL_low = BSL_low(rowrank, :);%%按照rowrank打乱矩阵的行数
% 
Pano_high = load('OFB_high.txt');
% rowrank = randperm(size(Pano_high, 1)); % 随机打乱的数字，从1~行数打乱
% Pano_high = Pano_high(rowrank, :);%%按照rowrank打乱矩阵的行数
% 
Pano_low = load('OFB_low.txt');
% rowrank = randperm(size(Pano_low, 1)); % 随机打乱的数字，从1~行数打乱
% Pano_low = Pano_low(rowrank, :);%%按照rowrank打乱矩阵的行数
% 
OFB_high = load('Pano_high.txt');
% rowrank = randperm(size(OFB_high, 1)); % 随机打乱的数字，从1~行数打乱
% OFB_high = OFB_high(rowrank, :);%%按照rowrank打乱矩阵的行数
% 
OFB_low = load('Pano_low.txt');
% rowrank = randperm(size(OFB_low, 1)); % 随机打乱的数字，从1~行数打乱
% OFB_low = OFB_low(rowrank, :);%%按照rowrank打乱矩阵的行数


BSL_high_sampled = [];
BSL_low_sampled = [];
Pano_high_sampled = [];
Pano_low_sampled = [];
OFB_high_sampled = [];
OFB_low_sampled = [];

gap = 110;
for i = gap:gap:2000
    BSL_high_sampled = [BSL_high_sampled;... 
        [mean(BSL_high(i-gap+1:i,3)),mean(BSL_high(i-gap+1:i,4))]];
    BSL_low_sampled = [BSL_low_sampled;...
        [mean(BSL_low(i-gap+1:i,3)),mean(BSL_low(i-gap+1:i,4))]];
    Pano_high_sampled = [Pano_high_sampled; 
        [mean(Pano_high(i-gap+1:i,3)),mean(Pano_high(i-gap+1:i,4))]];
    Pano_low_sampled = [Pano_low_sampled; ...
        [mean(Pano_low(i-gap+1:i,3)),mean(Pano_low(i-gap+1:i,4))]];
    OFB_high_sampled = [OFB_high_sampled;... 
        [mean(OFB_high(i-gap+1:i,3)),mean(OFB_high(i-gap+1:i,4))]];
    OFB_low_sampled = [OFB_low_sampled;... 
        [mean(OFB_low(i-gap+1:i,3)),mean(OFB_low(i-gap+1:i,4))]];
end

figure(1);
plot(OFB_high_sampled(:,2),OFB_high_sampled(:,1)/1000,...
    'LineStyle','none','Marker','o','MarkerSize',5,...
    'MarkerFace','[0.2,0.63,0.79]','MarkerEdge','b','LineWidth',1);
hold on;
plot(OFB_low_sampled(:,2),OFB_low_sampled(:,1)/1000,...
    'LineStyle','none','Marker','o','MarkerSize',5,...
    'MarkerEdge','b','LineWidth',1);
hold on;
plot(Pano_high_sampled(:,2),Pano_high_sampled(:,1)/1000,...
    'LineStyle','none','Marker','o','MarkerSize',5,...
    'MarkerFace','[1,0.5,0]','MarkerEdge','r','LineWidth',1);
hold on;
plot(Pano_low_sampled(:,2),Pano_low_sampled(:,1)/1000,...
    'LineStyle','none','Marker','o','MarkerSize',5,...
    'MarkerEdge','r','LineWidth',1);
hold on;
plot(BSL_high_sampled(:,2),BSL_high_sampled(:,1)/1000,...
    'LineStyle','none','Marker','o','MarkerSize',5,...
    'MarkerFace','[0.74,0.99,0.79]','MarkerEdge','[0.24,0.57,0.25]','LineWidth',1);
hold on;
plot(BSL_low_sampled(:,2),BSL_low_sampled(:,1)/1000,...
    'LineStyle','none','Marker','o','MarkerSize',5,...
    'MarkerEdge','[0.24,0.57,0.25]','LineWidth',1);

figure1 = plot([mean(OFB_high_sampled(:,2)),mean(OFB_low_sampled(:,2))],...
    [mean(OFB_high_sampled(:,1)),mean(OFB_low_sampled(:,1))]/1000,'-or','Color',[0,0,0]);
hold on;
plot([mean(Pano_high_sampled(:,2)),mean(Pano_low_sampled(:,2))],...
    [mean(Pano_high_sampled(:,1)),mean(Pano_low_sampled(:,1))]/1000,'-or','Color',[0,0,0]);
hold on;
plot([mean(BSL_high_sampled(:,2)),mean(BSL_low_sampled(:,2))],...
    [mean(BSL_high_sampled(:,1)),mean(BSL_low_sampled(:,1))]/1000,'-or','Color',[0,0,0]);

annotation('ellipse',circle(1,:),'Color',[0.24,0.57,0.25],'LineWidth',2,'LineStyle','--');
annotation('ellipse',circle(2,:),'Color',[0.74,0.99,0.79],'LineWidth',2,'LineStyle','--');
annotation('ellipse',circle(3,:),'Color',[1,0,0],'LineWidth',2,'LineStyle','--');
annotation('ellipse',circle(4,:),'Color',[1,0.5,0],'LineWidth',2,'LineStyle','--');
annotation('ellipse',circle(5,:),'Color',[0,0,1],'LineWidth',2,'LineStyle','--');
annotation('ellipse',circle(6,:),'Color',[0.2,0.63,0.79],'LineWidth',2,'LineStyle','--');

legend('OFB-VR with high bandwidth', 'OFB-VR with low bandwidth',...
    'Pano with high bandwidth','Pano with low bandwidth', ...
    'Plato with high bandwidth','Plato with low bandwidth');

xlabel('PSNR-OF/dB');
ylabel('Rebuffer Rate/%');



axis([55,80,0,0.2]);
set(gca,'linewidth',1,'fontsize',15,'fontname','Times');

