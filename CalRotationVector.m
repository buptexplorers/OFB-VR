function [Vector]=CalRotationVector(Data)
   [x y]=size(Data);
   sum=[0,0,0];
   for i=1:x-1
     A=Data(i,:);
     B=Data(i+1,:);
     sum=sum+B-A;
   end
   Vector=sum;
end