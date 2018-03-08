function [ Pruning_Probability_Table, Pruning_Probability_Table2 ] = Get_Pruning_Probability_Table_3( N_STA, Measurement_Duplication_per_Frame_RX, Measurement_Duplication_per_Frame_TX, Seed_Number, Sim_ID)
% Get_Pruning_Probability_Table 이 함수의 요약 설명 위치
% This function generates a table that include with Probability information based on their duplication level.
% for each node.
% The output 'Pruning_Probability_Table' have these information.
% Col is STA-ID and row is Duplication level.
% Each information element is probaility. (it gets from ratio # of Pure-Duplication Event to # of All of Duplication Event.)
% Seed_Number = Seed_List(Rep_Index)
Pruning_Probability_Table = zeros(N_STA,  max(max(Measurement_Duplication_per_Frame_RX))) -1;
Pruning_Probability_Table2 = zeros(N_STA,  max(max(Measurement_Duplication_per_Frame_RX))) -1;
for i = 1:N_STA
    MAX_Duplication_Count = max(Measurement_Duplication_per_Frame_RX(i,:));
    
    for j = 1:MAX_Duplication_Count
        Pruning_Probability_Table(i,j) = length(find(Measurement_Duplication_per_Frame_TX(i, Measurement_Duplication_per_Frame_RX(i,:) == j)==1)) ...
                                        / length(find(Measurement_Duplication_per_Frame_RX(i,:) == j));
                                 % length(find(Measurement_Duplication_per_Frame_RX(i,:) == j))
        Pruning_Probability_Table2(i,j) = sum(Measurement_Duplication_per_Frame_TX(i, Measurement_Duplication_per_Frame_RX(i,:) == j))   ...
                                        / length(find(Measurement_Duplication_per_Frame_RX(i,:) == j));
     
    end
    
end

filename = strcat(pwd, '\', Sim_ID, '\', 'Pruning_Table_', num2str(N_STA), '_STAs_', num2str(Seed_Number),'.mat');
save(filename, 'Pruning_Probability_Table');

filename = strcat(pwd, '\', Sim_ID, '\', 'Pruning_Table2_', num2str(N_STA), '_STAs_', num2str(Seed_Number),'.mat');
save(filename, 'Pruning_Probability_Table2');

filename = strcat(pwd, '\', Sim_ID, '\', 'DR_per_Frame', num2str(N_STA), '_STAs_', num2str(Seed_Number),'.mat');
save(filename, 'Measurement_Duplication_per_Frame_TX');

filename = strcat(pwd, '\', Sim_ID, '\', 'DC_Per_Frame', num2str(N_STA), '_STAs_', num2str(Seed_Number),'.mat');
save(filename, 'Measurement_Duplication_per_Frame_RX');

end

