function [ p ] = Find_Nearest( Array, Value )
% 1���� Array���� Value�� ���� ����� ���� ã���ִ� �Լ��̴�.

if ( max(Array) < Value )
%     Higher_Value = length(Array);
    p = length(Array);
else    
%     Higher_Value = find(Array >= Value, 1);
    tmp = abs(Array-Value);
    p = find(tmp==min(tmp)); %index of closest value

end

% Lower_Value = Higher_Value-1;
% 
% if Lower_Value > 0
%     if (Value-Array(Lower_Value)) <= (Array(Higher_Value)-Value) 
%         p = Lower_Value;
%     else
%         p = Higher_Value;
%     end
% else
%     p = Higher_Value;    
% end

end

