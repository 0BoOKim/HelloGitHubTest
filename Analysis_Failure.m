function [ Table_Results, Frame_List_SRC_Failure  ] = Analysis_Failure( STAs )
% �� �Լ��� ����� ������ �� �ߺ����� ���� �Է°����� �Ͽ�,
% �������� ���� ���� ���� ������ ����Ѵ�.
% ������ ���� ����� ����
% Total : ���޹��� ���� �������� ��
% Pruned:   ������ pruning���� ���� �ش� �������� ������ ��� ���� ���� �������� ���� ���� ����.
%           �ٸ� ������ ��� �� ��� �ϳ��� �������� ���� ���� �ʴ� ���� �������� �ʾҴ�;
%           ����,...
% Errored : �浹/������ ���� ä�ο��� �������� ��

N_STA = max(STAs.ID);
Table_Results = zeros(N_STA, 6);

for i = 1 : N_STA
    Table_Results(i,1) = length(find(STAs.Overhearing_Count_Frame(i,:) == 0));  % Total
    Table_Results(i,2) = length(find(STAs.Overhearing_Count_Frame2(i,:) == 0)); % Pruned
    Table_Results(i,3) = Table_Results(i,1)-Table_Results(i,2);                 % Errored
    Table_Results(i,4) = Table_Results(i,2)/Table_Results(i,1);                 % ratio-pruned
    Table_Results(i,5) = Table_Results(i,3)/Table_Results(i,1);                 % ratio-errored
    Table_Results(i,6) = length(find(STAs.Queue_Frame_List(i,:) == -3));       % protected
end

N_MPDU = length(STAs.Queue_Frame_List);
SRC_Failure = 0;
Frame_List_SRC_Failure = zeros(N_MPDU, 1);
for i = 1: N_MPDU
    Frame_List_SRC_Failure(i) = length(find(STAs.Queue_Frame_List(:,i)>0));
    
    if Frame_List_SRC_Failure(i) >= N_STA*0.5
        SRC_Failure = SRC_Failure + 1;
    end
    
end
Total = mean( Table_Results(:,1) )
Pruned = mean( Table_Results(:,2) )
Errored = mean( Table_Results(:,3) )
SRC_Failure
Protected = mean(Table_Results(:,6))

end

