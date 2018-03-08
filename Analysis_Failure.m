function [ Table_Results, Frame_List_SRC_Failure  ] = Analysis_Failure( STAs )
% 이 함수는 노드의 프레임 별 중복수신 수를 입력값으로 하여,
% 프레임이 전달 받지 못한 원인을 출력한다.
% 다음에 대한 평균을 취함
% Total : 전달받지 못한 프레임의 수
% Pruned:   과도한 pruning으로 인해 해당 프레임은 인접한 어느 노드로 부터 프레임을 전달 받지 못함.
%           다만 인접한 노드 중 어느 하나도 프레임을 갖고 있지 않는 경우는 구분하지 않았다;
%           따라서,...
% Errored : 충돌/간섭에 의한 채널에러 프레임의 수

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

