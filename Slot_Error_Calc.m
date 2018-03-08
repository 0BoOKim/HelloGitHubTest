function [ Error_Rate ] = Slot_Error_Calc( Data_Rate, slot_time, EsN0)
% 이 함수는 에러를 계산합니다.
% 자세한 설명은 생략한다.

List_Data_Rate = [ 6.5 13.0 19.5 ]*10^6;

% 1) 1/2 Punctured convolutional code for BPSK, ex) 6.5 Mpbs
if Data_Rate == List_Data_Rate(1) 
    t = poly2trellis(7, [171 133]);
    d = distspec(t,7);
    Cd= d.weight;
    Pb = 0;
    for i = 0:length(Cd)-1
        Pb = Pb + Cd(i+1)*qfunc(sqrt(2*(d.dfree+i)*(EsN0))); 
    end
    Pb(Pb>=1) = 1;  % approximation is accurate for medium-to-high SNR values. 
    Error_Rate = 1-(1-Pb).^(List_Data_Rate(1)*slot_time);
    
elseif Data_Rate == List_Data_Rate(2)
    t = poly2trellis(7, [171 133]);
    d = distspec(t,7);
    Cd= d.weight;
    Pb = 0;
    Pd = 0;
    for i = 0:length(Cd)-1
    Pb = Pb + Cd(i+1)*qfunc(sqrt((d.dfree+i)*(EsN0))); 
    end
    Pb(Pb>=1) = 1;
    Error_Rate = 1-(1-Pb).^(List_Data_Rate(2)*slot_time);
    
elseif Data_Rate == List_Data_Rate(3)
    Cd = [42, 201, 1492,  10469, 62935, 379546, 2252394];
    d.dfree = 5;
    Pb = 0;
    Pd = 0;
    for i = 0:length(Cd)-1
        Pb = Pb + Cd(i+1)*qfunc(sqrt((d.dfree+i)*(EsN0))); 
    end

    Pb = (1/3)*Pb;
    Pb(Pb>=1) = 1;
    Error_Rate = 1-(1-Pb).^(List_Data_Rate(3)*slot_time);
else
     error('Unexpected input value as Data_Rate!!'); 
end

end

