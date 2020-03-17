bw_path = './bw_track/';
files = dir(strcat(bw_path,'*.log'));
bw_statistic = zeros(length(files),2);
sum_bw = [];
for i=1:length(files)
    bw_raw_data = load(strcat(bw_path,files(i).name));
    sum_bw = [sum_bw; bw_raw_data];
    bw_statistic(i,:) = [mean(bw_raw_data(:,2)/5), std(bw_raw_data(:,2)/5)];
end

figure(2);
plot(1:length(sum_bw),sum_bw(:,2)/2);
hold on
plot(1:length(sum_bw),sum_bw(:,2)/5);

xlabel('Time/s');
ylabel('Badwidth/Mbps');

set(gca,'linewidth',1,'fontsize',15,'fontname','Times');

axis([0,16000,0,40]);

legend('high bandwidth', 'low bandwidth');
mean_badnwidth = [mean(sum_bw(:,2)/3), mean(sum_bw(:,2)/6)]
