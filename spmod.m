function [result]=spmod(a,b)
       if a==0
           result=b;
       else
           result=mod(a,b);
       end
       result(result==0)=b;
end