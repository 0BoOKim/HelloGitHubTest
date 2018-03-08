function [ Results ] = GET_SBM_Point( T )
%UNTITLED6 이 함수의 요약 설명 위치
%   이 함수는 각 노드의 Pruning Probability 값이 저장된 행렬로 부터, S, B, B1, M 포인트를 추출합니다.

Results = zeros(length(T(:,1)), 4);     % B, B1, M, S
Results(:,4) = T(:,1);  %S

for i = 1:length(T(:,1))
    
    Temp_Value = find(T(i,:) == 1, 1 , 'first');  % B
    if ~isempty(Temp_Value)
        Results(i,1) = Temp_Value;  % B
    else
        Results(i,1) = NaN;
    end
    
    Temp_Value = find(T(i,:) >= 0.9, 1 , 'first');  % B1
    if ~isempty(Temp_Value)
        Results(i,2) = Temp_Value;  % B1
    else
        Results(i,2) = NaN;
    end
    
    Temp_Value = find(T(i,:) == 1, 1 , 'last');     % M 
    if ~isempty(Temp_Value)
        Results(i,3) = Temp_Value;  % M
    elseif i ~= 1
        Results(i,3) = find( T(i,:) == max(T(i,:)), 1); % Insteadly, Maximum value
    else
        Results(i,3) = NaN;    
    end
    
  
end


end

