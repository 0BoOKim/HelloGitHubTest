function [ Slot_Array_MAC_STATE, Slot_Array_RSSI_Record, Sim_Time_in_Slot ] = Adding_Time_Slot( Slot_Array_MAC_STATE, Slot_Array_RSSI_Record, Sim_Time_in_Slot, Additional_Time_Slot )
%UNTITLED2 이 함수의 요약 설명 위치
%   자세한 설명 위치

STAs.MAC_STATE = zeros(Num_STAs, L_Rec);  % 0:IDLE Odd #:TX  Even #:RX
STAs.RSSI_Record = zeros(Num_STAs, L_Rec);
STAs.RSSI_Record(STAs.RSSI_Record == 0) = NaN;

Slot_Array_MAC_STATE = [Slot_Array_MAC_STATE zeros(length(Slot_Array_MAC_STATE(:,1)), Additional_Time_Slot)];
Slot_Array_RSSI_Record = [Slot_Array_RSSI_Record zeros(length(Slot_Array_RSSI_Record(:,1)), Additional_Time_Slot)];

Sim_Time_in_Slot = Sim_Time_in_Slot + Additional_Time_Slot;
disp('Simulation Time is expanded.');
disp('Current_Simulation Time is ');
disp(Sim_Time_in_Slot);
end

