close all;
clear all;


Target_Coverage = 300;
Taget_Number_of_STAs = 70;
U_Slot_Time = 9*10^-6;
Noise_Floor = -100;
Noise_Floor_in_mW = 10^(Noise_Floor/10);
SINR_Interval = 0.0001;

Longest_Distance = sqrt(2*Target_Coverage^2);


% Max_SINR = Path_Loss(0,0,0.001,0.001)
% Max_SINR_in_mw =  10^(Max_SINR/10)/Noise_Floor_in_mW
% Max_SINR = 100;
% Max_SINR_in_mw =  10^(Max_SINR/10)
% 
% 
% Min_SINR = Path_Loss(0,0, Target_Coverage,Target_Coverage)
% Min_SINR_in_mw =  10^(Min_SINR/10)/(Taget_Number_of_STAs*Max_SINR_in_mw+Noise_Floor_in_mW)


EsN0 = 0:0.001:15;
% EsN0 = 0:0.01:100;
List_Data_Rate = [ 6.5 13.0 19.5 ]*10^6;
% Table_BER = zeros(length(List_Data_Rate)+1, length(EsN0));
Table_SlotER = zeros(length(List_Data_Rate)+1, length(EsN0));
% Table_BER(1,:) = EsN0; 
Table_SlotER(1,:) = EsN0; 

for i = 1:length(EsN0)
    for j = 1:length(List_Data_Rate)
        Table_SlotER(1+j,i) = Slot_Error_Calc(List_Data_Rate(j), U_Slot_Time, EsN0(i));
    end
end

semilogy(EsN0,Table_SlotER(2,:),'r-');
save 'Error_Table.mat' 'Table_SlotER';