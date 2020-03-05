clear;
flow = GetRotationVector(2,1,15);
flow = abs(acos((2-sum(flow.^2,2))/2)*180/pi);
speed  = GetRotationSpeed(2,1,15);
speedLowerBound = zeros(407,1);
for frame = 75:6105
    speedLowerBound(round(frame/15)) = min(speed((round(frame/15)-4):(round(frame/15)-1)));
end

figure(1)
x = 1:407;
plot(x,speed,'r','Linewidth',0.75);
hold on;
plot(x,speedLowerBound,'g','Linewidth',0.75);
hold on;
plot(x,flow,'b','Linewidth',0.75);
legend('ground truth','speed lower bound','optical flow speed');
hold on;
xlabel('time / frame');
ylabel('rotate speed / degs');
cov1 = cov(flow,speed);
cov2 = cov(speedLowerBound,speed);

figure(2)
delta1 = abs(speed - speedLowerBound)./speed;
delta2 = abs(speed - flow)./speed;
cdfplot(delta1);
hold on
cdfplot(delta2);
legend('speed lower bound','optical flow estimated speed');
xlabel('error ratio / %');
ylabel('CDF');
