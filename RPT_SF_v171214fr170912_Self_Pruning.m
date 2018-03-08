% Repetition of Simple Flooding - 17.12.14 - %
% bellow functions are added.

% 17-12-14
% 실험 결과를 쉽게 저장할 수 있도록 시뮬레이션 코드를 수정함.

% 17-10-02
% AFLD2의 적응 기간을 재전송 기간을 결정하는 방식과 같은 방법으로 결정함(X).(fixed time -> adaptation time based on number of nodes)


% 17-09-18
% 1) 다른 유형의 오버히어링 기간(Mode 3(보류), Mode 4(보류)) - (see 17-09-18)
% 2) Dynamic Duplication Counter Threshold.(instead of Retransmission Probability)

% 17-09-12
% 1) 프레임 단위의 재전송 효과를 측정하는 기능 추가(미구현)
%    프레임의 재전송을 위해 re-enque 하였을 때, 인접 노드 중 해당 프레임을 수신하지 못한 노드의 비율을 지표로 함.
% 2) 노드별로 오버히어링 시간을 측정함.(구현됨)   

% 17-09-06 -> 17-09-11
% 1) FLD2 재전송에서 DC_Threshold를 응용하는 다른 방법 추가
%    DC_Threshold 이하가 아닌, DC_Threshold 일 때.
%    실제 기법이 되기 보다는 각 DC_Threshold 별 재전송 효과를 측정하기 위함이며,
%    이를 통해, DC 수준에 따른 확률적 재전송을 설계
%
% 2) 노드는 측정된 자신의 최대 중복 수신 횟수에 따라 overhearing time을 계산함.

% 17-09-04
% 1) FLD2 재전송에서 중복 수신 횟수를 카운트하는 기간을 다르게 설정
% Mode_OH_Time = 2

% 17-09-03
% 1) FLD2에서 모든 노드가 재전송을 수행하는 기능을 추가함.
% FLD2_ReTx_Mode = 1;

% 17-08-08
% 1)  FLD2에서 소스 노드의 재전송을 수행하기 위한 코드를 추가함.
%       FLD2가 단독으로 사용되는 경우, 재전송을 위한 대기 시간을 얻을 때 
%       FLD1이 사용하는 확률을 사용할 수 없으므로 FLD2가 사용하는 pruning 확률을 이용하는 것으로 변경하여야함.
%       그런데 이 확률은 변화한다...(아직 구현 안됨)
%
% 2) FLD2에서 재전송을 위해 고정된 대기 시간을 사용함.(구현됨)
%   Opt_RED_Retransmission_Fixed_Overhearing_Mode_On



close all;
clear all;

[Y, FS]=audioread('Bastions Ultimate Ability Sound.mp3',[1 Inf]);
sound(10*Y, FS)
% pause(3.0);
% break;


tic;
% Probability_List = [ 1.0 0.9 0.8 0.7 0.6 0.5 0.4 0.3 0.2 0.1];
Probability_List = 1.0;
% Probability_List = [ 1.0 0.9 0.8 0.7 0.6 0.5 0.4 0.3 0.2 0.1]*0.1;
% Probability_List = [0.03 0.02 0.01];
% Num_of_Repitition = length(Probability_List);


% Major Simulation Parameters --------------------------------------------%
% Num_of_STAs = 80;   % number of STAs exc, 36 for grid topology
Contention_Window = 15;
MPDU_Size = 1000;    % Bytes;
Traffic_Volumes = 1.0*10^6; % unit: Byte
MCS = [ 6.5 13.0 19.5 26.0 39 52 58.5 65]*10^6;
Data_Rate = MCS(3);
Target_Coverages = 400;
% Opt_CH_Error_On = 0;
%-------------------------------------------------------------------------%

% Major Simulation Parameters for ICTC2107 Simulation Results-------------%
Seed_List = 51:60;%[51:54 56:61]; %[51:58 60:61];
Simulation_ID = '180129-03'  % Simulation Identification(Name)

Num_of_Repitition = length(Probability_List)*length(Seed_List);

Num_of_STAs = 60;   % number of STAs

Opt_Building_Pruning_Table = 1;     %If this option is "1", simulator makes Pruning Probability Table.
On_Save_STAs_Info = 1;              %If this option is "1", simulator makes STA's Information Data.
        if Opt_Building_Pruning_Table || On_Save_STAs_Info 
            Save_Path = strcat(pwd, '\', Simulation_ID);    
            mkdir(Save_Path);
        end
Para_Sim_Time  = 6.0;
CBF_Th = 4;
Parameter_Set = [1 0 0 0 0];
    % Description of Parameters
    % CASE [0 0 0] : use 1/N as transmission probability without Pruning
    % 1st Parameter: Both Fixed_Transmission_Probability_Mode_On and its Value (0.0 1.0] 
    %               i.e.,) Opt_Fixed_TX_Probability_On
    % 2nd Parameter: Probabilistic Pruning Scheme for Individual STAs(PP2->FLD2), this mode use duplication ratio as Pruning probability.
    %               i.e.,)Opt_Measurement_Prob_Pruning_Scheme_Individulal_Type
    % 3rd Parameter: Proposed-pruning scheme for ICTC2017(AFLD). it gets pruning probablity by approximation of duplication ratio
    %               i.e.,)Opt_Probabilistic_Counter_Based_Pruning_Scheme
    %               Note) Detailed options are in below lines.
    % 4th Parameter: Retransmission mode on.
    % 5th Parameter: If > 0, Fixed overhearing time mode is enable in Retransmission Mode. its value is fixed_overhearing time itself.

 if Parameter_Set(3)   % if Opt_Probabilistic_Counter_Based_Pruning_Scheme is enabled,
        Para_mu = 1000;
        Para_Fixed_S_Value_Small = 0.1;
        Para_Fixed_S_Value_Large = 0.1;
        Para_Initial_M_Value = 5; % not required
        Para_Adaptation_Duration = 0.002; % refer to #251 slide(결과정리 2016), 1.0s is used in ICTC2017
 end
%-------------------------------------------------------------------------%


% Preallocation values 
Slot_Error = zeros(1, Num_of_STAs+1);
Error_Decision_Result = zeros(1, Num_of_STAs+1);
SIR = zeros(1, Num_of_STAs+1);
Sim_Result_Type_1 = zeros(Num_of_Repitition, 14);
RSSI_Colector = 0;
% Sim_Result_Type_1 = 0;
% Preallocation values -END-

% Various Options are here.
Opt_All_Figs_On = 0;
Opt_Measurement_On = 1;
Opt_Measure_Failure_MAP_Generation = 0;
Opt_Measurement_Receive_Path = 1;
Opt_Measurement_Receive_Path_Duplication = 1;
Opt_Measurement_Duplication = 1;



                if Opt_Measurement_Receive_Path

                    Measurement_Receive_Path = zeros(Num_of_STAs+1, 5);
                    %Measurement_Receive_Path_All = zeros(Num_of_STAs+1, 5);
                    % DESCRIPTION
                    % Row: ID of STAs
                    % 1st Col: Source -> 1-hop ( or RED   -> GREEN )
                    % 2nd Col: 1-hop  -> 1-hop ( or GREEN -> GREEN ) * Positive effect of duplication
                    % 3rd Col: 1-hop  -> 2-hop ( or GREEN -> BLUE  )
                    % 4th Col: 2-hop  -> 2-hop ( or BLUE  -> BLUE  ) * Positive effect of duplication
                    % 5th Col: 2-hop  -> 1-hop ( or BLUE ->  GREEN ) * Positive effect of dulpication. reverse transmission.
                end
                
                if Opt_Measurement_Receive_Path_Duplication

                    Measurement_Receive_Path_Duplication = zeros(Num_of_STAs+1, 5);
                    %Measurement_Receive_Path_Duplication_1Hop = zeros(Num_of_STAs+1, 5);  % 전송이 1홉 노드에게 중복 수신인 경우 만을 측정함.
                    %Measurement_Receive_Path_Duplication_2Hop = zeros(Num_of_STAs+1, 5);  % 전송이 2홉 노드에게 중복 수신인 경우 만을 측정함.
                    %Measurement_Receive_Path_All = zeros(Num_of_STAs+1, 5);
                    % DESCRIPTION
                    % Row: ID of STAs
                    % 1st Col: Source -> 1-hop ( or RED   -> GREEN )
                    % 2nd Col: 1-hop  -> 1-hop ( or GREEN -> GREEN ) * Positive effect of duplication
                    % 3rd Col: 1-hop  -> 2-hop ( or GREEN -> BLUE  )
                    % 4th Col: 2-hop  -> 2-hop ( or BLUE  -> BLUE  ) * Positive effect of duplication
                    % 5th Col: 2-hop  -> 1-hop ( or BLUE ->  GREEN ) * Positive effect of dulpication. reverse transmission.
                end
                
                if Opt_Measurement_Duplication

                    Measurement_Duplication = zeros(Num_of_STAs+1, ceil(Traffic_Volumes/MPDU_Size)+100)-1;
                    Measurement_Duplication_1Hop = zeros(Num_of_STAs+1, ceil(Traffic_Volumes/MPDU_Size)+100)-1;
                    Measurement_Duplication_2Hop = zeros(Num_of_STAs+1, ceil(Traffic_Volumes/MPDU_Size)+100)-1;
                    % DESCRIPTION
                    % Row: ID of STAs
                    % Col: number of duplication per each Transmission Sequence
                    
                    Measurement_Duplication_ratio = zeros(Num_of_STAs+1, ceil(Traffic_Volumes/MPDU_Size)+100)-1;
                    Measurement_Duplication_ratio_1Hop = zeros(Num_of_STAs+1, ceil(Traffic_Volumes/MPDU_Size)+100)-1;
                    Measurement_Duplication_ratio_2Hop = zeros(Num_of_STAs+1, ceil(Traffic_Volumes/MPDU_Size)+100)-1;
                    % DESCRIPTION
                    % Row: ID of STAs
                    % Col: ratio of RX-STA which recieve duplicated frame to RX-STA which recieve non-duplicated frame per each Transmission Sequence
                    
                    Measurement_Duplication_Summary = zeros(Num_of_STAs+1, 5);
                    Measurement_Duplication_Summary_1Hop = zeros(Num_of_STAs+1, 5);
                    Measurement_Duplication_Summary_2Hop = zeros(Num_of_STAs+1, 5);
                    % DESCRIPTION
                    % Row: ID of STAs
                    % 1st Col: Sum of duplication event
                    % 2nd Col: Average of duplication event(number)
                    % 3rd Col: Average of duplication event(ratio)
                    % 4th Col: sum of pure-duplication event(number)
                    % 5th Col: ratio of pure-duplication event(number)
                    Measurement_Duplication_per_Frame_TX =  zeros(Num_of_STAs+1, ceil(Traffic_Volumes/MPDU_Size))-1;
                    Measurement_Duplication_per_Frame_RX =  zeros(Num_of_STAs+1, ceil(Traffic_Volumes/MPDU_Size))-1;
                    
                    Measurement_Duplication_per_Frame_TX_1Hop =  zeros(Num_of_STAs+1, ceil(Traffic_Volumes/MPDU_Size))-1;
                    Measurement_Duplication_per_Frame_RX_1Hop =  zeros(Num_of_STAs+1, ceil(Traffic_Volumes/MPDU_Size))-1;
                    
                    Measurement_Duplication_per_Frame_TX_2Hop =  zeros(Num_of_STAs+1, ceil(Traffic_Volumes/MPDU_Size))-1;
                    Measurement_Duplication_per_Frame_RX_2Hop =  zeros(Num_of_STAs+1, ceil(Traffic_Volumes/MPDU_Size))-1;
                    
                end 
               
                    
Opt_TX_Prob_Decision_Scheme_On = 0;   % 1: Schem 1, 2: scheme 2, ...
Opt_Self_Pruning_On = 0;  % If 1, Self-Pruning mode is enabled. pruned-STAs discard their frame regardless of thier own tx probability. 
Opt_Hybrid_On = 0;        % If 1, Hybrid mode is enabled. RCP-STAs discard their frame according to their tx probability.

Opt_Coloring_On = 1;

if (Opt_Coloring_On)
      
    Criterion_Coloring_Distance = 38.8625;   % criterion to decide transmission probability unit: meter, reference value: 88.9205m(53.9992) <-> -82dBm
    Criterion_Coloring_RSSI_dBm = Path_Loss(0,0,0,Criterion_Coloring_Distance, 10);
    Criterion_Coloring_RSSI_mW = 10^(Criterion_Coloring_RSSI_dBm/10);
    
%     Criterion_Coloring_Distance_Pruning = 88.9205;   % 50m, criterion to discard(prune) its frame for GREEN/BLUE STAs. unit: meter, reference value: 88.9205m <-> -82dBm
%     % Note) This Criterion should be devided independently for each GREEN and BLUE STAs. '17.01.09
%     Criterion_Coloring_Pruning_RSSI_dBm = Path_Loss(0,0,0,Criterion_Coloring_Distance_Pruning);
%     Criterion_Coloring_Pruning_RSSI_mW = 10^(Criterion_Coloring_Pruning_RSSI_dBm/10);
    
    Reception_Boundary_Coloring = 1;  % ex) if 1, when some STA receive same frame that is still in the queue two times, it is abandoned.
    % Note) Reception Boundary is not adjuseted and used in this simulation yet. But it should be used for major parameter later, ;'17.01.09 
    RCP_Tx_Probability_Coloring = 0.0;
    RSSI_Measure_Mode_Coloring = 1;  % 0: Last slot, 1: Average Value, 2: Highest Value, 3: Lowest Value, 4: Median Value
    RSSI_Measurement_Coloring = zeros(1, Num_of_STAs+1);

% Bellow lines are depends on ICTC2017 major Parmaters set for convenience(line:79)
    % TX-Probability Decision Mode
    Opt_RED_Variable_TX_Probability_On = 1;     % 1: In this mode, RED(source) also change its TX Probability like as others.
    Opt_Fixed_TX_Probability_On = Parameter_Set(1) > 0;            % 1: In this mode, dyanmic Tx probability mode dose not work in every nodes.
    if Opt_Fixed_TX_Probability_On              % 2: Insteadly, 
        Fixed_TX_Probability =  Parameter_Set(1);            % 3: the value 'Fixed_TX_Probability' is used. 
    end
    
    % TX-Probability Decision Mode, Choose one between them.
    % 이 것은 전송 확률을 결정할 때, 1홉과 2홉을 차별화하여 결정하는 지 제어하는 옵션인 것 같다. 내 생각에도 이름이 이상하다는 것 안다.
    Opt_Common_TX_Probability_On = 1;
    Opt_Diff_TX_Probability_On = 0;

    Opt_RED_Retransmission_On = Parameter_Set(4);              % In this mode, RED(source) calculate its 'Overhearing Time' based on other's color for retransmission.
    Opt_RED_Retransmission_Fixed_Overhearing_Mode_On = Parameter_Set(5);     
        
        if Opt_RED_Retransmission_On
           Table_TX_Probability = [-1 -1 -1 -1 -1];        
           % 1st-col: STA_ID, 2nd/3rd/4th-col: num of RED/GREEN/BLUE, ,5th-col: Tx_Probability   
           
           Overhearing_Time_Table = [ -1 -1 -1 -1];    
           % 1st-col: Frame Seq#,  2nd-col: Overhearing Time(In Slot)
           % 3rd-col: number of reTX  % 4th-col: Number of reception.
           
           Num_Retry = 4;           % Allowed number of retry.
           if( Opt_RED_Retransmission_Fixed_Overhearing_Mode_On > 0)
               Initial_ReTx_Overhearing_Time = Opt_RED_Retransmission_Fixed_Overhearing_Mode_On;
               Fixed_Overhearing_Time = Opt_RED_Retransmission_Fixed_Overhearing_Mode_On;
           else
               Initial_ReTx_Overhearing_Time = 0.1;
    %            Initial_ReTx_Overhearing_Time_in_Slot = ceil(Initial_ReTx_Overhearing_Time/U_Slot_Time);
           end
        end
        
    Opt_GREEN_Self_Pruning = CBF_Th;
    Opt_GREEN_Reception_Boundary_Coloring = CBF_Th;    % more than # of recpetion. at least 2. ex) value 2 means...
    Criterion_Coloring_Distance_Pruning_GREEN = 38.8625;   % 50m, criterion to discard(prune) its frame for GREEN/BLUE STAs. unit: meter, reference value: 88.9205m(53.9992) <-> -82dBm
        % Note) This Criterion should be devided independently for each GREEN and BLUE STAs. '17.01.09
        Criterion_Coloring_Pruning_RSSI_dBm_GREEN = Path_Loss(0,0,0,Criterion_Coloring_Distance_Pruning_GREEN, 10);
        Criterion_Coloring_Pruning_RSSI_mW_GREEN = 10^(Criterion_Coloring_Pruning_RSSI_dBm_GREEN/10);
        
    Opt_Additional_GREEN_Self_Pruning = 0; 
    Criterion_Coloring_Distance_Additional_Pruning_GREEN = 38.8625;   % ?m, criterion to discard(prune) its frame for GREEN/BLUE STAs. unit: meter, reference value: 88.9205m(53.9992) <-> -82dBm
        % Note) This Criterion should be devided independently for each GREEN and BLUE STAs. '17.01.09
        Criterion_Coloring_Additional_Pruning_RSSI_dBm_GREEN = Path_Loss(0,0,0,Criterion_Coloring_Distance_Additional_Pruning_GREEN, 10);
        Criterion_Coloring_Additional_Pruning_RSSI_mW_GREEN = 10^(Criterion_Coloring_Additional_Pruning_RSSI_dBm_GREEN/10);
    
    
    
    Opt_BLUE_Self_Pruning = CBF_Th;
    Opt_BLUE_Reception_Boundary_Coloring = CBF_Th; % more than # of recpetion. at least 2
    Criterion_Coloring_Distance_Pruning_BLUE = 38.8625;   % 50m, criterion to discard(prune) its frame for GREEN/BLUE STAs. unit: meter, reference value: 88.9205m(53.9992) <-> -82dBm
        % Note) This Criterion should be devided independently for each GREEN and BLUE STAs. '17.01.09
        Criterion_Coloring_Pruning_RSSI_dBm_BLUE = Path_Loss(0,0,0,Criterion_Coloring_Distance_Pruning_BLUE, 10);
        Criterion_Coloring_Pruning_RSSI_mW_BLUE = 10^(Criterion_Coloring_Pruning_RSSI_dBm_BLUE/10);

    Opt_Additional_BLUE_Self_Pruning = 0;
    
    Opt_Mode_All_BLUE_Pruning_On = 0;    % Every Blue STA do not try to access channel
    Opt_Mode_All_GREEN_Pruning_On = 0;   % Every Green STA do not try to access channel
    
    Opt_BLUE_TPC = 0;   % BLUE(2-hop) STA's Transmission Power Control
    
    % DESCRIPTION(X)
    % If any BLUE(2-hop) STAs discover any neighbor BLUE STAs which cannot sense GREEN STA(1-hop), 
    % the BLUE STAs(former) control their transmission power based on minimum RSSI among neighbor BLUE.
    % it can be lead to mitigate problem that disturb to reception of 1-hop STA.
    
    Opt_Coloring_Completion_Time_Measurement = 0;
    Coloring_Completion_Time = -1*ones(Num_of_Repitition,4);
    % Description: the matrix 'Coloring_Completion_Time'
    % Raw = number of repetition(random seed number)
    % 1st col : the time(in sec) when every STAs decide their color. 
    % 2nd col : the time(in slot) when every STAs decide their color.
    % 3rd col : the time(in sec) when every STAs know their neighbor's color.
    % 4th col : the time(in slot) when every STAs know their neighbor's color.
    Target_Color = zeros(Num_of_STAs+1, 1);
    Target_Color(2:(Num_of_STAs/2)+1) = 1;
    Target_Color((Num_of_STAs/2)+2 : Num_of_STAs+1 ) = 2;
    
    Opt_Measurement_Det_Pruning_Scheme_Batch_Type = 0;  % Determinstic Pruning Scheme for every STAs(Not Implemented now)
    Opt_Measurement_Prob_Pruning_Scheme_Batch_Type = 0; % Probabilistic Pruning Scheme for every STAs
    
    Opt_Measurement_Det_Pruning_Scheme_Individulal_Type = 0;  % Determinstic Pruning Scheme for Individual STAs
    Opt_Measurement_Prob_Pruning_Scheme_Individulal_Type = Parameter_Set(2); % Probabilistic Pruning Scheme for Individual STAs(PP2->FLD2)
    On_Pruning_Prob_Noise = 0; % Only for Prob_Pruning_Scheme_Individulal_Type
    
    
    Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_Linear = 0;    % Linear Abstraction
    Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_MLC = 0;       % Mu-Law Compress Abstraction, (Just Abstraction, No measurement in this scheme)
    
    Opt_Probabilistic_Counter_Based_Pruning_Scheme = Parameter_Set(3);                 % Proposed-pruning scheme for ICTC2017
    
    FLD2_ReTx_Mode = 0; % FLD2(or AFLD2) Retransmission mode on
    if FLD2_ReTx_Mode   % Configuration  prameters for FLD2(AFLD2) Retranmsmission Mode
        DC_Threshold = 1; % Duplication Counter Threshold
        OH_Time = 0.002;    % Overhearing Time(fixed) -> Initial OH_Time ('17.09.11)
        Mode_OH_Time = 1; % The duration of OH_Time is changed according to its value,(See 17-09-18)
                          % 1: Cumulative number of reception is used from when its first reception(T1) to T1+T2(discard or transmit time)+OH_Time  
                          % 2: Cumulative number of reception is used from when T2(discard or transmit time) to T2(discard or transmit time)+OH_Time
                          % 3: 
                          % 4: 
        
        Opt_OH_Time_Calc_On = 1; % If this option is enable, each node calclutate its overheagring time based on its virtual number of neighbor node.
                                 % virtual number of neighbor node = maximum of duplication counter.('17.09.11)
        Opt_Dynamic_DC_Th_On = 1; % Dynamic Duplication Counter Threshold Mode On
                                  % 1: based on the mode of the duplication counter 
                                  % 2: based on the maximum of the duplication counter
                                  
        Measurement_OH_Time_On = 1; % If this value is enable, the calculated overhearing times are recorded.
        
        Retry_Limit = 1;  % 1 means that each node try to retransmit just 1-time.(Now, Retry limit is not used)
        
    elseif ( FLD2_ReTx_Mode && (Opt_Probabilistic_Counter_Based_Pruning_Scheme || Opt_Measurement_Prob_Pruning_Scheme_Individulal_Type) )
        error( ' FLD2_ReTx_Mode is only available for FLD2 or AFLD2!');
    end
    
    if Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_MLC
        mu = 1000;  % common mu value
        Common_S = 0.5; % common S value. if it is negative, common s value is not used.
    end
    
    if  Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_Linear ...
            ||  Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_MLC
        On_Fixed_S_Value = -1;   %  If this value is -1, it means Fixed_S_Value is not used.
    end
    
    if  Opt_Probabilistic_Counter_Based_Pruning_Scheme == 1 %  Proposed-pruning scheme for ICTC2017
        mu = Para_mu;
        Fixed_S_Value_Small = Para_Fixed_S_Value_Small;
        Fixed_S_Value_Large = Para_Fixed_S_Value_Large;
        Initial_M_Value = Para_Initial_M_Value; % not required
        Adaptation_Duration = Para_Adaptation_Duration; % refer to #251 slide(결과정리 2016)
    end
    On_Pruning_Prob_S_Point_Noise = 0; % Only for S Point Noise
    
    Opt_Simple_Pruning_Probability_Adaptation_Scheme = 0;
    if Opt_Simple_Pruning_Probability_Adaptation_Scheme
        Table_Pruning_Probability = zeros(Num_of_STAs+1, Num_of_STAs+1) - 1;
    end
      
    if Opt_Measurement_Det_Pruning_Scheme_Batch_Type + ...
            Opt_Measurement_Prob_Pruning_Scheme_Batch_Type + ...
            Opt_Measurement_Det_Pruning_Scheme_Individulal_Type + ...
            Opt_Measurement_Prob_Pruning_Scheme_Individulal_Type + ...
            Opt_Simple_Pruning_Probability_Adaptation_Scheme + ...
            Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_Linear + ...
            Opt_Probabilistic_Counter_Based_Pruning_Scheme > 1
        error('Unexpected Pruning Mode!');
    end
    
    if Opt_Measurement_Det_Pruning_Scheme_Batch_Type || Opt_Measurement_Prob_Pruning_Scheme_Batch_Type   %  only for #51 topology
        Duplication_Decision_Table = [1:18; 0.389348103962505,0.625054688639347,0.772578176251913,0.871900826446281,0.933241569167240,0.971477960242005,0.987222222222222,0.997863247863248,1,1,1,1,1,1,1,1,1,1];
    end
    
%     if Opt_Measurement_Det_Pruning_Scheme_Individulal_Type ... 
%             || Opt_Measurement_Prob_Pruning_Scheme_Individulal_Type ...
%             || Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_Linear ...
%             || Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_MLC
%         
%         Pruning_Probability_Table_File_Name = strcat('Pruning_Table_', num2str(Num_of_STAs+1), '_STAs_', num2str(Seed_List(Rep
%         Duplication_Decision_Table = load('Pruning_Table.mat');  % Only for #51 Topology, 40-Relay-STAs.
% %         Duplication_Decision_Table = load('Pruning_Table2.mat');  % Only for #51 Topology, 40-Relay-STAs.
% %         Duplication_Decision_Table = load('Pruning_Table_51_100STA.mat');  % Only for #51 Topology, 100-Relay-STAs.
%         Duplication_Decision_Table = Duplication_Decision_Table.T;
%       
%         if (On_Pruning_Prob_Noise)
%             for idx_color1 = 1 : length(Duplication_Decision_Table(1,:))
%                     for idx_color2 = 2:length(Duplication_Decision_Table)
%                         if ( Duplication_Decision_Table(idx_color2, idx_color1) >= 0)
%                             Duplication_Decision_Table(idx_color2, idx_color1) = Duplication_Decision_Table(idx_color2, idx_color1) +0.5+0.5*randn; % mean + var*randn
%                         end
% 
%                         if ( Duplication_Decision_Table(idx_color2, idx_color1) >= 1)
%                             Duplication_Decision_Table(idx_color2, idx_color1) = 1;
%                         end
% 
%                         if ( Duplication_Decision_Table(idx_color2, idx_color1) < 0)
%                             Duplication_Decision_Table(idx_color2, idx_color1) = 0;
%                         end
% 
%                     end
%             end
%         end
%         
%         if ( On_Pruning_Prob_S_Point_Noise )  % Noise should be given before Each nodes make its PP Curve. Because Curves are depends on its S point. 
%             for idx_color1 = 2 : length(Duplication_Decision_Table(:,1))
%                     
%                         if ( Duplication_Decision_Table(idx_color1, 1) >= 0)
%                             Duplication_Decision_Table(idx_color1, 1) = Duplication_Decision_Table(idx_color1, 1) - 0.0;  % Constant Error Value is given
%                         end
% 
%                         if ( Duplication_Decision_Table(idx_color1, 1) >= 1)
%                             Duplication_Decision_Table(idx_color1, 1) = 1;
%                         end
% 
%                         if ( Duplication_Decision_Table(idx_color1, 1) < 0)
%                             Duplication_Decision_Table(idx_color1, 1) = 0;
%                         end
% 
%                     
%             end
%         end
%         
%         if (Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_Linear)
%             
%             SBM_Point = GET_SBM_Point(Duplication_Decision_Table);
%             
%             % SBM_Point: (1) B Point (2) B1 Point (3) M Point (4) S Value
%             for Idx_DDT = 2:length(Duplication_Decision_Table)
%                 Duplication_Decision_Table(Idx_DDT,1:SBM_Point(Idx_DDT,3)) ...
%                 = linspace(SBM_Point(Idx_DDT,4), 1, SBM_Point(Idx_DDT,3));            
%             end
%             
%             if (On_Fixed_S_Value ~= -1)  % If fixed S value is enable,
%                 Duplication_Decision_Table(1:Num_of_STAs+1) = On_Fixed_S_Value; 
%             end
%         elseif (Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_MLC)
%              
%              SBM_Point = GET_SBM_Point(Duplication_Decision_Table);
%              % SBM_Point: (1) B Point (2) B1 Point (3) M Point (4) S Value
%              
%              for Idx_DDT = 2:length(Duplication_Decision_Table)
%                 Duplication_Decision_Table(Idx_DDT,1:SBM_Point(Idx_DDT,3)) ...
%                 = SBM_Point(Idx_DDT,4) + ( log(1+mu.*abs( (0:(SBM_Point(Idx_DDT,3)-1)))/(SBM_Point(Idx_DDT,3)-1) )./log(1+mu) )/(1/(1-SBM_Point(Idx_DDT,4)))  ;
%                 % = ( log(1+mu.*abs( (0:(SBM_Point(Idx_DDT,3)-1)))/(SBM_Point(Idx_DDT,3)-1) )./log(1+mu) )/(1/(1-SBM_Point(Idx_DDT,4)))  ;
%                 % = SBM_Point(Idx_DDT,4) + ( log(1+mu.*abs( (1:SBM_Point(Idx_DDT,3)))/SBM_Point(Idx_DDT,3) )./log(1+mu) ) /(1/(1-SBM_Point(Idx_DDT,4)));
%              end
%              
%              if (On_Fixed_S_Value ~= -1)  % If fixed S value is enable,
%                 Duplication_Decision_Table(1:Num_of_STAs+1) = On_Fixed_S_Value; 
%              end
%             
%         end
%     end
end

% break;

if ( Opt_Self_Pruning_On || Opt_Hybrid_On )
    Criterion_Distance = 40;   % unit: meter
    Criterion_RSSI_dBm = Path_Loss(0,0,0,Criterion_Distance, 10);
    Criterion_RSSI_mW = 10^(Criterion_RSSI_dBm/10);

    Reception_Boundary = 1;  % ex) if 1, when some STA receive same frame that is still in the queue two times, it is abandoned.
    RCP_Tx_Probability = 0.0;
    RSSI_Measure_Mode = 1;  % 0: Last slot, 1: Average Value, 2: Highest Value, 3: Lowest Value, 4: Median Value
%     SIR_Measurement = zeros(1, Num_of_STAs+1);
    RSSI_Measurement = zeros(1, Num_of_STAs+1);
end
% Option List -END-  
MAX_SIR = 0;
Min_SIR = 0;
SIR_Collector = 0;

Opt_Error_Calc_Mode = 1; % 0: Calculated for each slot, 1: search nearnest value(recommended), 2: No Error Mode
if Opt_Error_Calc_Mode == 1
    Table_ESN0 = load ('Error_Table.mat');
    L_Table_ESN0 = length(Table_ESN0.Table_SlotER(1,:));
    Max_Table_ESN0 = max(Table_ESN0.Table_SlotER(1,:));
end


% break;
for Rep_Index = 1:Num_of_Repitition
close all;
% Result_Avg = -1*ones(1,26);
Sim_Time = Para_Sim_Time;     % unit: sec
% Sim_Time = 1.0;
% Sim_Time = 0.0050;
N_STA = Num_of_STAs; % except a Source STA


Simple_Flooding_Probabilty = Probability_List(ceil(Rep_Index/length(Seed_List)));
rng(Seed_List(Rep_Index-length(Seed_List)*(ceil(Rep_Index/length(Seed_List))-1)   ));
LOG_Simulation_Parameter(Rep_Index, :) = [Simple_Flooding_Probabilty, Seed_List(Rep_Index-length(Seed_List)*(ceil(Rep_Index/length(Seed_List))-1))]; 
% continue;
% Flooding Option
% (0) No Flooding : Every STAs always have Frames to send
% (1) Simple Flooding 
% (-) Simple Flooding with Probability ( Simple_Flooding_Probabilty = 1
% means normal Simple_Flooding(Option # 1)
Opt_Fixed_Traffic_Volume = 1;
Opt_Decision_Boundary_for_No_More_TX = 100000; % slots, 100,000 slot is 0.9 sec when a unit slot time is 9 usec
IDLE_Period = 0;


Opt_Flooding = 1;
% Simple_Flooding_Probabilty = Probability_List(1);

Opt_Simple_Flooding_Probabilty_Mode_Discard = 0; %1 % If This mode is enable, A frame has no allowed to transmit is discarded. And the next frame have to chance to transmit
Opt_Mode_Discard_Probability = 0.0; % 0.5 How many STAs will discard frame statiscally/probabilitically?, -1: The only STAs who are suffered from high density will discard frame selectively. 

% The both bellow options are not allowed to enable.
Opt_Src_Retransmission_Mode = 0;
Opt_All_Retransmission_Mode = 0;
Opt_Decision_Boundary_for_No_More_TX_RX_MODE = Opt_Decision_Boundary_for_No_More_TX*0.1;

if (Opt_Src_Retransmission_Mode)
   IDLE_Period_Src = 0;
   Actual_Failure_Frame_of_Src = 0
   Num_Src_Retry = 0;
   Normal_Failure_Frame = 0;
   Seq_Retry = 0;
   Actual_Ending_Time = -1;
elseif (Opt_All_Retransmission_Mode)
   IDLE_Period_All = zeros(1,N_STA+1); % N_STA+1 means the summation of a souce STA and another STAs(Num_STAs).
else
    Actual_Ending_Time = -1;
    N_1_Hop_Failure = -1;
    N_Other_Failure = -1;
    N_Estimation = -1;
    Num_Src_Retry = -1;
end

if Opt_RED_Retransmission_On
           Table_TX_Probability = [-1 -1 -1 -1 -1];        
           % 1st-col: STA_ID, 2nd/3rd/4th-col: num of RED/GREEN/BLUE, ,5th-col: Tx_Probability   
           
           Overhearing_Time_Table = [ -1 -1 -1 -1];    
           % 1st-col: Frame Seq#,  2nd-col: Overhearing Time(In Slot)
           % 3rd-col: number of reTX  % 4th-col: Number of reception.
           
           Num_Retry = 4;           % Allowed number of retry.
           if( Opt_RED_Retransmission_Fixed_Overhearing_Mode_On > 0)
               Initial_ReTx_Overhearing_Time = Opt_RED_Retransmission_Fixed_Overhearing_Mode_On;
               Fixed_Overhearing_Time = Opt_RED_Retransmission_Fixed_Overhearing_Mode_On;
           else
               Initial_ReTx_Overhearing_Time = 0.1;
    %            Initial_ReTx_Overhearing_Time_in_Slot = ceil(Initial_ReTx_Overhearing_Time/U_Slot_Time);
           end
end
        
Opt_Control_Simple_Flooding_Probabilty = 0;

if Opt_Control_Simple_Flooding_Probabilty
    RSSI_Criteria = -77; %dBm
    Low_Prob = 1.0;
    High_Prob = 0.1;
end

Opt_RTS_Flooding = 1;

Opt_Error_Model_Validation_Scenario = 0;  % for this scenario, Flooding Probability must be zero.
Opt_Enable_Group = 0;

Opt_Time_Interval_Measurement = 0;
Time_Interval_for_Measurement = 0.009; % 0.009 sec is corresponded to 1000 slot

% SIMULATION PARAMETERS : MAC

U_Slot_Time = 9*10^-6;  % unit: sec
Sim_Time_in_Slots = ceil(Sim_Time/U_Slot_Time)  % Simulation Time in Slots
% Sim_Time_in_Slots = 10000

if ( Opt_Time_Interval_Measurement )
    Time_Interval_for_Measurement_in_Slot = ceil( Time_Interval_for_Measurement/U_Slot_Time );
    Result_Time_Interval_Measurement = zeros(9, Time_Interval_for_Measurement_in_Slot);
    Result_Time_Interval_Measurement_Neighbor = zeros(9, Time_Interval_for_Measurement_in_Slot);
    Result_Time_Interval_Measurement_Others = zeros(9, Time_Interval_for_Measurement_in_Slot);
    
    Measurement_Criteria_of_Received_Traffic_Volume = [ 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 ];
    Index_Measurement_Criteria_of_Received_Traffic_Volume = [ 1 1 1 ]; 
    Measured_Time = zeros(3, length(Measurement_Criteria_of_Received_Traffic_Volume)); % 1-row : total, 2-row : Neighbors of Src, 3-row : others 

%     Measured_Time_Neighbor = zeros(1, length(Measurement_Criteria_of_Received_Traffic_Volume));
%     Measured_Time_Others = zeros(1, length(Measurement_Criteria_of_Received_Traffic_Volume));
    
    Measurement_Sequence = 1;
    Current_Cummulative_Slots = 0;
end
Sim_Result_Type_3 = zeros(2, N_STA+10);

CW = Contention_Window;     % Contention Window ( fixed )
DIFS = 3;

% SIMULATION PARAMETERS : PHY

Basic_Rate = 6.5*10^6; % unit: bps for Control Frame Transmission and
% Data_Rate = 19.5*10^6; % unit: bps for DATA Transmission
Noise_Floor = -100;  % unit: dBm
Noise_Floor_in_mW = 10^(Noise_Floor/10); % unit: mW

% SIMULATION PARAMETERS : Traffic Property

Traffic_Volume = Traffic_Volumes; % unit: Byte
L_MPDU = MPDU_Size; % unit: Byte
TX_Duration_MPDU = 8*L_MPDU/Data_Rate;
TX_Duration_MPDU_in_Slots = ceil( 8*L_MPDU/Data_Rate/U_Slot_Time ); 
N_MPDU = ceil(Traffic_Volume/L_MPDU); % How many are the piece of MPDU?? 
Queue_Length = N_MPDU;

% TOPOLOGY SETTING (later)


% MAC_STATE
IDLE = 0;
TX = 1;
RX = 2;
TX_RX = 3;

% START SIMULATION !

% 1) Initializaion bfore while
Target_Coverage = Target_Coverages;
if  Opt_Coloring_On && Opt_Fixed_TX_Probability_On
    STAs = Initialization_STA( N_STA, N_MPDU, Queue_Length, Target_Coverage,  CW, Sim_Time_in_Slots, Fixed_TX_Probability);
else
    STAs = Initialization_STA( N_STA, N_MPDU, Queue_Length, Target_Coverage,  CW, Sim_Time_in_Slots, Simple_Flooding_Probabilty);
end
N_STA = N_STA + 1;

% Each STAs has additional inforamtion sturcture for ReTX
% It should declare after function "Initialization_STA"
if FLD2_ReTx_Mode
    STAs.Time_Table_FLD2_ReTX = zeros(N_STA, N_MPDU)-1;
    % row : STAs_ID
    % col : Ended Time for Waitng in slot for each frame
    %       -1: initial value
    %       -n? : nodes try to retransmit n times(not implemented yet)
    %       -3 : nodes try to retransmit
    
    OH_Time = ceil(OH_Time/U_Slot_Time);
    if Mode_OH_Time == 2
        STAs.Overhearing_MAP_FLD2_ReTx = zeros(N_STA, N_MPDU)-1;
        % Even STAs.Overhearing_Count is already used for duplication counter, 
        % This array is used to measure duplication counter during specific time(overhearing duration of each frame for each node)
        % row : STAs_ID
        % col : Duplication counter for each frame
        %       -1: initial value
        % n(n >=0): duplication counter
    end
%     STAs.Time_Table_FLD2_ReTX = zeros(N_MPDU, 3);
    % row : Sequence Number of each frame
    % 1st-col: Transmitted Time in slot
    % 2nd-col: The amount time for waiting in slot(Timer_Interval)  
    % 3rd-col: Ended Time for Waitng in slot
    
    if Opt_OH_Time_Calc_On
        tau = 2/(CW+1);
        Ts =  8*L_MPDU/Data_Rate + DIFS*U_Slot_Time;  % TX_Duration_MPDU(No ACK), in seconds
        Tc = Ts;                                      % Collision Duration(No ACK), in seconds
    end
    
    if Measurement_OH_Time_On 
        
        STAs.Record_Overhearing_Time = zeros(N_STA, N_MPDU)-1;
        
    end
    
    if Opt_Dynamic_DC_Th_On
       STAs.Dynamic_DC_Th = zeros(N_STA, N_MPDU)-1; 
    end
    
end
% rng(1713);

if ( Opt_Error_Model_Validation_Scenario )
   
    STAs.pos_y(2:N_STA+1) = STAs.pos_y(1); % to make line topology 
    
    for i = 1:N_STA
   
       STAs.pos_x(i+1) = STAs.pos_x(i) + 20; 
       % i 
    end
   
end



% 2) Making RSSI MAP to reduce the amount of calculation
% 3) Making Possible Interference MAP to reduce the amount of calculation

RSSI_MAP = zeros(N_STA, N_STA);
Intf_MAP = zeros(N_STA, N_STA);

for i = 1 : N_STA
   for j = 1: N_STA 
   RSSI_MAP(i,j) = Path_Loss( STAs.pos_x(i), STAs.pos_y(i), STAs.pos_x(j), STAs.pos_y(j), STAs.TX_Power(i) );
   
   if (RSSI_MAP(i,j) >= STAs.CsTh (i) && RSSI_MAP(i,j) ~= Inf )
    
       Intf_MAP(i,j) = 1;
%    else 
%        Intf_MAP(i,j) = 0;  % This statement is not needed.
%        Inintialization are substitued to this.
%     
   end
   
   end
end

ID_Neighbor_STAs_of_Src = find(Intf_MAP(1,:) == 1);
ID_Others = find(Intf_MAP(1,:) == 0);
ID_Others(ID_Others == 1) = [];

if (Opt_Coloring_On && Opt_Coloring_Completion_Time_Measurement)
    
    Target_Color_MAP = zeros(N_STA, N_STA);
    
    for i = 1 : N_STA   % i is TX_ID
       for j = 1: N_STA % j is RX_ID   i.e., 'i' can sense 'j''s transmission.
         

           if (Intf_MAP(i,j) == 1 && Intf_MAP(j,1) == 1 ) && j ~= 1

               Target_Color_MAP(i,j) = 1;   % Green STAs
           
           elseif (Intf_MAP(i,j) == 1 && Intf_MAP(j,1) == 0 ) && j ~= 1
              
               Target_Color_MAP(i,j) = 2;   % BLUE STAs
               
           elseif (Intf_MAP(i,j) == 1 &&  j == 1 )
               
               Target_Color_MAP(i,j) = 3;   % RED STAs
           
           end

       end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% '16.12.28, bellow legacy RGB scheme is discarded.   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RGB = zeros(N_STA, 3); % 1-col: Red, 2-col: Green, 3-col: Blue
% if (Opt_TX_Prob_Decision_Scheme_On)
%     %STAs.SFProb(2:N_STA) = 1./sum( Intf_MAP(2:N_STA,2:N_STA) );  % STAs do not distinguish between 1-hop and 2-hop
%     
%     STAs.SFProb(ID_Neighbor_STAs_of_Src) = 1./( sum(Intf_MAP(ID_Neighbor_STAs_of_Src,ID_Neighbor_STAs_of_Src))+1 );  
%     STAs.SFProb(ID_Others) = 1./( sum(Intf_MAP(ID_Others,ID_Others))+1 ); % 0 is for suppressing TX of 2-hop completly(2-hop STA dont tx at all)   
%     
%     STAs.SFProb(STAs.SFProb == Inf) = 0;
% 
%     % RED
%     RGB(ID_Neighbor_STAs_of_Src, 1) = 1;
%     RGB(ID_Others, 1) = 0;
%     % GREEN
%     RGB(ID_Neighbor_STAs_of_Src, 2) = sum(Intf_MAP(ID_Neighbor_STAs_of_Src,ID_Neighbor_STAs_of_Src));
%     RGB(ID_Others, 2) = sum(Intf_MAP(ID_Others,ID_Neighbor_STAs_of_Src));
%     % BLUE
%     RGB(ID_Neighbor_STAs_of_Src, 3) = sum(Intf_MAP(ID_Neighbor_STAs_of_Src,ID_Others));
%     RGB(ID_Others, 3) = sum(Intf_MAP(ID_Others,ID_Others));
%     
% %     RGB_MAP = RSSI_MAP;
% %     TX_POWER = 10; % dBm
% %     CS_Th = -82; %dBm
% %     RGB_MAP = 1 - (RGB_MAP-TX_POWER)/(CS_Th-TX_POWER);
% %     RGB_MAP = Intf_MAP .* RGB_MAP;
%     
% %     % RED
% %     RGB(ID_Neighbor_STAs_of_Src, 1) = RGB_MAP(1,ID_Neighbor_STAs_of_Src);
% %     RGB(ID_Others, 1) = 0;
% %     % GREEN
% %     RGB(ID_Neighbor_STAs_of_Src, 2) = sum(RGB_MAP(ID_Neighbor_STAs_of_Src,ID_Neighbor_STAs_of_Src));
% %     RGB(ID_Others, 2) = sum(RGB_MAP(ID_Others,ID_Neighbor_STAs_of_Src));
% %     % BLUE
% %     RGB(ID_Neighbor_STAs_of_Src, 3) = sum(RGB_MAP(ID_Neighbor_STAs_of_Src,ID_Others));
% %     RGB(ID_Others, 3) = sum(RGB_MAP(ID_Others,ID_Others));
%     
% end

 
if ( Opt_Mode_Discard_Probability > 0)
    
    Rand_Array = rand(1, N_STA);
    STAs.Tag(Rand_Array > Opt_Mode_Discard_Probability) = 1;
    %STAs.Tag = [ 0 
    
    ID_Tag_0 = find(STAs.Tag == 0);
    ID_Tag_1 = find(STAs.Tag == 1);
    
elseif ( Opt_Mode_Discard_Probability == -1 )
    Discard_Probability_MAP = zeros(N_STA, N_STA);
    for i = 1 : N_STA
        for j = 1: N_STA 
   
            if (RSSI_MAP(i,j) >= -70 && RSSI_MAP(i,j) ~= Inf )
    
                Discard_Probability_MAP(i,j) = 1;
            end
   
        end
    end
    
    STAs.Tag = 1./(sum(Discard_Probability_MAP)+1);
    STAs.Tag(STAs.Tag ~=1) = STAs.Tag(STAs.Tag ~=1)*0.5

end

Result_Failure_Reason_for_MPDUs = zeros(4,N_MPDU); % Values -> 1st Row : Not used yet.
                                                   %           2nd Row : If this is counted, a Frame failed to receive as a result of Interference   
                                                   %           3rd Row : the number of Frame has not even tried to transfer from any adjacent STAs.
Result_Failure_Reason_for_MPDUs_Neighbors = zeros(3,N_MPDU);
Result_Failure_Reason_for_MPDUs_Others = zeros(3,N_MPDU);

Result_Failure_Reason_for_MPDUs(3,:) = Result_Failure_Reason_for_MPDUs(3,:) + (N_STA-1);
Result_Failure_Reason_for_MPDUs_Neighbors(3,:) = Result_Failure_Reason_for_MPDUs_Neighbors(3,:) + length(ID_Neighbor_STAs_of_Src);
Result_Failure_Reason_for_MPDUs_Others(3,:) = Result_Failure_Reason_for_MPDUs_Others(3,:) + length(ID_Others);


RSSI_MAP_in_mW = 10.^(RSSI_MAP./10);

figure;
plot(STAs.pos_x, STAs.pos_y, 'bo');
xlabel('X-axis');ylabel('Y-axis');
hold on;
    if ( Opt_Mode_Discard_Probability > 0)
        plot(STAs.pos_x(ID_Tag_1), STAs.pos_y(ID_Tag_1), 'r*');
    end
sum_Intf_MAP = sum(Intf_MAP);
% mean(sum_Intf_MAP);
STAs.N_neigbors = sum_Intf_MAP;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% '16.12.28, bellow legacy RGB scheme is discarded.   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1 : N_STA
%    
% 
%     
%     N_RGB = 35;
%     R = RGB(i,1)/N_RGB;
%     G = RGB(i,2)/N_RGB;
%     B = RGB(i,3)/N_RGB; 
% %     R = RGB(i,1)*3%/N_RGB;
% %     G = RGB(i,2)%/N_RGB;
% %     B = RGB(i,3)%/N_RGB; 
%     R(isnan(R)) = 0;
%     G(isnan(G)) = 0;
%     B(isnan(B)) = 0;
% %     R(R>1) = 1;
% %     G(G>1) = 1;
% %     B(B>1) = 1;
%     R(R == 1/N_RGB) = 0.5;
%     plot(STAs.pos_x(i), STAs.pos_y(i), 'Marker', 'o', 'MarkerFaceColor', [R G B],...
%        'MarkerSize', 11, 'MarkerEdgeColor', [R G B]);
%    
% %     N_RGB = 20;
% %     R = RGB(i,1)/N_RGB;
% %     G = RGB(i,2)/N_RGB;
% %     B = RGB(i,3)/N_RGB; 
% %     R(isnan(R)) = 0;
% %     G(isnan(G)) = 0;
% %     B(isnan(B)) = 0;
% %     R(R == 1/N_RGB) = 0.5;
% %     plot(STAs.pos_x(i), STAs.pos_y(i), 'Marker', 'o', 'MarkerFaceColor', [R G B],...
% %        'MarkerSize', 11, 'MarkerEdgeColor', [R G B]);
% 
% %     R = RGB(i,1)/sum(RGB(i,:));
% %     G = RGB(i,2)/sum(RGB(i,:));
% %     B = RGB(i,3)/sum(RGB(i,:)); 
% %     R(isnan(R)) = 0;
% %     G(isnan(G)) = 0;
% %     B(isnan(B)) = 0;
% %     plot(STAs.pos_x(i), STAs.pos_y(i), 'Marker', 'o', 'MarkerFaceColor', [R G B],...
% %         'MarkerSize', 11, 'MarkerEdgeColor',  [R G B]);
    text(STAs.pos_x(i)+3, STAs.pos_y(i)+3, num2str(sum_Intf_MAP(i)), 'Color', [1 0 0] );
    text(STAs.pos_x(i)-3, STAs.pos_y(i)-3, num2str(STAs.ID(i)), 'Color', [0 0 0] );
end

% Bellow statements are procedure to draw the coverage of a source STA based on CSTh and TX_Power.

% END of Drawing Coverage %
theta = 0:0.01:2*pi;
r = 1:0.01:300;
% r2 = 1:0.01:300;
for i=1:length(r)
    if Path_Loss(0,0,0,r(i), 10) <= STAs.CsTh(1)
        break;
    end
end
r = r(i);
r2 = r*2;
Circle_X = r*cos(theta) +STAs.pos_x(1);
Circle_Y = r*sin(theta) +STAs.pos_y(1);
Circle_X2 = r2*cos(theta) +STAs.pos_x(1);
Circle_Y2 = r2*sin(theta) +STAs.pos_y(1);
plot(Circle_X, Circle_Y,'k--', Circle_X2, Circle_Y2,'k--');
clear theta r r2 Circle_X Circle_Y Circle_X2 Circle_Y2;
% filename = strcat('Info_', num2str(N_STA), '_STAs_', num2str(Seed_List(Rep_Index)), '_', num2str(round(rand*10000)),'.mat');
% save(filename, 'STAs','-v7.3');
% % break;  % To only get Topology Graph
% continue;

if (Opt_Enable_Group)
% Grouping 
    Avg_Neighbor = [ 9.0245 11.1672 13.3208 15.4563 17.6129 19.7543 21.8927];
    Index_Avg = (N_STA - 16)/5;

    for i = 2 : N_STA
   
        if  Intf_MAP(1, i) == 1 %  near(0)
            STAs.Group(i,1) = 0;
        else                    %  far(1)
            STAs.Group(i,1) = 1;
        end
    
        if sum_Intf_MAP(i) >= Avg_Neighbor(Index_Avg)     % Many(0)
            STAs.Group(i,2) = 0; 
        else    % few(1)
            STAs.Group(i,2) = 1;
        end
    
        STAs.Group(i,3) = binaryVectorToDecimal([STAs.Group(i,1) STAs.Group(i,2)]);
    end

    Array_Num_Neighbors = unique(sum_Intf_MAP);
end
    
% Future Work : Plotiing Coverage of each STA

hold off;
% 
% figure;
% contour(STAs.pos_x, STAs.pos_y, RSSI_MAP);
% xlabel('X-axis');ylabel('Y-axis');

% figure;
% % data1 = randn(1,1e5); %// example data
% % data2 = randn(1,1e5) + .5*data1; %// example data correlated to above
% % values = hist3([data1(:) data2(:)],[51 51]);
% % imagesc(values)
% values = hist3([STAs.pos_x(:) STAs.pos_y(:)],[250 250]);
% imagesc(values)
% colorbar
% axis equal
% axis xy

% CS_MAP = zeros(N_STA, N_STA);  % Carrier Sesing MAP, this map is updated when TX/RX occur




%%%%%%%%%%%%%% Coloring: PRUNNING SCHEME CONFIGURATIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(Opt_Coloring_On) 
    if Opt_Measurement_Det_Pruning_Scheme_Individulal_Type ... 
            || Opt_Measurement_Prob_Pruning_Scheme_Individulal_Type ...
            || Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_Linear ...
            || Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_MLC
        
        Pruning_Probability_Table_File_Name = strcat('Pruning_Table_', num2str(Num_of_STAs+1), '_STAs_', num2str(Seed_List(Rep_Index)), '.mat');
        try
            Duplication_Decision_Table = load(Pruning_Probability_Table_File_Name);  % Pruning_Probability_Table is loaded based on its number of nodes and seed number
            Duplication_Decision_Table = Duplication_Decision_Table.Pruning_Probability_Table;
        catch exception
            disp(strcat(Pruning_Probability_Table_File_Name, ' is not available. go to the next simulation.'));
            continue;
        end
        if (On_Pruning_Prob_Noise)
            for idx_color1 = 1 : length(Duplication_Decision_Table(1,:))
                    for idx_color2 = 2:length(Duplication_Decision_Table)
                        if ( Duplication_Decision_Table(idx_color2, idx_color1) >= 0)
                            Duplication_Decision_Table(idx_color2, idx_color1) = Duplication_Decision_Table(idx_color2, idx_color1) +0.5+0.5*randn; % mean + var*randn
                        end

                        if ( Duplication_Decision_Table(idx_color2, idx_color1) >= 1)
                            Duplication_Decision_Table(idx_color2, idx_color1) = 1;
                        end

                        if ( Duplication_Decision_Table(idx_color2, idx_color1) < 0)
                            Duplication_Decision_Table(idx_color2, idx_color1) = 0;
                        end

                    end
            end
        end
        
        if ( On_Pruning_Prob_S_Point_Noise )  % Noise should be given before Each nodes make its PP Curve. Because Curves are depends on its S point. 
            for idx_color1 = 2 : length(Duplication_Decision_Table(:,1))
                    
                        if ( Duplication_Decision_Table(idx_color1, 1) >= 0)
                            Duplication_Decision_Table(idx_color1, 1) = Duplication_Decision_Table(idx_color1, 1) - 0.0;  % Constant Error Value is given
                        end

                        if ( Duplication_Decision_Table(idx_color1, 1) >= 1)
                            Duplication_Decision_Table(idx_color1, 1) = 1;
                        end

                        if ( Duplication_Decision_Table(idx_color1, 1) < 0)
                            Duplication_Decision_Table(idx_color1, 1) = 0;
                        end

                    
            end
        end
        
        if (Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_Linear)
            
            SBM_Point = GET_SBM_Point(Duplication_Decision_Table);
            
            % SBM_Point: (1) B Point (2) B1 Point (3) M Point (4) S Value
            for Idx_DDT = 2:length(Duplication_Decision_Table)
                Duplication_Decision_Table(Idx_DDT,1:SBM_Point(Idx_DDT,3)) ...
                = linspace(SBM_Point(Idx_DDT,4), 1, SBM_Point(Idx_DDT,3));            
            end
            
            if (On_Fixed_S_Value ~= -1)  % If fixed S value is enable,
                Duplication_Decision_Table(1:Num_of_STAs+1) = On_Fixed_S_Value; 
            end
        elseif (Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_MLC)
             
             SBM_Point = GET_SBM_Point(Duplication_Decision_Table);
             % SBM_Point: (1) B Point (2) B1 Point (3) M Point (4) S Value
             
             if Common_S >= 0
                SBM_Point(:,4) = Common_S;
             end
             
             for Idx_DDT = 2:length(Duplication_Decision_Table)
                Duplication_Decision_Table(Idx_DDT,1:SBM_Point(Idx_DDT,3)) ...
                = SBM_Point(Idx_DDT,4) + ( log(1+mu.*abs( (0:(SBM_Point(Idx_DDT,3)-1)))/(SBM_Point(Idx_DDT,3)-1) )./log(1+mu) )/(1/(1-SBM_Point(Idx_DDT,4)))  ;
                % = ( log(1+mu.*abs( (0:(SBM_Point(Idx_DDT,3)-1)))/(SBM_Point(Idx_DDT,3)-1) )./log(1+mu) )/(1/(1-SBM_Point(Idx_DDT,4)))  ;
                % = SBM_Point(Idx_DDT,4) + ( log(1+mu.*abs( (1:SBM_Point(Idx_DDT,3)))/SBM_Point(Idx_DDT,3) )./log(1+mu) ) /(1/(1-SBM_Point(Idx_DDT,4)));
             end
             
             if (On_Fixed_S_Value ~= -1)  % If fixed S value is enable,
                Duplication_Decision_Table(1:Num_of_STAs+1) = On_Fixed_S_Value; 
             end
            
        end
    end
end

%%%%%%%%%%%%% PRUNNING SCHEME CONFIGURATIONS -END- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%------------------------------------------------------------------
% START SIMULATION
%------------------------------------------------------------------

NOW = 1;          % Current Simulation Time
NOW_in_Slots = 1; % Current Simulation Time in slot

% STAs.bc = ones(1,N_STA);

while(NOW_in_Slots < (Sim_Time_in_Slots+1))
   

   %GOD =  Check_MAC_STATE( STAs.MAC_STATE(:, NOW_in_Slots) );   
   
    GOD.ID_IDLE = find(STAs.MAC_STATE(:, NOW_in_Slots) == 0);
%     STAs.MAC_STATE(GOD.ID_IDLE, NOW_in_Slots)= -1;
    GOD.ID_TX = find(mod(STAs.MAC_STATE(:, NOW_in_Slots),2) == 1);   % It's not required to re-initialization(or clear). this value is updated regardless of previous value.
    GOD.ID_RX = find(mod(STAs.MAC_STATE(:, NOW_in_Slots),2) == 0 & STAs.MAC_STATE(:, NOW_in_Slots) ~= 0);

    GOD.CS_MAP = zeros( N_STA ) ;
    
   %------------------------------------------------------------------
   % (0) IDLE STATE
   %------------------------------------------------------------------
   
   if (Opt_Flooding || Opt_RTS_Flooding )
        
       GOD.ID_IDLE = GOD.ID_IDLE(STAs.Queue(GOD.ID_IDLE, 3)> 0); 
        
   end
   
   if ( GOD.ID_IDLE )
       
       % Backoff - STAGE : This statement must be located on second line.  
       STAs.bc( GOD.ID_IDLE( STAs.DIFS(GOD.ID_IDLE) == 0 ) ) = STAs.bc( GOD.ID_IDLE( STAs.DIFS(GOD.ID_IDLE) == 0 ) ) - 1;
%        bc = STAs.bc( GOD.ID_IDLE( STAs.DIFS(GOD.ID_IDLE) == 0 ) )
       % DIFS - STAGE : : This statement must be located on last line.  
       STAs.DIFS( GOD.ID_IDLE( STAs.DIFS(GOD.ID_IDLE) > 0 ) ) = STAs.DIFS( GOD.ID_IDLE( STAs.DIFS(GOD.ID_IDLE) > 0 ) ) - 1; 
       
       % Change MAC_STATE to TX from IDLE : This statement must be located on fisrt line.
       
       % TX STAs are filtered according to their Simple Flooding Probability 
       TX_ID_Cadindate = GOD.ID_IDLE(STAs.bc(GOD.ID_IDLE) == 0);  
      
       if ( not(isempty( TX_ID_Cadindate )) )  % TX STAs are not filtered yet
           STAs.bc(TX_ID_Cadindate)... 
           = backoff(CW, length(STAs.bc(TX_ID_Cadindate)));
           STAs.DIFS(TX_ID_Cadindate) = DIFS;
%            STAs.DIFS(Idx_RX_STAs) = DIFS;

           TX_Decision_Random_Array = STAs.SFProb(TX_ID_Cadindate)-rand(length(TX_ID_Cadindate),1);
           
           if ( Opt_Simple_Flooding_Probabilty_Mode_Discard && ~isempty(TX_ID_Cadindate(TX_Decision_Random_Array < 0)))
                
               if (Opt_TX_Prob_Decision_Scheme_On == 2)
                    
                    TX_ID_Cadindate_Others = intersect(TX_ID_Cadindate, ID_Others);
                    ID_STA_Discarded_Frame = [];
                    if (~isempty( TX_ID_Cadindate_Others))
                        Position_TX_ID_Cadindate_Others = zeros(1, length( TX_ID_Cadindate_Others));
                        for idx_TX_ID_Cadindate = 1:length(TX_ID_Cadindate_Others)
                            Position_TX_ID_Cadindate_Others(idx_TX_ID_Cadindate) = find( TX_ID_Cadindate_Others(idx_TX_ID_Cadindate) == TX_ID_Cadindate); 
                        end
                        
                        TX_Decision_Random_Array_Others = TX_Decision_Random_Array(Position_TX_ID_Cadindate_Others);
                        
                        if (  ~isempty(TX_ID_Cadindate_Others(TX_Decision_Random_Array_Others < 0)) )
                            % TX_ID_Cadindate_Neighbors = intersect(TX_ID_Cadindate, ID_Neighbor_STAs_of_Src);
                            ID_STA_Discarded_Frame = TX_ID_Cadindate_Others(TX_Decision_Random_Array_Others < 0);
                        end
                    end

               else
                    ID_STA_Discarded_Frame = TX_ID_Cadindate(TX_Decision_Random_Array < 0);  
               end
                
               if ( Opt_Mode_Discard_Probability > 0)
                     ID_STA_Discarded_Frame =  ID_STA_Discarded_Frame(STAs.Tag(ID_STA_Discarded_Frame) == 1);
               
               elseif ( Opt_Mode_Discard_Probability == -1 )
                    Rand_Array = rand(1, length(ID_STA_Discarded_Frame));
                    ID_STA_Discarded_Frame = ID_STA_Discarded_Frame( STAs.Tag(ID_STA_Discarded_Frame) > Rand_Array);
                    
               end
               
            
                STAs.Count_Failure(ID_STA_Discarded_Frame, 3) = STAs.Count_Failure(ID_STA_Discarded_Frame, 3) + 1;
                for i = 1: length(ID_STA_Discarded_Frame)
                    if STAs.Queue_Frame_List(ID_STA_Discarded_Frame(i), (STAs.Queue(ID_STA_Discarded_Frame(i), 2) ) ) == -1
                        STAs.Queue_Frame_List(ID_STA_Discarded_Frame(i), (STAs.Queue(ID_STA_Discarded_Frame(i), 2) ) ) = -3; % -3 means abandoned frame.
                    else
                        error('Unexpected Queue_Frame_List in IDLE STATE...Simulation ends...'); 
                    end
                    
                    if ( STAs.Queue(ID_STA_Discarded_Frame(i), 3) == 1 )
                         STAs.Queue(ID_STA_Discarded_Frame(i), 2)...
                         = 0;
                    elseif ( STAs.Queue(ID_STA_Discarded_Frame(i), 3) > 1 )
                         STAs.Queue(ID_STA_Discarded_Frame(i), 2)...
                         = find(STAs.Queue_Frame_List(ID_STA_Discarded_Frame(i),:) == -1, 1, 'first' );    
                    end
                end
                STAs.Queue(ID_STA_Discarded_Frame, 3) = STAs.Queue(ID_STA_Discarded_Frame, 3) -1;   % Reduce Queue Length
            clear i;
           end
           
           TX_ID_Cadindate = TX_ID_Cadindate(TX_Decision_Random_Array >= 0); % TX STAs are filtered from here
       end
       
       STAs.MAC_STATE(TX_ID_Cadindate, (NOW_in_Slots+1):(NOW_in_Slots+TX_Duration_MPDU_in_Slots)) = 1;
%        STAs.MAC_STATE(GOD.ID_IDLE(STAs.bc(GOD.ID_IDLE) == 0), (NOW_in_Slots+1):(NOW_in_Slots+TX_Duration_MPDU_in_Slots)) = 1;
       
              
       if ( not(isempty( TX_ID_Cadindate )) )
           

        
           [Idx_TX_STAs, Idx_RX_STAs] = find(Intf_MAP(TX_ID_Cadindate,:) == 1);  % row are TX STAs(wrong and useless!). And col are RX_STAs
                
           STAs.MAC_STATE(Idx_RX_STAs, (NOW_in_Slots+1):(NOW_in_Slots+TX_Duration_MPDU_in_Slots))... 
           =  STAs.MAC_STATE(Idx_RX_STAs, (NOW_in_Slots+1):(NOW_in_Slots+TX_Duration_MPDU_in_Slots)) + 2;    % Update RX STATE
                     
%            STAs.bc(TX_ID_Cadindate)... 
%            = backoff(CW, length(STAs.bc(TX_ID_Cadindate)));
%            STAs.DIFS(TX_ID_Cadindate) = DIFS;
           STAs.DIFS(Idx_RX_STAs) = DIFS;
                      
       end
       
       % Bellow statements are added to get additional RX_STAs by the effect of sum of signal energy('16.10.04)
       if ( ~isempty( find( STAs.MAC_STATE( :, NOW_in_Slots ) == 0, 1) ) )    % these statements execute only when one and more IDLE STAs still exist.
           % step 1) Make the map-type information that include current TX and Potetial RX status for the current 1-slot
           CS_MAP_for_Next_Slot = zeros(N_STA, N_STA);
           CS_MAP_for_Next_Slot( STAs.MAC_STATE( :, NOW_in_Slots ) == 1, :) = 1; 
           
           % step 2) Calculate their sum of RSSI in dBm
           RSSI_MAP_in_mW_for_Next_Slot = nansum(CS_MAP_for_Next_Slot.*RSSI_MAP_in_mW);
           RSSI_MAP_in_dBm_for_Next_Slot = 10*log10(RSSI_MAP_in_mW_for_Next_Slot);
           
           % stpe 3) Only IDLE STAs their RSSI >= CSth change their state to RX_STATE and their STATEs are recorded on MAC_STATE.
           Idx_Additional_RX_STAs_Candidate = find( STAs.MAC_STATE( :, NOW_in_Slots ) == 0);  % row are TX STAs. And col are RX_STAs 
           Idx_Additional_RX_STAs = Idx_Additional_RX_STAs_Candidate(STAs.CsTh(Idx_Additional_RX_STAs_Candidate) <= RSSI_MAP_in_dBm_for_Next_Slot(Idx_Additional_RX_STAs_Candidate) );
           STAs.MAC_STATE(Idx_Additional_RX_STAs, (NOW_in_Slots)) = STAs.MAC_STATE(Idx_Additional_RX_STAs, (NOW_in_Slots)) + N_STA + 2; 
           
           STAs.DIFS(Idx_Additional_RX_STAs) = DIFS;
           
           clear CS_MAP_for_Next_Slot RSSI_MAP_in_mW_for_Next_Slot RSSI_MAP_in_dBm_for_Next_Slot Idx_Additional_RX_STAs_Candidate Idx_Additional_RX_STAs
       end
   end
   
%    break; % there is no error until here.
   
        %------------------------------------------------------------------
        % (1) TX STATE - The key component is to calculate sum of RSSI for
        % their receiver.
        %------------------------------------------------------------------   
%     GOD.ID_TX = find(mod(STAs.MAC_STATE(:, NOW_in_Slots),2) == 1);
    

    % filterd again for Additional RX STAs.('16.10.04)
    % Assume) Additional RX STAs never decode their frame sccessfully because of its severe interference or low signal power.
    GOD.ID_TX(STAs.MAC_STATE(GOD.ID_TX, NOW_in_Slots) > N_STA) = [];    
    GOD.ID_RX(STAs.MAC_STATE(GOD.ID_RX, NOW_in_Slots) > N_STA) = [];
    
    if ( GOD.ID_TX )
        
        GOD.CS_MAP = zeros(N_STA, N_STA);
        % 1) Check RX STAs for each TX STA
        
        Idx_RX_STAs = find(Intf_MAP(GOD.ID_TX,:) == 1);  % row are TX STAs. And col are RX_STAs 
        
        CS_MAP_Temp = zeros(length(GOD.ID_TX), N_STA );
        CS_MAP_Temp(Idx_RX_STAs) = 1;
        GOD.CS_MAP(GOD.ID_TX,:) = CS_MAP_Temp;
        A = GOD.CS_MAP;
        
        New_TX_STA_ID = GOD.ID_TX(STAs.TX_Frame_Inform(GOD.ID_TX,2) <= 0);
        STAs.TX_Frame_Inform(New_TX_STA_ID, 1) = 1; % Only DATA Frame is considered temporarily. 
        STAs.TX_Frame_Inform(New_TX_STA_ID, 3) = STAs.Queue(New_TX_STA_ID, 2);
        STAs.TX_Frame_Inform(New_TX_STA_ID, 2) = TX_Duration_MPDU_in_Slots;
        STAs.Queue(New_TX_STA_ID,3) = STAs.Queue(New_TX_STA_ID,3) - 1; % decrease queue length 
        STAs.Queue(New_TX_STA_ID,1) = STAs.Queue(New_TX_STA_ID,1) + 1; % count the number of TX
%         STAs.Queue(GOD.ID_TX(STAs.TX_Frame_Inform(GOD.ID_TX,2) <= 0), 3) = STAs.Queue(GOD.ID_TX(STAs.TX_Frame_Inform(GOD.ID_TX,2) <= 0), 3) - 1; % reduce queue length
%         STAs.Queue(GOD.ID_TX(STAs.TX_Frame_Inform(GOD.ID_TX,2) <= 0), 2) = STAs.Queue(GOD.ID_TX(STAs.TX_Frame_Inform(GOD.ID_TX,2) <= 0), 2) + 1; % increse sequence ID for TX
        
        if (Opt_Coloring_On)  % color information is included in TX_Frame    
            STAs.TX_Frame_Inform(New_TX_STA_ID, 4) = STAs.Color(New_TX_STA_ID);
            STAs.TX_Frame_Inform(New_TX_STA_ID, 5:7) = STAs.RGB(New_TX_STA_ID, :);
        end

        if ( Opt_Self_Pruning_On || Opt_Hybrid_On )
            % At current time, the number of overheared frame are stored in 'STAs.Overhearing_Count_Frame_at_TX_Time(...)'  
%             STAs.Overhearing_Count_Frame_at_TX_Time(New_TX_STA_ID, STAs.TX_Frame_Inform(New_TX_STA_ID, 3))...
%             = STAs.Overhearing_Count_Frame(New_TX_STA_ID, STAs.TX_Frame_Inform(New_TX_STA_ID, 3));     
        end

        for i = 1: length(New_TX_STA_ID)
                %if( STAs.Queue(Temp_Index(i), 3) ~= 0)
                %if (find(STAs.Queue_Frame_List(STAs.Focused_Frame_Inform(Unfocused_RX_ID(i), 1),:) == -1, 1, 'first' ))
                STAs.Queue_Frame_List(New_TX_STA_ID(i), (STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3) ) ) = -2;
                
                Result_Failure_Reason_for_MPDUs(4, STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3))...
                = Result_Failure_Reason_for_MPDUs(4, STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) + 1; % 이 프레임에대해서 인접 STA에서 적어도 1번 이상의 전송 시도가 있었음.
            
                if ( STAs.Queue(New_TX_STA_ID(i), 3) > 0 )
                    STAs.Queue(New_TX_STA_ID(i), 2)...
                        = find(STAs.Queue_Frame_List(New_TX_STA_ID(i),:) == -1, 1, 'first' ); 
                end
                %end
                %end
                
%             debug_frame = [ 433   469   693   694   732   934   977];
%             for j = 1:length(debug_frame)
%                 if debug_frame(j) == STAs.Queue(New_TX_STA_ID(1), 2)
%                    debug_frame(j) 
%                 end
%             end

            if Opt_Measurement_Duplication
                 
                % 1) Get Sequence ID from TX-Frame
                % STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)
                
                % 2) Get RX-node from CS MAP for i-th TX-Frame
                Idx_RX_STAs_dupl = find(Intf_MAP(New_TX_STA_ID(i),:) == 1);
                Idx_RX_STAs_dupl_1Hop = find(Intf_MAP(New_TX_STA_ID(i),:) == 1 & Intf_MAP(1,:) == 1);
                Idx_RX_STAs_dupl_2Hop = find(Intf_MAP(New_TX_STA_ID(i),:) == 1 & Intf_MAP(1,:) == 0);
                
                % 3) record... 
                Num_of_Dupl = length(find(STAs.Queue_Frame_List(Idx_RX_STAs_dupl, STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) < 0));
                Num_of_Dupl_1Hop = length(find(STAs.Queue_Frame_List(Idx_RX_STAs_dupl_1Hop, STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) < 0));
                Num_of_Dupl_2Hop = length(find(STAs.Queue_Frame_List(Idx_RX_STAs_dupl_2Hop, STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) < 0));
                
                Measurement_Duplication(New_TX_STA_ID(i), find(Measurement_Duplication(New_TX_STA_ID(i), :) == -1, 1)) ... 
                = Num_of_Dupl;  % Arrange based on Transmission Sequence
                Measurement_Duplication_1Hop(New_TX_STA_ID(i), find(Measurement_Duplication_1Hop(New_TX_STA_ID(i), :) == -1, 1)) ... 
                = Num_of_Dupl_1Hop;  % Arrange based on Transmission Sequence(1Hop)
                Measurement_Duplication_2Hop(New_TX_STA_ID(i), find(Measurement_Duplication_2Hop(New_TX_STA_ID(i), :) == -1, 1)) ... 
                = Num_of_Dupl_2Hop;  % Arrange based on Transmission Sequence(2Hop)
            
                Measurement_Duplication_ratio(New_TX_STA_ID(i), find(Measurement_Duplication_ratio(New_TX_STA_ID(i), :) == -1, 1)) ... 
                = Num_of_Dupl/length(Idx_RX_STAs_dupl);   % Arrange based on Transmission Sequence
                Measurement_Duplication_ratio_1Hop(New_TX_STA_ID(i), find(Measurement_Duplication_ratio_1Hop(New_TX_STA_ID(i), :) == -1, 1)) ... 
                = Num_of_Dupl_1Hop/length(Idx_RX_STAs_dupl_1Hop);   % Arrange based on Transmission Sequence(1Hop)
                Measurement_Duplication_ratio_2Hop(New_TX_STA_ID(i), find(Measurement_Duplication_ratio_2Hop(New_TX_STA_ID(i), :) == -1, 1)) ... 
                = Num_of_Dupl_2Hop/length(Idx_RX_STAs_dupl_2Hop);   % Arrange based on Transmission Sequence(2Hop)
            
                Measurement_Duplication_per_Frame_TX(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) ...   
                = Num_of_Dupl/length(Idx_RX_STAs_dupl);   % Arrange base on Frame Sequence ID(ratio value)
                Measurement_Duplication_per_Frame_TX_1Hop(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) ...   
                = Num_of_Dupl_1Hop/length(Idx_RX_STAs_dupl_1Hop);   % Arrange base on Frame Sequence ID(ratio value)
                Measurement_Duplication_per_Frame_TX_2Hop(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) ...   
                = Num_of_Dupl_2Hop/length(Idx_RX_STAs_dupl_2Hop);   % Arrange base on Frame Sequence ID(ratio value)
               
                Measurement_Duplication_per_Frame_RX(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) ...
                = STAs.Overhearing_Count_Frame(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3));
                Measurement_Duplication_per_Frame_RX_1Hop(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) ...
                = STAs.Overhearing_Count_Frame(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3));
                Measurement_Duplication_per_Frame_RX_2Hop(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) ...
                = STAs.Overhearing_Count_Frame(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3));
            end
        end
            clear i;

            
            % Processing for focusing frame for RX
        if ( sum(GOD.ID_RX) > 0 && sum(STAs.Focused_Frame_Inform( GOD.ID_RX, 2) <= 0) )  % fouced_Frames is not decided yet for each RX STAs.

            Unfocused_RX_ID = GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) <= 0);
%             STAs.Focused_Frame_Inform(Unfocused_RX_ID, 2) = TX_Duration_MPDU_in_Slots;   % 1st col: TX_ID, 2nd col: Frame Length, error: dimension mismatch
%             [Idx_TX_STAs col] = find(GOD.CS_MAP(:, GOD.ID_RX) == 1);

            %A = GOD.CS_MAP.*RSSI_MAP_in_mW;
            A = GOD.CS_MAP.*RSSI_MAP;
            A(A == 0) = NaN;
            
            for i = 1: length(Unfocused_RX_ID)       
                STAs.Focused_Frame_Inform(Unfocused_RX_ID(i), 1)...
                = find(A(:,Unfocused_RX_ID(i)) == max(A(:,Unfocused_RX_ID(i))));  % Check again for validation
%                 STAs.Focused_Frame_Inform(Unfocused_RX_ID(i), 3) = NOW_in_Slots + TX_Duration_MPDU_in_Slots -1; 
%                 STAs.Focused_Frame_Inform(Unfocused_RX_ID(i), 4) = RSSI_MAP_in_mW(Idx_TX_STAs(i), Unfocused_RX_ID(i));
                STAs.Focused_Frame_Inform(Unfocused_RX_ID(i), 4)...
                = RSSI_MAP_in_mW(STAs.Focused_Frame_Inform(Unfocused_RX_ID(i), 1), Unfocused_RX_ID(i));
                
%                 Result_Failure_Reason_for_MPDUs(4, STAs.TX_Frame_Inform( STAs.Focused_Frame_Inform(Unfocused_RX_ID(i), 1),3))...
%                 = Result_Failure_Reason_for_MPDUs(4, STAs.TX_Frame_Inform( STAs.Focused_Frame_Inform(Unfocused_RX_ID(i), 1),3)) + 1; % 이 프레임에대해서 인접 STA에서 적어도 1번 이상의 전송 시도가 있었음.
            end
            
            STAs.Focused_Frame_Inform(Unfocused_RX_ID, 2) = STAs.TX_Frame_Inform( STAs.Focused_Frame_Inform(Unfocused_RX_ID, 1),2);
            STAs.Focused_Frame_Inform(Unfocused_RX_ID, 6) = STAs.TX_Frame_Inform( STAs.Focused_Frame_Inform(Unfocused_RX_ID, 1),3);
            STAs.Focused_Frame_Inform(Unfocused_RX_ID( STAs.Focused_Frame_Inform(Unfocused_RX_ID, 2) < TX_Duration_MPDU_in_Slots ), 5) = 1; % Check if partial frame or full frame.
            
            STAs.Focused_Frame_Inform(Unfocused_RX_ID, 7) = STAs.Focused_Frame_Inform(Unfocused_RX_ID, 2);
            
            if (Opt_Coloring_On)
                % Write color information in RX-Frame
                STAs.Focused_Frame_Inform(Unfocused_RX_ID, 8) = STAs.TX_Frame_Inform( STAs.Focused_Frame_Inform(Unfocused_RX_ID, 1), 4);        % Own Color
                STAs.Focused_Frame_Inform(Unfocused_RX_ID, 9:11) = STAs.TX_Frame_Inform( STAs.Focused_Frame_Inform(Unfocused_RX_ID, 1), 5:7);   % Neighbors Color
                for i = 1 : length(New_TX_STA_ID)
                    if  Opt_RED_Retransmission_On && STAs.Color(New_TX_STA_ID(i)) == 0   % When RED_ReTX is enable and RED STA
                        if STAs.RGB(New_TX_STA_ID(i),2) >= 1  % ?

                            if (Opt_RED_Retransmission_Fixed_Overhearing_Mode_On > 0)
                                Overhearing_Time = NOW_in_Slots + TX_Duration_MPDU_in_Slots + ceil(Fixed_Overhearing_Time/U_Slot_Time);
                            else
                                tau = 2*Table_TX_Probability(2:length(Table_TX_Probability(:,1)),5)/(Contention_Window+1);
                                P_tr = 1-prod(tau);
                                P_s = sum( (tau./(1-tau)).*prod(1-tau) )/P_tr;
                                % step 1) Calculating Overhearing _Time
                                Overhearing_Time = (length(tau)-1)*( (1-P_tr)*U_Slot_Time + P_tr*P_s*TX_Duration_MPDU + P_tr*(1-P_s)*TX_Duration_MPDU );  % in sec
                                Overhearing_Time = NOW_in_Slots + TX_Duration_MPDU_in_Slots +ceil(Overhearing_Time/U_Slot_Time); % in slot, and re-calulated it based on current slot time
                            end
                            % step 2) Update End Time(in slot) on table
                        else
                            Overhearing_Time = NOW_in_Slots + TX_Duration_MPDU_in_Slots + ceil(Initial_ReTx_Overhearing_Time/U_Slot_Time);
                        end
                        
                        % If there exists old information of TX frame in TABLE,
                        Check_Existing_Frame = find(Overhearing_Time_Table(:,1) == STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)); 
                        if ~isempty(Check_Existing_Frame)
                            % Overhearing_Time_Table(Check_Existing_Frame, :) = [STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)  Overhearing_Time Overhearing_Time_Table(Check_Existing_Frame, 3)+1]; 
                            Overhearing_Time_Table(Check_Existing_Frame, 2:3) = [Overhearing_Time Overhearing_Time_Table(Check_Existing_Frame, 3)+1];
                        else
                            Overhearing_Time_Table = [Overhearing_Time_Table ; STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)  Overhearing_Time 0 0];    
                        end
                        
                    end
                    
                    % In TX_STATE, Fill up Time table for Retransmission.
                    if FLD2_ReTx_Mode
                        
                       if STAs.Time_Table_FLD2_ReTX(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) > 0 % 이미 전송 시도 되었던 프레임을 체크함.
                            error('Unexpected Transmitted Frame!');
                       elseif  STAs.Time_Table_FLD2_ReTX(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) == -3 % 이미 재전송 시도 되었던 프레임을 체크함.
                           % Do Nothing, this line is related to retranmission limit
                       else
                           % Update Timer for sent frame according to different overhearing adjusting option.
                           if Opt_OH_Time_Calc_On == 1
                                % step 1) get the maximum value of duplication counter for the current node.
                                max_dc =  max(STAs.Overhearing_Count_Frame(New_TX_STA_ID(i),:));
                                % step 2) calulate overhearing time based on the maximum duplication counter(virtual neighbor node)
                                if max_dc > 0
                                    P_tr = 1-(1-tau)^max_dc; 
                                    P_s  = (  max_dc*tau*( (1-tau)^(max_dc-1) )  ) / P_tr;
                                    Calculated_OH_Time = max_dc * ( (1-P_tr)*U_Slot_Time + P_tr*P_s*Ts + P_tr*(1-P_s)*Tc) ; % expressed in seconds.
                                    
                                    % transform to slot...
                                    STAs.Time_Table_FLD2_ReTX(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) ...
                                        = NOW_in_Slots + TX_Duration_MPDU_in_Slots + ceil(Calculated_OH_Time/U_Slot_Time);
                                    if Measurement_OH_Time_On
                                        STAs.Record_Overhearing_Time(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) = ceil(Calculated_OH_Time/U_Slot_Time); % In slot
                                    end
                                    
                                else  % if max dc is 0(i.e., any transmission is not occured yet from neighbors), fixed overhearing time is used insteadly.
                                    STAs.Time_Table_FLD2_ReTX(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) ...
                                        = NOW_in_Slots + TX_Duration_MPDU_in_Slots + OH_Time;
                                    if Measurement_OH_Time_On
                                        STAs.Record_Overhearing_Time(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) = OH_Time; % In slot
                                    end
                                end
                           else  % fixed overhearing time is used.
                                STAs.Time_Table_FLD2_ReTX(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) ... 
                                    = NOW_in_Slots + TX_Duration_MPDU_in_Slots + OH_Time;
                                if Measurement_OH_Time_On
                                    STAs.Record_Overhearing_Time(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) = OH_Time; % In slot
                                end
                           end
                           
                           if Mode_OH_Time == 2
                               if STAs.Overhearing_MAP_FLD2_ReTx(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) == -1
                                   STAs.Overhearing_MAP_FLD2_ReTx(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) = 0; 
                               else
                                   error('Unexpected ~~~!');
                               end
                           end
                           
                           if Opt_Dynamic_DC_Th_On == 1 % Calculate dynamic threshold based on Mode value of duplication counter
                               if max_dc > 0 && STAs.Overhearing_Count_Frame(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) ~= 0
                                   Temp_OCF = STAs.Overhearing_Count_Frame(New_TX_STA_ID(i), :);
                                   Temp_OCF(Temp_OCF == 0) = [];
                                   
                                   if Opt_Probabilistic_Counter_Based_Pruning_Scheme % for ICTC2017(AFLD2)
                                       Overhearing_Count = STAs.Overhearing_Count_Frame(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3));
                                       if NOW_in_Slots*U_Slot_Time < Adaptation_Duration % Overhearing_Count <= Initial_M_Value
                                            % Pruning_Probability = Fixed_S_Value + ( log(1+mu* Overhearing_Count/Initial_M_Value)/log(1+mu))/(1/(1-Fixed_S_Value));
                                            Pruning_Probability = 0.0;
                                       else 
                                            if STAs.Color(New_TX_STA_ID(i)) == 1
                                                Pruning_Probability = Fixed_S_Value_Small + ( log(1+mu* ( (Overhearing_Count-1)/(sum(STAs.RGB(New_TX_STA_ID(i),:))-1)) )/log(1+mu))/(1/(1-Fixed_S_Value_Small));
                                            elseif STAs.Color(New_TX_STA_ID(i)) == 2 && STAs.RGB(New_TX_STA_ID(i), 2) == 0
                                                Pruning_Probability = Fixed_S_Value_Large + ( log(1+mu* ( (Overhearing_Count-1)/(sum(STAs.RGB(New_TX_STA_ID(i),:))-1)) )/log(1+mu))/(1/(1-Fixed_S_Value_Large));
                                            end       
                                       end
                                       temp_dr = Pruning_Probability;
                                       
                                   elseif Opt_Measurement_Prob_Pruning_Scheme_Individulal_Type % FLD2
                                       
                                       if isnan(Duplication_Decision_Table( New_TX_STA_ID(i), STAs.Overhearing_Count_Frame(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)))) ...
                                           ||Duplication_Decision_Table( New_TX_STA_ID(i), STAs.Overhearing_Count_Frame(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) )  == -1

                                           temp_dr = 0;
                                           % temp_dr = 1;

                                       else
                                           temp_dr = Duplication_Decision_Table( New_TX_STA_ID(i), STAs.Overhearing_Count_Frame(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3)) );
                                       end
                                   else
                                       error('unexpected flooding scheme!');
                                   end
                                   
                                   STAs.Dynamic_DC_Th(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3) ) ...
                                       = mode(Temp_OCF) ...
                                       - ceil( max_dc * temp_dr );

                                   % clear Temp_OCF;
                               else
                                    STAs.Dynamic_DC_Th(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3) ) = DC_Threshold;
                               end
                           elseif Opt_Dynamic_DC_Th_On  == 2 % Calculate dynamic threshold based on MAX value of duplication counter(Not implemented yet)
                               STAs.Dynamic_DC_Th(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3) ) ...
                                   = max(STAs.Overhearing_Count_Frame(New_TX_STA_ID(i),:));
                           end
                           
                       end
                            
                    end
                end
            end
            %STAs.Queue(STAs.Focused_Frame_Inform(Unfocused_RX_ID, 1), 3) = STAs.Queue(STAs.Focused_Frame_Inform(Unfocused_RX_ID, 1), 3) - 1; % reduce queue length
            %STAs.Queue(GOD.ID_TX, 2) = STAs.Queue(GOD.ID_TX, 2) + 1; % increse sequence ID for TX
            
%             Temp_Index = unique(STAs.Focused_Frame_Inform(Unfocused_RX_ID, 1));
%             Temp_Index
            
        end
        
        STAs.RSSI_Record(:, NOW_in_Slots) = nansum(GOD.CS_MAP.*RSSI_MAP_in_mW);
        
        STAs.TX_Frame_Inform(GOD.ID_TX(STAs.TX_Frame_Inform(GOD.ID_TX,2) > 0), 2)... 
        = STAs.TX_Frame_Inform(GOD.ID_TX(STAs.TX_Frame_Inform(GOD.ID_TX,2) > 0), 2) - 1;
        
       
    end
   
   
%    if ( GOD.ID_TXnRX )
%         
%    
%    
%    end
   
  
   if (Opt_Flooding && sum(find(GOD.ID_RX == 1)))
        
       if( Opt_Src_Retransmission_Mode )
           % Do nothing, Source STA is not excepted as RX STAs to keep STAs.Overhearing_MAP
       elseif ( Opt_Coloring_On && ( Opt_RED_Variable_TX_Probability_On || Opt_RED_Retransmission_On ))
           % Do nothing, instead of excepting source STA as RX_STA.
       else
           GOD.ID_RX = GOD.ID_RX(2:length(GOD.ID_RX));  % except source STA
       end
       
       
        
   end
    
    % Exculde RX_STAs that have partial frame in current slot, 
    % so sometimes, there is no any RX_STAs even there are any RX STAs on
    % MAC_STATE
    if( sum(STAs.Focused_Frame_Inform(GOD.ID_RX, 5))  > 0 )  % Filtering of Partial RX Frame start from here.
        ID_Partial_RX = GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 5) == 1);
        
        STAs.Focused_Frame_Inform(ID_Partial_RX(STAs.Focused_Frame_Inform(ID_Partial_RX, 2) > 0), 2)...
        = STAs.Focused_Frame_Inform(ID_Partial_RX(STAs.Focused_Frame_Inform(ID_Partial_RX, 2) > 0), 2) - 1;
        
        %STAs.Result_Partial_Frame(ID_Partial_RX, 2) = STAs.Result_Partial_Frame(ID_Partial_RX, 2) + 1 % count for total remained length 
    
        if STAs.Focused_Frame_Inform(ID_Partial_RX(STAs.Focused_Frame_Inform(ID_Partial_RX, 2) == 0), 1) % When STAs finished to receive their Partial frames, do bellows.
            Partial_RX_ID = ID_Partial_RX(STAs.Focused_Frame_Inform(ID_Partial_RX, 2) == 0);
            
            
            
            %STAs.Count_Failure(ID_Partial_RX(STAs.Focused_Frame_Inform(ID_Partial_RX, 2) == 0), 1) = STAs.Count_Failure(ID_Partial_RX(STAs.Focused_Frame_Inform(ID_Partial_RX, 2) == 0), 1) + 1; % count one for the number of  RX frame 
            %STAs.Count_Failure(ID_Partial_RX(STAs.Focused_Frame_Inform(ID_Partial_RX, 2) == 0), 2) = STAs.Count_Failure(ID_Partial_RX(STAs.Focused_Frame_Inform(ID_Partial_RX, 2) == 0), 2) + 1; % count one for the number of  failure RX frame 
            
            % Don't remove! bellow 2 line must be saved later. The chance
            % to utilize partial frame is still remained.
%             A = ID_Partial_RX( STAs.Focused_Frame_Inform(ID_Partial_RX, 2) == 0 & STAs.Focused_Frame_Inform(ID_Partial_RX, 3) > 0 ) ;
%             STAs.Count_Failure(A, 2)  = STAs.Count_Failure(A, 2) + 1; % count for the number of error frame
%          STAs.Queue(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 5) == 0), 3) = STAs.Queue(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 5) == 0), 3) - 1;
         GOD.ID_RX = GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 5) == 0);
         STAs.Result_Partial_Frame(Partial_RX_ID, 1) = STAs.Result_Partial_Frame(Partial_RX_ID, 1) + 1; % count for total received partial frame         
         % STAs.Result_Partial_Frame(Partial_RX_ID, 2) = STAs.Focused_Frame_Inform(ID_Partial_RX(STAs.Focused_Frame_Inform(ID_Partial_RX, 2) == 0), 2); % save remained length of partial frame
         for i = 1:length(Partial_RX_ID)
                if STAs.Queue_Frame_List(Partial_RX_ID(i),STAs.Focused_Frame_Inform(Partial_RX_ID(i), 6)) < 0 ;  % Duplicated Frame is checked here.
                    STAs.Result_Partial_Frame(Partial_RX_ID(i), 3) = STAs.Result_Partial_Frame(Partial_RX_ID(i), 3) + 1;
                    % STAs.Result_Partial_Frame(Partial_RX_ID(i), 4) = 
                    STAs.Result_Partial_Frame(Partial_RX_ID(i), 2) = STAs.Result_Partial_Frame(Partial_RX_ID(i), 2) + STAs.Focused_Frame_Inform(Partial_RX_ID(i), 7);
                    STAs.Result_Partial_Frame(Partial_RX_ID(i), 4) = STAs.Result_Partial_Frame(Partial_RX_ID(i), 4) + STAs.Focused_Frame_Inform(Partial_RX_ID(i), 7);
                else
                    STAs.Result_Partial_Frame(Partial_RX_ID(i), 2) = STAs.Result_Partial_Frame(Partial_RX_ID(i), 2) + STAs.Focused_Frame_Inform(Partial_RX_ID(i), 7);
                    STAs.Result_Partial_Frame(Partial_RX_ID(i), 5) = STAs.Result_Partial_Frame(Partial_RX_ID(i), 5) + STAs.Focused_Frame_Inform(Partial_RX_ID(i), 7); % Frame length without dulpication
                end
         end
         %STAs.Result_Partial_Frame(Pratial_RX_ID, 3) = 
         
         %Pratial_RX_ID = 0;
         STAs.Focused_Frame_Inform(ID_Partial_RX(STAs.Focused_Frame_Inform(ID_Partial_RX, 2) == 0), 1:6) = 0;   % Initialization 
        end
        
        GOD.ID_RX = GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 5) == 0);  % finally, RX STAs that have partial frame are filtered here

    end
    
   
   if ( GOD.ID_RX )
    
    % Check Symbol Error in the current slot
    % RSSI_MAP_in_mW(STAs.Focused_Frame_Inform(GOD.ID_RX, 1), GOD.ID_RX);   % GET TX STA_ID and RSSI for each RX_STA 
    %    SIR = find(Intf_MAP(GOD.ID_TX,:) == 1);
    SIR(GOD.ID_RX) = STAs.Focused_Frame_Inform(GOD.ID_RX, 4)./( STAs.RSSI_Record(GOD.ID_RX, NOW_in_Slots)-STAs.Focused_Frame_Inform(GOD.ID_RX, 4) + Noise_Floor_in_mW);
    
    if (Opt_Self_Pruning_On )
        % Note) the unit of 'RSSI_Measurement' is mW. And the RSSI of interference frame should be added to the RSSI of the focusing(receiving) frame additively.
        if (RSSI_Measure_Mode == 0)  % 0: Last slot
            % SIR_Measurement(GOD.ID_RX)
            RSSI_Measurement(GOD.ID_RX) = STAs.RSSI_Record(GOD.ID_RX, NOW_in_Slots);
      
        elseif(RSSI_Measure_Mode == 1) % 1: Average Value
            % SIR_Measurement(GOD.ID_RX) = SIR_Measurement(GOD.ID_RX)+SIR(GOD.ID_RX);
            RSSI_Measurement(GOD.ID_RX) = RSSI_Measurement(GOD.ID_RX) + STAs.RSSI_Record(GOD.ID_RX, NOW_in_Slots)';
        elseif(RSSI_Measure_Mode == 2) % 2: Highest Value
            % SIR_Measurement(GOD.ID_RX(SIR_Measurement(GOD.ID_RX)< SIR(GOD.ID_RX))) = SIR(GOD.ID_RX(SIR_Measurement(GOD.ID_RX)< SIR(GOD.ID_RX)));
            RSSI_Measurement(GOD.ID_RX(RSSI_Measurement(GOD.ID_RX) < STAs.RSSI_Record(GOD.ID_RX, NOW_in_Slots)' ))...
                = STAs.RSSI_Record(GOD.ID_RX(RSSI_Measurement(GOD.ID_RX) < STAs.RSSI_Record(GOD.ID_RX, NOW_in_Slots)'), NOW_in_Slots)';
        elseif(RSSI_Measure_Mode == 3) % 3: Lowest Value
            % SIR_Measurement(GOD.ID_RX(SIR_Measurement(GOD.ID_RX)> SIR(GOD.ID_RX))) = SIR(GOD.ID_RX(SIR_Measurement(GOD.ID_RX)> SIR(GOD.ID_RX)));
             RSSI_Measurement(GOD.ID_RX(RSSI_Measurement(GOD.ID_RX) > STAs.RSSI_Record(GOD.ID_RX, NOW_in_Slots)' ))...
                = STAs.RSSI_Record(GOD.ID_RX(RSSI_Measurement(GOD.ID_RX) > STAs.RSSI_Record(GOD.ID_RX, NOW_in_Slots)'), NOW_in_Slots)';
        elseif(RSSI_Measure_Mode == 4) % 4: Median Value
            % SIR_Measurement(GOD.ID_RX);
            error('Unexpected RSSI or SIR Measurement mode(Median Value) is not supported yet...Simulation ends...'); 
        else
            error('Unexpected RSSI or SIR Measurement mode...Simulation ends...'); 
        end
    end
    
    if (Opt_Coloring_On )
        % Note) the unit of 'RSSI_Measurement' is mW. And the RSSI of interference frame should be added to the RSSI of the focusing(receiving) frame additively.
        if (RSSI_Measure_Mode_Coloring == 0)  % 0: Last slot
            % SIR_Measurement(GOD.ID_RX)
            RSSI_Measurement_Coloring(GOD.ID_RX) = STAs.RSSI_Record(GOD.ID_RX, NOW_in_Slots);
      
        elseif(RSSI_Measure_Mode_Coloring == 1) % 1: Average Value
            % SIR_Measurement(GOD.ID_RX) = SIR_Measurement(GOD.ID_RX)+SIR(GOD.ID_RX);
            RSSI_Measurement_Coloring(GOD.ID_RX) = RSSI_Measurement_Coloring(GOD.ID_RX) + STAs.RSSI_Record(GOD.ID_RX, NOW_in_Slots)';
        elseif(RSSI_Measure_Mode_Coloring == 2) % 2: Highest Value
            % SIR_Measurement(GOD.ID_RX(SIR_Measurement(GOD.ID_RX)< SIR(GOD.ID_RX))) = SIR(GOD.ID_RX(SIR_Measurement(GOD.ID_RX)< SIR(GOD.ID_RX)));
            RSSI_Measurement_Coloring(GOD.ID_RX(RSSI_Measurement_Coloring(GOD.ID_RX) < STAs.RSSI_Record(GOD.ID_RX, NOW_in_Slots)' ))...
                = STAs.RSSI_Record(GOD.ID_RX(RSSI_Measurement_Coloring(GOD.ID_RX) < STAs.RSSI_Record(GOD.ID_RX, NOW_in_Slots)'), NOW_in_Slots)';
        elseif(RSSI_Measure_Mode_Coloring == 3) % 3: Lowest Value
            % SIR_Measurement(GOD.ID_RX(SIR_Measurement(GOD.ID_RX)> SIR(GOD.ID_RX))) = SIR(GOD.ID_RX(SIR_Measurement(GOD.ID_RX)> SIR(GOD.ID_RX)));
             RSSI_Measurement_Coloring(GOD.ID_RX(RSSI_Measurement_Coloring(GOD.ID_RX) > STAs.RSSI_Record(GOD.ID_RX, NOW_in_Slots)' ))...
                = STAs.RSSI_Record(GOD.ID_RX(RSSI_Measurement_Coloring(GOD.ID_RX) > STAs.RSSI_Record(GOD.ID_RX, NOW_in_Slots)'), NOW_in_Slots)';
        elseif(RSSI_Measure_Mode_Coloring == 4) % 4: Median Value
            % SIR_Measurement(GOD.ID_RX);
            error('Unexpected RSSI or SIR Measurement mode(Median Value) is not supported yet...Simulation ends...'); 
        else
            error('Unexpected RSSI or SIR Measurement mode...Simulation ends...'); 
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     if( MAX_SIR < max(SIR))
%         MAX_SIR = max(SIR);
%     end
%     
%     if( Min_SIR > min(SIR))
%         Min_SIR = min(SIR);
%     end
%     SIR_Collector =  [SIR_Collector SIR(GOD.ID_RX)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %    SIR = RSSI_MAP_in_mW(STAs.Focused_Frame_Inform(GOD.ID_RX, 1), GOD.ID_RX)./( STAs.RSSI_Record(GOD.ID_RX,NOW_in_Slots-Interval)-RSSI_MAP_in_mW(STAs.Focused_Frame_Inform(GOD.ID_RX, 1), GOD.ID_RX));
    
    % Replace these bellow lines with error calculation function
%     Ser_QPSK(GOD.ID_RX) = erfc(sqrt(0.5*SIR(GOD.ID_RX))) - (1/4)*(erfc(sqrt(0.5*SIR(GOD.ID_RX)))).^2;
%     Slot_Error(GOD.ID_RX) = 1-(1-Ser_QPSK(GOD.ID_RX)).^(2.25);
    if (Opt_Error_Calc_Mode == 0)
            Slot_Error(GOD.ID_RX) =  Slot_Error_Calc(Data_Rate, U_Slot_Time, SIR(GOD.ID_RX));
    elseif (Opt_Error_Calc_Mode == 1);
%             for i = 1:length(GOD.ID_RX)
%                 if ( Max_Table_ESN0 < SIR(GOD.ID_RX(i)) )
%                     Idx_row = L_Table_ESN0;
%                 else    
% %                     tmp = abs(Table_ESN0.Table_SlotER(1,:)-SIR(GOD.ID_RX(i)));
% %                     Idx_row = find(tmp==min(tmp)); %index of closest value
%                     Idx_row = 0.1*(round(SIR(GOD.ID_RX(i))*10))/0.1+1;
%                 end
% %               Idx_row = Find_Nearest(Table_ESN0.Table_SlotER(1,:), SIR(GOD.ID_RX(i)));
%                 Slot_Error(GOD.ID_RX(i)) = Table_ESN0.Table_SlotER(find(MCS==Data_Rate)+1, uint64(Idx_row));
%             end
%            
            Idx_row = 0.001*(round(SIR(GOD.ID_RX)*1000))/0.001+1;
            Idx_row(Idx_row > L_Table_ESN0) = L_Table_ESN0;
            Idx = Table_ESN0.Table_SlotER((find(MCS==Data_Rate)+1)*ones(1,length(GOD.ID_RX)), uint64(Idx_row));
            Slot_Error(GOD.ID_RX) = Idx(1,:);
    elseif (Opt_Error_Calc_Mode == 2)  % No Error Mode
            Slot_Error(GOD.ID_RX) = zeros(1, length(GOD.ID_RX));
    end
    % Replacement END
    
%     Slot_Error(GOD.ID_RX) = 1;
%     Error_Decision_Array = rand(1, N_STA);
%     Error_Decision_Result(GOD.ID_RX) = Error_Decision_Array(GOD.ID_RX) - Slot_Error(GOD.ID_RX);
    Error_Decision_Result(GOD.ID_RX) = rand(1, length(GOD.ID_RX)) - Slot_Error(GOD.ID_RX);
    
    STAs.Focused_Frame_Inform(GOD.ID_RX( Error_Decision_Result(GOD.ID_RX) <= 0), 3) = STAs.Focused_Frame_Inform(GOD.ID_RX( Error_Decision_Result(GOD.ID_RX) <= 0), 3) + 1; % 3-th column count
    
    if  ( Opt_Control_Simple_Flooding_Probabilty )
            
            Low_RSSI_STAs = GOD.ID_RX( SIR(GOD.ID_RX) <= RSSI_Criteria) ; %dBm
            High_RSSI_STAs = GOD.ID_RX( SIR(GOD.ID_RX) > RSSI_Criteria) ;
            
            STAs.SFProb(Low_RSSI_STAs) = Low_Prob;
            STAs.SFProb(High_RSSI_STAs) = High_Prob;
    end
    
   
%     STAs.Queue(GOD.ID_RX) =  STAs.Queue(GOD.ID_RX)+1;
    STAs.Focused_Frame_Inform(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) > 0), 2)...
    = STAs.Focused_Frame_Inform(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) > 0), 2) - 1;
%     STAs.Focused_Frame_Inform
%     STAs.Count_Failure
    clear SIR Ser_QPSK Slot_Error Error_Decision_Result;

    % bellow lines are to process RX-frame when Receiving Frame is
    % finished.
    if STAs.Focused_Frame_Inform(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0), 1) % Check if there are any STAs who finish their RX.
        RX_ID = GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0);
        for i = 1:length(ID_Neighbor_STAs_of_Src)
            RX_ID_Neighbors  = RX_ID(RX_ID == ID_Neighbor_STAs_of_Src(i));
        end
        for i = 1:length(ID_Others)
            RX_ID_Others  = RX_ID(RX_ID == ID_Others(i));
        end
        
 
        
        Result_Failure_Reason_for_MPDUs(2, STAs.Focused_Frame_Inform(RX_ID, 6)) = Result_Failure_Reason_for_MPDUs(2, STAs.Focused_Frame_Inform(RX_ID, 6)) + 1; % 이 프레임에대해서 인접 STA에서 적어도 1번 이상의 전송 시도가 있었음.
        Result_Failure_Reason_for_MPDUs_Neighbors(2, STAs.Focused_Frame_Inform(RX_ID_Neighbors, 6)) = Result_Failure_Reason_for_MPDUs_Neighbors(2, STAs.Focused_Frame_Inform(RX_ID_Neighbors, 6)) + 1;
        Result_Failure_Reason_for_MPDUs_Others(2, STAs.Focused_Frame_Inform(RX_ID_Others, 6)) = Result_Failure_Reason_for_MPDUs_Others(2, STAs.Focused_Frame_Inform(RX_ID_Others, 6)) + 1;
       
%         STAs.Focused_Frame_Inform(RX_ID, 1) = 0;    % Initilization
%         
%         STAs.Focused_Frame_Inform(RX_ID, 4) = 0;
        
        STAs.Count_Failure(RX_ID, 1)= STAs.Count_Failure(RX_ID, 1) + 1; % count one for the number of  RX frame 
        
%         Failure_RX_ID = GOD.ID_RX( STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0 & STAs.Focused_Frame_Inform(GOD.ID_RX, 3) > 0 ) ;
        Failure_RX_ID = RX_ID(STAs.Focused_Frame_Inform(RX_ID, 3) > 0 ) ;
        STAs.Count_Failure(Failure_RX_ID, 2)  = STAs.Count_Failure(Failure_RX_ID, 2) + 1; % count for the number of error frame
        
        Failure_RX_ID_Frame_Seq = [Failure_RX_ID STAs.Focused_Frame_Inform(Failure_RX_ID, 6)];
        if (Failure_RX_ID_Frame_Seq)
            for i = 1:length(Failure_RX_ID_Frame_Seq(:,1))
                if STAs.Queue_Frame_List(Failure_RX_ID_Frame_Seq(i,1),Failure_RX_ID_Frame_Seq(i,2)) < 0 ;  % Duplicated Frame is checked here.
                    STAs.Count_Failure(Failure_RX_ID_Frame_Seq(i,1), 4) = STAs.Count_Failure(Failure_RX_ID_Frame_Seq(i,1), 4) + 1;    
                else
%                     STAs.Queue_Frame_List(i,i) = -1; 
                end
            end
        end
        

        
        Duplicated_Failure_RX_ID = [];
%         RX_ID = GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0);
        Failure_RX_ID_Frame_Seq_5th_col = [RX_ID(STAs.Focused_Frame_Inform(RX_ID, 3) == 0) STAs.Focused_Frame_Inform(RX_ID(STAs.Focused_Frame_Inform(RX_ID, 3) == 0), 6)];
        C=[];
        if (Failure_RX_ID_Frame_Seq_5th_col)
            for i = 1:length(Failure_RX_ID_Frame_Seq_5th_col(:,1))
                if STAs.Queue_Frame_List(Failure_RX_ID_Frame_Seq_5th_col(i,1),Failure_RX_ID_Frame_Seq_5th_col(i,2)) < 0;  % Duplicated Frame is checked here.
                    STAs.Count_Failure(Failure_RX_ID_Frame_Seq_5th_col(i,1), 5) = STAs.Count_Failure(Failure_RX_ID_Frame_Seq_5th_col(i,1), 5) + 1;
                    Duplicated_Failure_RX_ID = [Duplicated_Failure_RX_ID Failure_RX_ID_Frame_Seq_5th_col(i,1)];
                elseif STAs.Queue_Frame_List(Failure_RX_ID_Frame_Seq_5th_col(i,1),Failure_RX_ID_Frame_Seq_5th_col(i,2)) == -2;
                    % do nothing
                elseif STAs.Queue_Frame_List(Failure_RX_ID_Frame_Seq_5th_col(i,1),Failure_RX_ID_Frame_Seq_5th_col(i,2)) > 0
                    STAs.Queue_Frame_List(Failure_RX_ID_Frame_Seq_5th_col(i,1),Failure_RX_ID_Frame_Seq_5th_col(i,2)) = -1; 
                    C = [ C ; Failure_RX_ID_Frame_Seq_5th_col(i,1) Failure_RX_ID_Frame_Seq_5th_col(i,2)];
                else
                     error('Unexpected Queue_Frame_List...Simulation ends...'); 
                end
            end
        end
        
        
        
%         STAs.Count_Failure

%         A = STAs.Focused_Frame_Inform(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0, 6) - STAs.Queue(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0), 1);
%         In_Order_Failure_RX_ID = GOD.ID_RX( GOD.ID_RX(A) ~= 1); 
%         
        %In_Order_Failure_RX_ID = GOD.ID_RX( STAs.Focused_Frame_Inform(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0), 6) - STAs.Queue(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0), 1) ~= 1); 
        %STAs.Count_Failure(In_Order_Failure_RX_ID, 3) = STAs.Count_Failure(In_Order_Failure_RX_ID, 3) + 1; 
        In_Order_Failure_RX_ID=[];
        
%         Duplicated_Failure_RX_ID...
%         = GOD.ID_RX( STAs.Focused_Frame_Inform(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0), 6)...
%           - STAs.Queue(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0), 1) <= 0);
%         STAs.Queue(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0), 3) = STAs.Count_Failure(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0), 1)-STAs.Count_Failure(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0), 2)-STAs.Count_Failure(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0), 3);
        % STAs.Queue(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0), 1) = STAs.Focused_Frame_Inform(GOD.ID_RX(STAs.Focused_Frame_Inform(GOD.ID_RX, 2) == 0), 6);
        
%         B = GOD.ID_RX(GOD.ID_RX ~= In_Order_Failure_RX_ID & GOD.ID_RX ~= Failure_RX_ID);
        
        % 
%         if ( sum( [Failure_RX_ID In_Order_Failure_RX_ID]) )
%             B = GOD.ID_RX;
%             B( B == [Failure_RX_ID In_Order_Failure_RX_ID]) = [];
%        
%         else
%             B = GOD.ID_RX;
%         end
       
        %B = GOD.ID_RX; 
        B = RX_ID;
        B = B(~ismember(B,unique([In_Order_Failure_RX_ID Failure_RX_ID' Duplicated_Failure_RX_ID])));
        % B become STAs who receive its frame successufuly by filtering
        
        Result_Failure_Reason_for_MPDUs(3, STAs.Focused_Frame_Inform(B,6)) = Result_Failure_Reason_for_MPDUs(3, STAs.Focused_Frame_Inform(B,6)) - 1;
        

        
               
        STAs.Queue(B, 3) = STAs.Queue(B, 3) + 1;
        %STAs.Queue(B, 1) = STAs.Queue(B, 1) + 1;
        %STAs.Queue(B, 1) = ;% update latest RX Frame Seq #
        

        
        for i = 1: length(B)
%               STAs.Queue_Frame_List(B(i), (STAs.TX_Frame_Inform(B, 3)) ) = -2;
                %STAs.Queue(B(i), 1) = find(STAs.Queue_Frame_List(B(i),:) == -1, 1, 'first' );
                %if ( STAs.Queue(B(i), 3) > 0 )
                    STAs.Queue(B(i), 2) = find(STAs.Queue_Frame_List(B(i),:) == -1, 1, 'first' );
                    if(B(i) == 1)
                        error('Source Reception!');
                    end
                %end               
        end
        
        
        if (Opt_Measurement_Receive_Path)
            % DESCRIPTION
            % Row: ID of STAs
            % CASE 1) 1st Col: Source -> 1-hop ( or RED   -> GREEN )
            % CASE 2) 2nd Col: 1-hop  -> 1-hop ( or GREEN -> GREEN ) * Positive effect of duplication
            % CASE 3) 3rd Col: 1-hop  -> 2-hop ( or GREEN -> BLUE  )
            % CASE 4) 4th Col: 2-hop  -> 2-hop ( or BLUE  -> BLUE  ) * Positive effect of duplication
            % CASE 5) 5th Col: 2-hop  -> 1-hop ( or BLUE ->  GREEN ) * Positive effect of dulpication. reverse transmission.
            
            Neighbor_STAs = find(Intf_MAP(:,1) == 1);   % GREEN(1-hop) STA's IDs
            Other_STAs = find(Intf_MAP(:,1) == 0);      % BLUE(2-hop) STA's IDs
            Other_STAs(Other_STAs == 1) = [];
            
            for i = 1 : length(B)
            
                % Source STA으로 부터 수신 또는 RED 수신
                if STAs.Focused_Frame_Inform(B(i), 1) == 1
                    if B(i) == 1  % Current Color : RED
                        error('Exceptional CASE');
                    elseif ~isempty(find(B(i) == Neighbor_STAs,1)) % Current Color : GREEN                            
                    % CASE 1) 1st Col: Source -> 1-hop ( or RED   -> GREEN )
                        Measurement_Receive_Path(B(i), 1) =  Measurement_Receive_Path(B(i), 1) + 1;
                    elseif ~isempty(find(B(i) == Other_STAs,1)) % Current Color : BLUE
                        error('Exceptional CASE');
                    end

                % 1-hop STA으로 부터 수신 또는 GREEN 수신
                elseif ~isempty(find(STAs.Focused_Frame_Inform(B(i), 1) == Neighbor_STAs, 1))
                    if B(i) == 1  % Current Color : RED
                        error('Exceptional CASE');
                    elseif ~isempty(find(B(i) == Neighbor_STAs,1)) % Current Color : GREEN                            
                    % CASE 2) 2nd Col: 1-hop  -> 1-hop ( or GREEN -> GREEN ) * Positive effect of duplication
                        Measurement_Receive_Path(B(i), 2) =  Measurement_Receive_Path(B(i), 2) + 1;
                    elseif ~isempty(find(B(i) == Other_STAs,1))  % Current Color : BLUE
                    % CASE 3) 3rd Col: 1-hop  -> 2-hop ( or GREEN -> BLUE  )
                        Measurement_Receive_Path(B(i), 3) =  Measurement_Receive_Path(B(i), 3) + 1;
                    end

                % 2-hop STA으로 부터 수신 또는 BLUE 수신
                elseif  ~isempty(find(STAs.Focused_Frame_Inform(B(i), 1) == Other_STAs, 1))
                    if B(i) == 1  % Current Color : RED
                        error('Exceptional CASE');
                    elseif ~isempty(find(B(i) == Neighbor_STAs,1)) % Current Color : GREEN                            
                    % CASE 5) 5th Col: 2-hop  -> 1-hop ( or BLUE ->  GREEN ) * Positive effect of dulpication. reverse transmission.
                        Measurement_Receive_Path(B(i), 5) =  Measurement_Receive_Path(B(i), 5) + 1;
                    elseif ~isempty(find(B(i) == Other_STAs,1))  % Current Color : BLUE
                    % CASE 4) 4th Col: 2-hop  -> 2-hop ( or BLUE  -> BLUE  ) * Positive effect of duplication
                        Measurement_Receive_Path(B(i), 4) =  Measurement_Receive_Path(B(i), 4) + 1;
                    end
                end

            end       
                    
        end
        
         if (Opt_Measurement_Receive_Path_Duplication)
            % DESCRIPTION
            % Row: ID of STAs
            % CASE 1) 1st Col: Source -> 1-hop ( or RED   -> GREEN )
            % CASE 2) 2nd Col: 1-hop  -> 1-hop ( or GREEN -> GREEN ) * Positive effect of duplication
            % CASE 3) 3rd Col: 1-hop  -> 2-hop ( or GREEN -> BLUE  )
            % CASE 4) 4th Col: 2-hop  -> 2-hop ( or BLUE  -> BLUE  ) * Positive effect of duplication
            % CASE 5) 5th Col: 2-hop  -> 1-hop ( or BLUE ->  GREEN ) * Positive effect of dulpication. reverse transmission.
            
            Neighbor_STAs = find(Intf_MAP(:,1) == 1);   % GREEN(1-hop) STA's IDs
            Other_STAs = find(Intf_MAP(:,1) == 0);      % BLUE(2-hop) STA's IDs
            Other_STAs(Other_STAs == 1) = [];
            
            C = Duplicated_Failure_RX_ID;
            C(C==1) = [];
            %C =C(~ismember(C,unique([In_Order_Failure_RX_ID Failure_RX_ID'])));
        
            for i = 1 : length(C)
            
                % Source STA으로 부터 중복수신 또는 RED 수신
                if STAs.Focused_Frame_Inform(C(i), 1) == 1
                    if C(i) == 1  % Current Color : RED
                        error('Exceptional CASE');
                    elseif ~isempty(find(C(i) == Neighbor_STAs,1)) % Current Color : GREEN                            
                    % CASE 1) 1st Col: Source -> 1-hop ( or RED   -> GREEN )
                        Measurement_Receive_Path_Duplication(C(i), 1) =  Measurement_Receive_Path_Duplication(C(i), 1) + 1;
                    elseif ~isempty(find(C(i) == Other_STAs,1)) % Current Color : BLUE
                        error('Exceptional CASE');
                    end

                % 1-hop STA으로 부터 중복 수신 또는 GREEN 수신
                elseif ~isempty(find(STAs.Focused_Frame_Inform(C(i), 1) == Neighbor_STAs, 1))
                    if C(i) == 1  % Current Color : RED
                        error('Exceptional CASE');
                    elseif ~isempty(find(C(i) == Neighbor_STAs,1)) % Current Color : GREEN                            
                    % CASE 2) 2nd Col: 1-hop  -> 1-hop ( or GREEN -> GREEN ) * Positive effect of duplication
                        Measurement_Receive_Path_Duplication(C(i), 2) =  Measurement_Receive_Path_Duplication(C(i), 2) + 1;
                    elseif ~isempty(find(C(i) == Other_STAs,1))  % Current Color : BLUE
                    % CASE 3) 3rd Col: 1-hop  -> 2-hop ( or GREEN -> BLUE  )
                        Measurement_Receive_Path_Duplication(C(i), 3) =  Measurement_Receive_Path_Duplication(C(i), 3) + 1;
                    end

                % 2-hop STA으로 부터 중복 수신 또는 BLUE 수신
                elseif  ~isempty(find(STAs.Focused_Frame_Inform(C(i), 1) == Other_STAs, 1))
                    if C(i) == 1  % Current Color : RED
                        error('Exceptional CASE');
                    elseif ~isempty(find(C(i) == Neighbor_STAs,1)) % Current Color : GREEN                            
                    % CASE 5) 5th Col: 2-hop  -> 1-hop ( or BLUE ->  GREEN ) * Positive effect of dulpication. reverse transmission.
                        Measurement_Receive_Path_Duplication(C(i), 5) =  Measurement_Receive_Path_Duplication(C(i), 5) + 1;
                    elseif ~isempty(find(C(i) == Other_STAs,1))  % Current Color : BLUE
                    % CASE 4) 4th Col: 2-hop  -> 2-hop ( or BLUE  -> BLUE  ) * Positive effect of duplication
                        Measurement_Receive_Path_Duplication(C(i), 4) =  Measurement_Receive_Path_Duplication(C(i), 4) + 1;
                    end
                end

            end       
                    
         end
        
        
                       
        if (Opt_Coloring_On) % Update Color information from RX-Frame
                % Write color information in RX-Frame
                RX_Colored_ID = RX_ID; 
                
                % Update number of reception for each STA and each frame including errored frame
                STAs.Overhearing_Count_Frame2( RX_Colored_ID, STAs.Focused_Frame_Inform( RX_Colored_ID,6))...
                = STAs.Overhearing_Count_Frame2( RX_Colored_ID, STAs.Focused_Frame_Inform( RX_Colored_ID,6)) + 1;     
                
                RX_Colored_ID(STAs.Focused_Frame_Inform(RX_Colored_ID, 3) > 0 )  = [];   % Errorred frames are filtered here.
                
                % Update[Count 1] number of reception for each STA and each frame
                STAs.Overhearing_Count_Frame( RX_Colored_ID, STAs.Focused_Frame_Inform( RX_Colored_ID,6))...
                = STAs.Overhearing_Count_Frame( RX_Colored_ID, STAs.Focused_Frame_Inform( RX_Colored_ID,6)) + 1;     
                
                if FLD2_ReTx_Mode && Mode_OH_Time == 2
                    Temp_RX_Colored_ID = RX_Colored_ID;
                    for i = 1:length(Temp_RX_Colored_ID) 
                        if STAs.Time_Table_FLD2_ReTX(Temp_RX_Colored_ID(i), STAs.Focused_Frame_Inform( Temp_RX_Colored_ID(i),6)) < 0
                            % Do Nothing % error('Unexpected~~~!')
                        elseif STAs.Overhearing_MAP_FLD2_ReTx(Temp_RX_Colored_ID(i), STAs.Focused_Frame_Inform( Temp_RX_Colored_ID(i),6)) == -1
                            % Do Nothing % error('Unexpected~~~!')
                        elseif STAs.Time_Table_FLD2_ReTX(Temp_RX_Colored_ID(i), STAs.Focused_Frame_Inform( Temp_RX_Colored_ID(i),6)) > NOW_in_Slots
                            %Temp_RX_Colored_ID( STAs.Time_Table_FLD2_ReTX(Temp_RX_Colored_ID, STAs.Focused_Frame_Inform( Temp_RX_Colored_ID,6)) <= NOW_in_Slots) = [];
                            
                            STAs.Overhearing_MAP_FLD2_ReTx(Temp_RX_Colored_ID(i), STAs.Focused_Frame_Inform( Temp_RX_Colored_ID(i),6)) ...
                            = STAs.Overhearing_MAP_FLD2_ReTx(Temp_RX_Colored_ID(i), STAs.Focused_Frame_Inform( Temp_RX_Colored_ID(i),6)) + 1;             
                        end
                    end
                end
            
                if (RSSI_Measure_Mode_Coloring == 0)  % 0: Last slot
                    % Convert mW to dBm
                    RSSI_Measurement_Coloring(RX_Colored_ID) = 10*log10(RSSI_Measurement_Coloring(RX_Colored_ID));
                elseif(RSSI_Measure_Mode_Coloring == 1) % 1: Average Value
                    % Average mW. And then, convert mW to dBm
                    % SIR_Measurement(RX_ID) = SIR_Measurement(RX_ID)/TX_Duration_MPDU_in_Slots;
                    RSSI_Measurement_Coloring(RX_Colored_ID) = RSSI_Measurement_Coloring(RX_Colored_ID)/TX_Duration_MPDU_in_Slots;
                    RSSI_Measurement_Coloring(RX_Colored_ID) = 10*log10(RSSI_Measurement_Coloring(RX_Colored_ID));
             
                elseif(RSSI_Measure_Mode_Coloring == 2) % 2: Highest Value
                    % Convert mW to dBm
                    RSSI_Measurement_Coloring(RX_Colored_ID) = 10*log10(RSSI_Measurement_Coloring(RX_Colored_ID));
                elseif(RSSI_Measure_Mode_Coloring == 3) % 3: Lowest Value
                    % Convert mW to dBm
                    RSSI_Measurement_Coloring(RX_Colored_ID) = 10*log10(RSSI_Measurement_Coloring(RX_Colored_ID));
                elseif(RSSI_Measure_Mode_Coloring == 4) % 4: Median Value
                    % SIR_Measurement(GOD.ID_RX);
                    error('Unexpected SIR Measurement mode(Median Value) is not supported yet...Simulation ends...'); 
                else
                    error('Unexpected SIR Measurement mode...Simulation ends...'); 
                end
                
                % RX_Colored_ID =  RX_Colored_ID(RSSI_Measurement_Coloring(RX_Colored_ID) < Criterion_Coloring_RSSI_dBm); % Non-neighbor STAs are filtered by RSSI-criterion
                
                for i = 1 : length(RX_Colored_ID)
                
                    % case 1) RED 수신(Source STA->1-hop)
                    if STAs.Focused_Frame_Inform(RX_Colored_ID(i), 8) == 0
                       STAs.Color(RX_Colored_ID(i)) = 1; % Set to GREEN 
                        
                       if STAs.Color(RX_Colored_ID(i)) == 0  % Current Color : RED
                            % nothing to change
                            if RSSI_Measurement_Coloring(RX_Colored_ID(i)) >= Criterion_Coloring_RSSI_dBm
                                STAs.RGB_STA_MAP(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 1)) = 3;
                            end
                        elseif STAs.Color(RX_Colored_ID(i)) == 1 % Current Color : GREEN
                            % nothing to change
                            if RSSI_Measurement_Coloring(RX_Colored_ID(i)) >= Criterion_Coloring_RSSI_dBm
                                STAs.RGB_STA_MAP(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 1)) = 3; % To RED
                            end
                            
                        elseif STAs.Color(RX_Colored_ID(i)) == 2 % Current Color : BLUE
                            % nothing to change
                            
                            if RSSI_Measurement_Coloring(RX_Colored_ID(i)) >= Criterion_Coloring_RSSI_dBm
                                STAs.RGB_STA_MAP(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 1)) = 3; % To RED
                            end
                            
                        end
                        
                    % case 2) GREEN 수신(1-hop STA -> 2-hop STA, source STA, 1-hop STA)
                    elseif STAs.Focused_Frame_Inform(RX_Colored_ID(i), 8) == 1
                        if STAs.Color(RX_Colored_ID(i)) == 0  % Current Color : RED
                            % nothing to change
                            if RSSI_Measurement_Coloring(RX_Colored_ID(i)) >= Criterion_Coloring_RSSI_dBm
                                STAs.RGB_STA_MAP(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 1)) = 1;
                            end
                        elseif STAs.Color(RX_Colored_ID(i)) == 1 % Current Color : GREEN
                            % nothing to change
                            if RSSI_Measurement_Coloring(RX_Colored_ID(i)) >= Criterion_Coloring_RSSI_dBm
                                STAs.RGB_STA_MAP(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 1)) = 1;
                            end
                            
                        elseif STAs.Color(RX_Colored_ID(i)) == 2 % Current Color : BLUE
                            % nothing to change
                            
                            if RSSI_Measurement_Coloring(RX_Colored_ID(i)) >= Criterion_Coloring_RSSI_dBm
                                STAs.RGB_STA_MAP(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 1)) = 1;
                            end
                            
                        end
                        
                    % case 3) BLUE 수신
                    elseif STAs.Focused_Frame_Inform(RX_Colored_ID(i), 8) == 2
                        if STAs.Color(RX_Colored_ID(i)) == 0  % Current Color : RED
                            % nothing to change
                            if RSSI_Measurement_Coloring(RX_Colored_ID(i)) >= Criterion_Coloring_RSSI_dBm
                                STAs.RGB_STA_MAP(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 1)) = 2;
                            end
                        elseif STAs.Color(RX_Colored_ID(i)) == 1 % Current Color : GREEN                            
                            % nothing to change
                            if RSSI_Measurement_Coloring(RX_Colored_ID(i)) >= Criterion_Coloring_RSSI_dBm
                                STAs.RGB_STA_MAP(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 1)) = 2;
                            end
                        elseif STAs.Color(RX_Colored_ID(i)) == 2 % Current Color : BLUE
                            % nothing to change
                            if RSSI_Measurement_Coloring(RX_Colored_ID(i)) >= Criterion_Coloring_RSSI_dBm
                                STAs.RGB_STA_MAP(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 1)) = 2;
                            end
                        end
                    end
                % STAs.
                end
                
                % 
                for i = 1:length(RX_Colored_ID)
                    % Step 1) Count Neighbor GREEN(value:1, column:2) STAs to calculate its TX probability
                    STAs.RGB(RX_Colored_ID(i), 2) = length(find(STAs.RGB_STA_MAP(RX_Colored_ID(i),:) == 1));        
                    % Step 2) Count Neighbor BLUE(value:2, column:3) STAs to calculate its TX probability
                    STAs.RGB(RX_Colored_ID(i), 3) = length(find(STAs.RGB_STA_MAP(RX_Colored_ID(i),:) == 2));
                    % Step 3) Count Neighbor BLUE(value:2, column:3) STAs to calculate its TX probability
                    STAs.RGB(RX_Colored_ID(i), 1) = length(find(STAs.RGB_STA_MAP(RX_Colored_ID(i),:) == 3));
                end
                
                % Step 3) Transmission Probability Decision & Source(RED) Overhearing for Retransmission
                if Opt_Fixed_TX_Probability_On ~= 1
                    for i = 1:length(RX_Colored_ID)
                            if STAs.Color(RX_Colored_ID(i)) == 0  % Current Color : RED
                                % Do nothing, a source STA dose not restrict or control its transmission opportunity.
                                if (Opt_RED_Variable_TX_Probability_On || Opt_Common_TX_Probability_On)
                                    STAs.SFProb(RX_Colored_ID(i)) =  1/( STAs.RGB(RX_Colored_ID(i),2) + 1);
                                end

                                if ( Opt_RED_Retransmission_On && ~isempty(find(STAs.Color(RX_Colored_ID(i)) == 0, 1)) ) % Source(RED) Overhearing for Retransmission
                                    STAs.Overhearing_MAP(1, STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) = STAs.Overhearing_MAP(1, STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) + 1;


                                    if STAs.Focused_Frame_Inform(RX_Colored_ID(i), 8) == 1  % Check if the color of RX_FRAME is GREEN(1-hop)
                                        Existing_Color_Information_Index = find(Table_TX_Probability(:,1) == STAs.Focused_Frame_Inform(RX_Colored_ID(i), 1), 1);
                                        if ~isempty(Existing_Color_Information_Index)
                                            if ( Opt_Diff_TX_Probability_On )
                                                Table_TX_Probability(Existing_Color_Information_Index,:)...
                                                = [STAs.Focused_Frame_Inform(RX_Colored_ID(i), 1)...
                                                  STAs.Focused_Frame_Inform(RX_Colored_ID(i), 9:11)...
                                                  1/(sum(STAs.Focused_Frame_Inform(RX_Colored_ID(i), 9:10))+1)]; % step 2) Calculating TX Probabilities of each GREEN STAs.

                                            elseif ( Opt_Common_TX_Probability_On )
                                                Table_TX_Probability(Existing_Color_Information_Index,:)...
                                                = [STAs.Focused_Frame_Inform(RX_Colored_ID(i), 1)...
                                                  STAs.Focused_Frame_Inform(RX_Colored_ID(i), 9:11)...
                                                  1/(sum(STAs.Focused_Frame_Inform(RX_Colored_ID(i), 9:11))+1)]; % step 2) Calculating TX Probabilities of each GREEN STAs.
                                            end
                                        else
                                        % step 1) Gathering Color Informations from RX Frame
                                            if ( Opt_Diff_TX_Probability_On )
                                                Table_TX_Probability = [Table_TX_Probability;...
                                                STAs.Focused_Frame_Inform(RX_Colored_ID(i), 1)...
                                                STAs.Focused_Frame_Inform(RX_Colored_ID(i), 9:11)...
                                                1/(sum(STAs.Focused_Frame_Inform(RX_Colored_ID(i), 9:10))+1)]; % step 2) Calculating TX Probabilities of each GREEN STAs.

                                            elseif ( Opt_Common_TX_Probability_On )
                                                Table_TX_Probability = [Table_TX_Probability;...
                                                STAs.Focused_Frame_Inform(RX_Colored_ID(i), 1)...
                                                STAs.Focused_Frame_Inform(RX_Colored_ID(i), 9:11)...
                                                1/(sum(STAs.Focused_Frame_Inform(RX_Colored_ID(i), 9:11))+1)]; % step 2) Calculating TX Probabilities of each GREEN STAs.
                                            end
                                        end
                                    end

                                    if ~isempty(find(Overhearing_Time_Table(:,1) > 0, 1))   % If there exists any frame information to overhearing,
                                        Check_RX_Frame_Seq = find(Overhearing_Time_Table(:,1) == STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6), 1);
                                        % check if there are corresponded RX frame and then, get its seq #.                                  

                                        if ~isempty(Check_RX_Frame_Seq)
                                            %Overhearing_Time_Table(Check_RX_Frame_Seq,:) = [];  % Elimination
                                            Overhearing_Time_Table(Check_RX_Frame_Seq,4) = Overhearing_Time_Table(Check_RX_Frame_Seq,4) + 1;
                                        end

                                    end
                                end

                            elseif STAs.Color(RX_Colored_ID(i)) == 1 % Current Color : GREEN(N_RED + N_GREEN + 1)                            
                                if (Opt_Common_TX_Probability_On)
                                    STAs.SFProb(RX_Colored_ID(i)) = 1/( STAs.RGB(RX_Colored_ID(i),1) + STAs.RGB(RX_Colored_ID(i),2) + STAs.RGB(RX_Colored_ID(i),3) + 1 );
                                elseif (Opt_Diff_TX_Probability_On)
                                    STAs.SFProb(RX_Colored_ID(i)) =  1/( STAs.RGB(RX_Colored_ID(i),1) + STAs.RGB(RX_Colored_ID(i),2) + 1 );
                                elseif (Opt_Common_TX_Probability_On && Opt_Diff_TX_Probability_On)
                                    error('Wrong TX_Probaility Decision Mode!');
                                else
                                    error('Wrong TX_Probaility Decision Mode!');
                                end
                            elseif STAs.Color(RX_Colored_ID(i)) == 2 % Current Color : BLUE(N_GREEN + N_BLUE + 1)
                                if (Opt_Common_TX_Probability_On)
                                    STAs.SFProb(RX_Colored_ID(i)) = 1/( STAs.RGB(RX_Colored_ID(i),1) + STAs.RGB(RX_Colored_ID(i),2) + STAs.RGB(RX_Colored_ID(i),3) + 1 );
                                elseif (Opt_Diff_TX_Probability_On)   
                                    STAs.SFProb(RX_Colored_ID(i)) =  1/( STAs.RGB(RX_Colored_ID(i),2) + STAs.RGB(RX_Colored_ID(i),3) + 1);
                                elseif (Opt_Common_TX_Probability_On && Opt_Diff_TX_Probability_On)
                                    error('Wrong TX_Probaility Decision Mode!');
                                else
                                    error('Wrong TX_Probaility Decision Mode!');
                                end
                            end
                    end
                end
                               
                
                if Opt_Mode_All_BLUE_Pruning_On
                      
                      Other_STAs = find(Intf_MAP(:,1) == 0);      % BLUE(2-hop) STA's IDs
                      Other_STAs(Other_STAs == 1) = [];
                      STAs.SFProb(Other_STAs) = 0;
                     % STAs.SFProb(1) = 1;
                end
                
                if Opt_Mode_All_GREEN_Pruning_On
                    Neighbor_STAs = find(Intf_MAP(:,1) == 1);   % GREEN(1-hop) STA's IDs
                    STAs.SFProb(Neighbor_STAs) = 0;
                    % STAs.SFProb(1) = 1;
                end
                
                % Step 4) Self-Pruning(Discarding Frame) Decision
                % Reception_Boundary_Coloring
              
                for i = 1:length(RX_Colored_ID)
                    if Opt_Measurement_Prob_Pruning_Scheme_Batch_Type
                        Overhearing_Count = STAs.Overhearing_Count_Frame(RX_Colored_ID(i),STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6));
                        Pruning_Probability = Duplication_Decision_Table(2, Duplication_Decision_Table(1,:) == Overhearing_Count);
                               if ( rand <  Pruning_Probability...
                                        && STAs.Queue_Frame_List(RX_Colored_ID(i),STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) == -1)
                                    STAs.Queue(RX_Colored_ID(i),3) = STAs.Queue(RX_Colored_ID(i),3) - 1;
                                    if STAs.Queue(RX_Colored_ID(i),3) < 0
                                        error('unexpected queue length')
                                    end
                                    % STAs.Queue_Frame_List(Pruned_STA_ID(Idx_Pruned_STA_ID), Discarding_Frame_ID(Idx_Pruned_STA_ID)) = -2; % -2 means normal dequeing
                                    STAs.Queue_Frame_List(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) = -4;   % -4 means dequeing by pruning scheme
                                    if ( isempty(find(STAs.Queue_Frame_List(RX_Colored_ID(i),:) == -1, 1, 'first' )) )
                                        % do nothing. because there is any frame to send no longer.
                                    else
                                        STAs.Queue(RX_Colored_ID(i),2) = find(STAs.Queue_Frame_List(RX_Colored_ID(i),:) == -1, 1, 'first' );
                                    end
                                end
                    elseif Opt_Measurement_Det_Pruning_Scheme_Individulal_Type
                            Overhearing_Count = STAs.Overhearing_Count_Frame(RX_Colored_ID(i),STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6));
                            if ( Duplication_Decision_Table(RX_Colored_ID(i), Overhearing_Count) == 1 ...
                                        && STAs.Queue_Frame_List(RX_Colored_ID(i),STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) == -1)
                                    STAs.Queue(RX_Colored_ID(i),3) = STAs.Queue(RX_Colored_ID(i),3) - 1;
                                    if STAs.Queue(RX_Colored_ID(i),3) < 0
                                        error('unexpected queue length')
                                    end
                                    % STAs.Queue_Frame_List(Pruned_STA_ID(Idx_Pruned_STA_ID), Discarding_Frame_ID(Idx_Pruned_STA_ID)) = -2; % -2 means normal dequeing
                                    STAs.Queue_Frame_List(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) = -4;   % -4 means dequeing by pruning scheme
                                    if ( isempty(find(STAs.Queue_Frame_List(RX_Colored_ID(i),:) == -1, 1, 'first' )) )
                                        % do nothing. because there is any frame to send no longer.
                                    else
                                        STAs.Queue(RX_Colored_ID(i),2) = find(STAs.Queue_Frame_List(RX_Colored_ID(i),:) == -1, 1, 'first' );
                                    end
                             end
                    elseif Opt_Measurement_Prob_Pruning_Scheme_Individulal_Type ...  % PP2->FLD2
                            || Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_Linear ...
                            || Opt_Prob_Pruning_Scheme_Individulal_Type_Abstraction_MLC ... 
                            || Opt_Probabilistic_Counter_Based_Pruning_Scheme   % for ICTC2017(AFLD2)
                            
                            Overhearing_Count = STAs.Overhearing_Count_Frame(RX_Colored_ID(i),STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6));
                            if Opt_Probabilistic_Counter_Based_Pruning_Scheme % for ICTC2017(AFLD2)
                                if NOW_in_Slots*U_Slot_Time < Adaptation_Duration % Overhearing_Count <= Initial_M_Value
                                    % Pruning_Probability = Fixed_S_Value + ( log(1+mu* Overhearing_Count/Initial_M_Value)/log(1+mu))/(1/(1-Fixed_S_Value));
                                    Pruning_Probability = 0.0;
                                else 
                                    if STAs.Color(RX_Colored_ID(i)) == 1
                                        Pruning_Probability = Fixed_S_Value_Small + ( log(1+mu* ( (Overhearing_Count-1)/(sum(STAs.RGB(RX_Colored_ID(i),:))-1)) )/log(1+mu))/(1/(1-Fixed_S_Value_Small));
                                    elseif STAs.Color(RX_Colored_ID(i)) == 2 && STAs.RGB(RX_Colored_ID(i), 2) == 0
                                        Pruning_Probability = Fixed_S_Value_Large + ( log(1+mu* ( (Overhearing_Count-1)/(sum(STAs.RGB(RX_Colored_ID(i),:))-1)) )/log(1+mu))/(1/(1-Fixed_S_Value_Large));
                                    end       
                                end
                                
                            else
                                Pruning_Probability = Duplication_Decision_Table(RX_Colored_ID(i), Overhearing_Count);
                            end
                            
                            if(isnan(Pruning_Probability))
                                Pruning_Probability = 1;
                            end
                            if ( rand <  Pruning_Probability...   % If the frame will be discarded in the queue,
                                        && STAs.Queue_Frame_List(RX_Colored_ID(i),STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) == -1)
                                    STAs.Queue(RX_Colored_ID(i),3) = STAs.Queue(RX_Colored_ID(i),3) - 1;
                                    if STAs.Queue(RX_Colored_ID(i),3) < 0
                                        error('unexpected queue length')
                                    end
                                    % STAs.Queue_Frame_List(Pruned_STA_ID(Idx_Pruned_STA_ID), Discarding_Frame_ID(Idx_Pruned_STA_ID)) = -2; % -2 means normal dequeing
                                    STAs.Queue_Frame_List(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) = -4;   % -4 means dequeing by pruning scheme
                                    if ( isempty(find(STAs.Queue_Frame_List(RX_Colored_ID(i),:) == -1, 1, 'first' )) )
                                        % do nothing. because there is any frame to send no longer.
                                    else
                                        STAs.Queue(RX_Colored_ID(i),2) = find(STAs.Queue_Frame_List(RX_Colored_ID(i),:) == -1, 1, 'first' );
                                    end
                                    
                                    % In RX_STATE & FLD2(AFLD2), Fill up Time table for Retransmission.
                                    if FLD2_ReTx_Mode

                                       if STAs.Time_Table_FLD2_ReTX(RX_Colored_ID(i),STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) > 0
                                            error('Unexpected Transmitted Frame!');
                                       elseif STAs.Time_Table_FLD2_ReTX(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) == -3
                                           % Do Nothing, This line is related to retranmission limit
                                       else
                                           
                                            if Opt_OH_Time_Calc_On == 1
                                                % step 1) get the maximum value of duplication counter for the current node.
                                                max_dc =  max(STAs.Overhearing_Count_Frame(RX_Colored_ID(i),:));
                                                % step 2) calulate overhearing time based on the maximum duplication counter(virtual neighbor node)
                                                if max_dc > 0
                                                    P_tr = 1-(1-tau)^max_dc; 
                                                    P_s  = (  max_dc*tau*( (1-tau)^(max_dc-1) )  ) / P_tr;
                                                    Calculated_OH_Time = max_dc * ( (1-P_tr)*U_Slot_Time + P_tr*P_s*Ts + P_tr*(1-P_s)*Tc) ; % expressed in seconds.

                                                    % transform to slot...
                                                    STAs.Time_Table_FLD2_ReTX(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) ...
                                                        = NOW_in_Slots + ceil(Calculated_OH_Time/U_Slot_Time);
                                                    
                                                    if Measurement_OH_Time_On
                                                        STAs.Record_Overhearing_Time(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) ...
                                                        = ceil(Calculated_OH_Time/U_Slot_Time); % In slot
                                                    end
                                    
                                                else  % if max dc is 0(i.e., any transmission is not occured yet from neighbors), fixed overhearing time is used insteadly.
                                                    STAs.Time_Table_FLD2_ReTX(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) ...
                                                        = NOW_in_Slots + OH_Time;
                                                    
                                                    if Measurement_OH_Time_On
                                                        STAs.Record_Overhearing_Time(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) = OH_Time; % In slot
                                                    end
                                                end
                                           else  % fixed overhearing time is used insteadly.
                                                STAs.Time_Table_FLD2_ReTX(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) ... 
                                                    = NOW_in_Slots + OH_Time;
                                                
                                                if Measurement_OH_Time_On
                                                        STAs.Record_Overhearing_Time(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6))= OH_Time; % In slot
                                                end
                                                    
                                           end

                                           if Mode_OH_Time == 2
                                               if STAs.Overhearing_MAP_FLD2_ReTx(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) == -1
                                                   STAs.Overhearing_MAP_FLD2_ReTx(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) = 0; 
                                               else
                                                   error('Unexpected ~~~!');
                                               end
                                           end
                                           
                                           if Opt_Dynamic_DC_Th_On == 1 % Calculate dynamic threshold based on Mode value of duplication counter
                                               if max_dc > 0 
                                                   Temp_OCF = STAs.Overhearing_Count_Frame(RX_Colored_ID(i), :);
                                                   Temp_OCF(Temp_OCF == 0) = [];
                                                   
                                                   if Opt_Probabilistic_Counter_Based_Pruning_Scheme % for ICTC2017(AFLD2) 
                                                        Overhearing_Count = STAs.Overhearing_Count_Frame(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6));
                                                       if NOW_in_Slots*U_Slot_Time < Adaptation_Duration % Overhearing_Count <= Initial_M_Value
                                                            % Pruning_Probability = Fixed_S_Value + ( log(1+mu* Overhearing_Count/Initial_M_Value)/log(1+mu))/(1/(1-Fixed_S_Value));
                                                            Pruning_Probability = 0.0;
                                                       else 
                                                            if STAs.Color(RX_Colored_ID(i)) == 1
                                                                Pruning_Probability = Fixed_S_Value_Small + ( log(1+mu* ( (Overhearing_Count-1)/(sum(STAs.RGB(RX_Colored_ID(i),:))-1)) )/log(1+mu))/(1/(1-Fixed_S_Value_Small));
                                                            elseif STAs.Color(RX_Colored_ID(i)) == 2 && STAs.RGB(RX_Colored_ID(i), 2) == 0
                                                                Pruning_Probability = Fixed_S_Value_Large + ( log(1+mu* ( (Overhearing_Count-1)/(sum(STAs.RGB(RX_Colored_ID(i),:))-1)) )/log(1+mu))/(1/(1-Fixed_S_Value_Large));
                                                            end       
                                                       end
                                                       temp_dr = Pruning_Probability;
                                                   
                                                   elseif Opt_Measurement_Prob_Pruning_Scheme_Individulal_Type % FLD2
                                                            
                                                       if isnan(Duplication_Decision_Table( RX_Colored_ID(i), STAs.Overhearing_Count_Frame(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)))) ...
                                                           || Duplication_Decision_Table( RX_Colored_ID(i), STAs.Overhearing_Count_Frame(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6) ))  == -1

                                                           temp_dr = 0;
                                                           % temp_dr = 1;

                                                       else
                                                           temp_dr = Duplication_Decision_Table( RX_Colored_ID(i), STAs.Overhearing_Count_Frame(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6) ) );
                                                       end
                                                   else
                                                       error('Unexpected Flooding Scheme!');
                                                   end
                                                   
                                                   STAs.Dynamic_DC_Th( RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6) ) ...
                                                           = mode(Temp_OCF) ...
                                                           - ceil( max_dc * temp_dr );

                                                       % clear Temp_OCF;
          
                                               else
                                                   STAs.Dynamic_DC_Th( RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6) ) = DC_Threshold;
                                               end
                                           elseif Opt_Dynamic_DC_Th_On  == 2 % Calculate dynamic threshold based on MAX value of duplication counter(Not implemented yet)
                                               STAs.Dynamic_DC_Th(New_TX_STA_ID(i), STAs.TX_Frame_Inform(New_TX_STA_ID(i), 3) ) ...
                                                   = max(STAs.Overhearing_Count_Frame(RX_Colored_ID(i),:));
                                           end
   
                                       end

                                    end                                    
                                    
                            end
                    elseif Opt_Simple_Pruning_Probability_Adaptation_Scheme
                      
%                     elseif Opt_Probabilistic_Counter_Based_Pruning_Scheme  % for ICTC2017
%                           SBM_Point = GET_SBM_Point(Duplication_Decision_Table);
%                           % SBM_Point: (1) B Point (2) B1 Point (3) M Point (4) S Value
%                         
%                          for Idx_DDT = 2:length(Duplication_Decision_Table)
%                             Duplication_Decision_Table(Idx_DDT,1:SBM_Point(Idx_DDT,3)) ...
%                             = SBM_Point(Idx_DDT,4) + ( log(1+mu.*abs( (0:(SBM_Point(Idx_DDT,3)-1)))/(SBM_Point(Idx_DDT,3)-1) )./log(1+mu) )/(1/(1-SBM_Point(Idx_DDT,4)))  ;
%                             % = ( log(1+mu.*abs( (0:(SBM_Point(Idx_DDT,3)-1)))/(SBM_Point(Idx_DDT,3)-1) )./log(1+mu) )/(1/(1-SBM_Point(Idx_DDT,4)))  ;
%                             % = SBM_Point(Idx_DDT,4) + ( log(1+mu.*abs( (1:SBM_Point(Idx_DDT,3)))/SBM_Point(Idx_DDT,3) )./log(1+mu) ) /(1/(1-SBM_Point(Idx_DDT,4)));
%                          end
% 
%                          if (On_Fixed_S_Value ~= -1)  % If fixed S value is enable,
%                             Duplication_Decision_Table(1:Num_of_STAs+1) = On_Fixed_S_Value; 
%                          end
             
                    else
                        if STAs.Color(RX_Colored_ID(i)) == 0  % Current Color : RED
                            % Do nothing, 
                        %elseif Opt_GREEN_Self_Pruning && STAs.Color(RX_Colored_ID(i)) == 1 && STAs.Focused_Frame_Inform(RX_Colored_ID(i), 8) == 1 % Current Color : GREEN   
                        elseif  Opt_GREEN_Self_Pruning && STAs.Color(RX_Colored_ID(i)) == 1  % Current Color : GREEN

                            if RSSI_Measurement_Coloring(RX_Colored_ID(i)) > Criterion_Coloring_Pruning_RSSI_dBm_GREEN
                                if ( STAs.Overhearing_Count_Frame(RX_Colored_ID(i),STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) >= Opt_GREEN_Reception_Boundary_Coloring...
                                        && STAs.Queue_Frame_List(RX_Colored_ID(i),STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) == -1)
                                    STAs.Queue(RX_Colored_ID(i),3) = STAs.Queue(RX_Colored_ID(i),3) - 1;
                                    if STAs.Queue(RX_Colored_ID(i),3) < 0
                                        error('unexpected queue length')
                                    end
                                    % STAs.Queue_Frame_List(Pruned_STA_ID(Idx_Pruned_STA_ID), Discarding_Frame_ID(Idx_Pruned_STA_ID)) = -2; % -2 means normal dequeing
                                    STAs.Queue_Frame_List(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) = -4;   % -4 means dequeing by pruning scheme
                                    if ( isempty(find(STAs.Queue_Frame_List(RX_Colored_ID(i),:) == -1, 1, 'first' )) )
                                        % do nothing. because there is any frame to send no longer.
                                    else
                                        STAs.Queue(RX_Colored_ID(i),2) = find(STAs.Queue_Frame_List(RX_Colored_ID(i),:) == -1, 1, 'first' );
                                    end
                                end
                            end

                               % Current Color : BLUE
    %                     elseif Opt_BLUE_Self_Pruning && STAs.Color(RX_Colored_ID(i)) == 2 && STAs.Focused_Frame_Inform(RX_Colored_ID(i), 8) == 2 %... 
    %                             % && STAs.Focused_Frame_Inform(RX_Colored_ID(i), 10) == 0
                          elseif Opt_BLUE_Self_Pruning && STAs.Color(RX_Colored_ID(i)) == 2 
                            if RSSI_Measurement_Coloring(RX_Colored_ID(i)) > Criterion_Coloring_Pruning_RSSI_dBm_BLUE
                                if ( STAs.Overhearing_Count_Frame(RX_Colored_ID(i),STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) >= Opt_BLUE_Reception_Boundary_Coloring...
                                        && STAs.Queue_Frame_List(RX_Colored_ID(i),STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) == -1)
                                    STAs.Queue(RX_Colored_ID(i),3) = STAs.Queue(RX_Colored_ID(i),3) - 1;
                                    if STAs.Queue(RX_Colored_ID(i),3) < 0
                                        error('unexpected queue length')
                                    end
                                    % STAs.Queue_Frame_List(Pruned_STA_ID(Idx_Pruned_STA_ID), Discarding_Frame_ID(Idx_Pruned_STA_ID)) = -2; % -2 means normal dequeing
                                    STAs.Queue_Frame_List(RX_Colored_ID(i), STAs.Focused_Frame_Inform(RX_Colored_ID(i), 6)) = -4;   % -4 means dequeing by pruning scheme
                                    if ( isempty(find(STAs.Queue_Frame_List(RX_Colored_ID(i),:) == -1, 1, 'first' )) )
                                        % do nothing. because there is any frame to send no longer.
                                    else
                                        STAs.Queue(RX_Colored_ID(i),2) = find(STAs.Queue_Frame_List(RX_Colored_ID(i),:) == -1, 1, 'first' );
                                    end
                                end
                            end

                            if (Opt_BLUE_TPC)
                                % check out neighbor BLUE STAs that cannot sense 1-hop STA(GREEN) from its RX-FRAME
                                if STAs.Focused_Frame_Inform(RX_Colored_ID(i), 10) == 0
                                   % get min RSSI
                                   if STAs.TX_Power(RX_Colored_ID(i)) 

                                   end
                                end


                            end

                        end
                    
                    end
                    
                    % Additional Scheme I: BLUE STAs(2-hop) Pruning
                    % Description: In the case of BLUE(2-hop) STAs, if any BLUE(2-hop) STA cannot sense GREEN or BLUE(wrong condition!) STA at all,
                    % they don't try to access channel by discarding frames. Because those STAs just disturb other transmission unneccessarily
                    % And they are located on edge of topology explicitly.
                    if Opt_Additional_BLUE_Self_Pruning && STAs.Color(RX_Colored_ID(i)) == 2 
                       	if find(STAs.Queue_Frame_List(RX_Colored_ID(i),:) == -1, 1, 'first' ) > 1 
                            %if STAs.Queue(RX_Colored_ID(i),3) > 0 && ( STAs.RGB(RX_Colored_ID(i), 2) == 0 || STAs.RGB(RX_Colored_ID(i), 3) == 0)
                            if STAs.Queue(RX_Colored_ID(i),3) > 0 && ( STAs.RGB(RX_Colored_ID(i), 2) == 0)
                                STAs.Queue(RX_Colored_ID(i),3) = 0;
                                STAs.Queue_Frame_List(RX_Colored_ID(i),STAs.Queue_Frame_List(RX_Colored_ID(i), :) == -1) = -4; % -4 means dequeing by pruning scheme
                            end
                        end
                       
                    end
                    
                    % % Additional Scheme II: GREEN STAs(1-hop) Pruning
                    % Description: In the case of GREEN(1-hop) STAs, if any GREEN(2-hop) STA cannot sense BLUE(wrong condition!) STA at all,
                    % they don't try to access channel by discarding frames. Because those STAs just disturb other transmission unneccessarily
                    % And they are located on center of topology(a source STA) explicitly.(i.e., they don't need to contribute to disseminate traffic to 2-hop STAs.)
                    if Opt_Additional_GREEN_Self_Pruning &&...
                            STAs.Color(RX_Colored_ID(i)) == 1 &&...
                            STAs.Queue(RX_Colored_ID(i),3) > 0
                            %&& STAs.RGB(RX_Colored_ID(i), 3) == 0  
                        if ~isempty(max(RSSI_MAP(RX_Colored_ID(i),STAs.RGB_STA_MAP(RX_Colored_ID(i),:) == 2)) <= Criterion_Coloring_Additional_Pruning_RSSI_dBm_GREEN) &&...
                                max(RSSI_MAP(RX_Colored_ID(i),STAs.RGB_STA_MAP(RX_Colored_ID(i),:) == 2)) <= Criterion_Coloring_Additional_Pruning_RSSI_dBm_GREEN ||...
                                STAs.RGB(RX_Colored_ID(i), 3) == 0 
                            if find(STAs.Queue_Frame_List(RX_Colored_ID(i),:) == -1, 1, 'first' ) > 1
                                STAs.Queue(RX_Colored_ID(i),3) = 0;
                                STAs.Queue_Frame_List(RX_Colored_ID(i),STAs.Queue_Frame_List(RX_Colored_ID(i), :) == -1) = -4; % -4 means dequeing by pruning scheme
                            end
                        end
                    end
                    
                    
                end
                
                    

                    
                RSSI_Measurement_Coloring(RX_ID) = zeros(1, length(RX_ID)); % Re-initialization for STAs that finished their current transmission.
                
                
        end
        
        % <START> - Self-Pruning mode-------------------------------------%
        if (Opt_Self_Pruning_On )
            
            if (RSSI_Measure_Mode == 0)  % 0: Last slot
                % Convert mW to dBm
                RSSI_Measurement(RX_ID) = 10*log10(RSSI_Measurement(RX_ID));
            elseif(RSSI_Measure_Mode == 1) % 1: Average Value
                % Average mW. And then, convert mW to dBm
                % SIR_Measurement(RX_ID) = SIR_Measurement(RX_ID)/TX_Duration_MPDU_in_Slots;
                RSSI_Measurement(RX_ID) = RSSI_Measurement(RX_ID)/TX_Duration_MPDU_in_Slots;
                RSSI_Measurement(RX_ID) = 10*log10(RSSI_Measurement(RX_ID));
                if ( ~isempty(RX_ID == 22))
                    if(STAs.Focused_Frame_Inform(22, 1) == 1)
                        RSSI_Colector = [RSSI_Colector RSSI_Measurement(RX_ID(RX_ID==22))];
                    end
                end
            elseif(RSSI_Measure_Mode == 2) % 2: Highest Value
                % Convert mW to dBm
                RSSI_Measurement(RX_ID) = 10*log10(RSSI_Measurement(RX_ID));
            elseif(RSSI_Measure_Mode == 3) % 3: Lowest Value
                % Convert mW to dBm
                RSSI_Measurement(RX_ID) = 10*log10(RSSI_Measurement(RX_ID));
            elseif(RSSI_Measure_Mode == 4) % 4: Median Value
                % SIR_Measurement(GOD.ID_RX);
                error('Unexpected SIR Measurement mode(Median Value) is not supported yet...Simulation ends...'); 
            else
                error('Unexpected SIR Measurement mode...Simulation ends...'); 
            end
            
            
            
            % check RSSI of each frame here!
            Under_RSSI_Criterion_RX_ID = RX_ID(RSSI_Measurement(RX_ID) < Criterion_RSSI_dBm );
            %Under_RSSI_Criterion_RX_ID = RX_ID(RSSI_Measurement(RX_ID) > Criterion_RSSI_dBm );
            Candidate_Pruned_STAs_ID = RX_ID;
            Candidate_Pruned_STAs_ID = ...
            Candidate_Pruned_STAs_ID(~ismember(Candidate_Pruned_STAs_ID,unique([In_Order_Failure_RX_ID Failure_RX_ID' Under_RSSI_Criterion_RX_ID'])));
            
            STAs.Overhearing_Count_Frame(Candidate_Pruned_STAs_ID, STAs.Focused_Frame_Inform(Candidate_Pruned_STAs_ID,6))...
            = STAs.Overhearing_Count_Frame(Candidate_Pruned_STAs_ID, STAs.Focused_Frame_Inform(Candidate_Pruned_STAs_ID,6)) + 1;      
            
            Filtered_Frame_n_STA_ID = (STAs.Queue_Frame_List(Candidate_Pruned_STAs_ID,:) == -1)...
                                      &...
                                      ( STAs.Overhearing_Count_Frame(Candidate_Pruned_STAs_ID,:) > Reception_Boundary);
%              Filtered_Frame_n_STA_ID = (STAs.Queue_Frame_List(Candidate_Pruned_STAs_ID,:) >= -1) & ( STAs.Overhearing_Count_Frame(Candidate_Pruned_STAs_ID,:) > Reception_Boundary);
            [Pruned_STA_ID, Discarding_Frame_ID] = find(Filtered_Frame_n_STA_ID == 1);
            Pruned_STA_ID = Candidate_Pruned_STAs_ID(Pruned_STA_ID);
            
            for Idx_Pruned_STA_ID = 1:length(Pruned_STA_ID) 
                if ( RCP_Tx_Probability <= rand )
                    STAs.Queue(Pruned_STA_ID(Idx_Pruned_STA_ID),3) = STAs.Queue(Pruned_STA_ID(Idx_Pruned_STA_ID),3) - 1;
                    % STAs.Queue_Frame_List(Pruned_STA_ID(Idx_Pruned_STA_ID), Discarding_Frame_ID(Idx_Pruned_STA_ID)) = -2; % -2 means normal dequeing
                    STAs.Queue_Frame_List(Pruned_STA_ID(Idx_Pruned_STA_ID), Discarding_Frame_ID(Idx_Pruned_STA_ID)) = -4;   % -4 means dequeing by pruning scheme
                    if ( isempty(find(STAs.Queue_Frame_List(Pruned_STA_ID(Idx_Pruned_STA_ID),:) == -1, 1, 'first' )) )
                        % do nothing. because there is any frame to send no longer.
                    else
                        STAs.Queue(Pruned_STA_ID(Idx_Pruned_STA_ID),2) = find(STAs.Queue_Frame_List(Pruned_STA_ID(Idx_Pruned_STA_ID),:) == -1, 1, 'first' );
                    end
                else
                    % do nothing. because a candidate has a higher value than RCP TX_Probability. 
                end
            end
            % SIR_Measurement(RX_ID) = zeros(1, length(RX_ID)); % Re-initialization for STAs that finished their current transmission.
              RSSI_Measurement(RX_ID) = zeros(1, length(RX_ID)); % Re-initialization for STAs that finished their current transmission.
        end
        % <END> - Self-Pruning mode---------------------------------------%
        
        % 17-06-07
        % Now, Each node can know from which node the frame is received for the received frame.
        % For above function, the required data structure is defined in "Inintialization_STA.m".  
        % % -1: Not received yet. any Node ID: its TX NODEs.
        for idx_Record_TX_Node_ID = 1:length(B)
            if ~isempty(find(STAs.Record_TX_Node_ID(B(idx_Record_TX_Node_ID), STAs.Focused_Frame_Inform(B(idx_Record_TX_Node_ID),6)) >= 0, 1))
                error('Wrong Record Trial!!');
            else
                STAs.Record_TX_Node_ID(B(idx_Record_TX_Node_ID), STAs.Focused_Frame_Inform(B(idx_Record_TX_Node_ID),6)) ...
                    = STAs.Focused_Frame_Inform(B(idx_Record_TX_Node_ID),1);
            end
        end
        if( Opt_Src_Retransmission_Mode || Opt_Measurement_On )
            
            if ((RX_ID(1) == 1) && STAs.Focused_Frame_Inform(RX_ID(1), 3) == 0)
                STAs.Overhearing_MAP(1, STAs.Focused_Frame_Inform(RX_ID(1), 6)) = STAs.Overhearing_MAP(1, STAs.Focused_Frame_Inform(RX_ID(1), 6)) + 1;
            end
            
            % bellow is just for measurement. the Relay STAs do not re-tx at all.
            % These statements only count for number of received frame regardless of error or dulpication
            for i=1:length(RX_ID)
                if (RX_ID(i) ~= 1)
                    if (STAs.Overhearing_MAP(RX_ID(i), STAs.Focused_Frame_Inform(RX_ID(i), 6)) == -1 )
                        STAs.Overhearing_MAP(RX_ID(i), STAs.Focused_Frame_Inform(RX_ID(i), 6)) = 0;
                    end
                    
                    if (STAs.Queue_Frame_List(RX_ID(i), STAs.Focused_Frame_Inform(RX_ID(i), 6)) > 0)
                        STAs.Overhearing_MAP(RX_ID(i), STAs.Focused_Frame_Inform(RX_ID(i), 6))...
                        = STAs.Overhearing_MAP(RX_ID(i), STAs.Focused_Frame_Inform(RX_ID(i), 6)) + 1;              
                    end
                    
                end
            end
            
        elseif ( Opt_All_Retransmission_Mode )
            for i=1:length(RX_ID)
                if (STAs.Queue_Frame_List(RX_ID(i), STAs.Focused_Frame_Inform(RX_ID(i), 6)) == -2)  % Check if corresponding frame is sent. 
                    STAs.Overhearing_MAP(RX_ID(i), STAs.Focused_Frame_Inform(RX_ID(i), 6)) = 0;
                end
                
                if ( STAs.Focused_Frame_Inform(RX_ID(i), 3) == 0 && STAs.Overhearing_MAP(STAs.Focused_Frame_Inform(RX_ID(i), 6)) == 0)    % If no Error, update their Overhearing MAP
                    STAs.Overhearing_MAP(RX_ID(i), STAs.Focused_Frame_Inform(RX_ID(i), 6)) = STAs.Overhearing_MAP(RX_ID(i), STAs.Focused_Frame_Inform(RX_ID(i), 6)) + 1; 
                end
            end
            
        else
            % Do Nothing
        end
        
        for i = 1: length(B)
                if( B(i) ~= 1)
                    Result_Failure_Reason_for_MPDUs(1, STAs.Focused_Frame_Inform(B(i),6))...
                    = Result_Failure_Reason_for_MPDUs(1, STAs.Focused_Frame_Inform(B(i),6))...
                    + STAs.Overhearing_MAP(B(i), STAs.Focused_Frame_Inform(B(i),6));
                end
        end
        
        STAs.Focused_Frame_Inform(RX_ID, 3) = 0;  % Intialization slot error count
        STAs.Focused_Frame_Inform(RX_ID, 1) = 0;  % Initilization
        STAs.Focused_Frame_Inform(RX_ID, 4) = 0;
%         % bellow codes are for debugging and validation
%         if ~isempty(B) && isempty(C)
%             B==C
%             error('Unexpected Case...Simulation ends...'); 
%         elseif  isempty(B) && ~isempty(C)
%             B==C
%             error('Unexpected Case...Simulation ends...'); 
%         elseif ~isempty(B) && ~isempty(C)
%             for i = 1 : max([length(B) length(C(:,1))])
%                 if B(i) == C(i,1)
%                     %B(i) == C(i,1);
%                 else
%                     error('Unexpected Case...Simulation ends...'); 
%                 end
%             end
%         end

    end
    %     Interval = find(STAs.Focused_Frame_Inform(:,2) == 0 & STAs.Focused_Frame_Inform(:,3) ~= 0 & STAs.Focused_Frame_Inform(:,3) <= NOW_in_Slots);
%     STAs.MAC_STATE(:, 1:Interval) = STAs.MAC_STATE(:, Interval: Last_Rec-Interval);
%     STAs.MAC_STATE(:, Last_Rec-Interval+1:L_Rec) = 0;
   
       
   end
   
    % enque a frame to retransmit
    if FLD2_ReTx_Mode
        
        for i=1:N_STA
           ReTX_Candidate = find(STAs.Time_Table_FLD2_ReTX(i, :) <= NOW_in_Slots & STAs.Time_Table_FLD2_ReTX(i, :) > 0);
           
           if( ~isempty(find( STAs.Queue_Frame_List( i, ReTX_Candidate ) == -1 | STAs.Queue_Frame_List( i, ReTX_Candidate ) > 0,1))  )
               error('unexpected frame!');  % Check if any frame that do not receive yet exits
           end
           
           if Mode_OH_Time == 1
               if Opt_Dynamic_DC_Th_On == 1
                    Temp_ReTX_Candidate = ReTX_Candidate( STAs.Overhearing_Count_Frame(i, ReTX_Candidate) <= STAs.Dynamic_DC_Th(i, ReTX_Candidate) ); 
               elseif Opt_Dynamic_DC_Th_On == 2
               
               else % fixed DC_Threshold
                    Temp_ReTX_Candidate = ReTX_Candidate(STAs.Overhearing_Count_Frame(i, ReTX_Candidate) <= DC_Threshold); 
               end
           elseif Mode_OH_Time == 2
               Temp_ReTX_Candidate = ReTX_Candidate(STAs.Overhearing_MAP_FLD2_ReTx(i, ReTX_Candidate) <= DC_Threshold);
           else
               error('Unexpected Overhearing Time Mode!');
           end
           
           if ~isempty(Temp_ReTX_Candidate)  
                 %Temp_ReTX_Candidate = ReTX_Candidate(STAs.Overhearing_Count_Frame(i, ReTX_Candidate) <= DC_Threshold);
                 
%                  if( ~isempty(find( STAs.Queue_Frame_List( i, Temp_ReTX_Candidate ) == -1,1))  )
%                      error('unexpected frame!');  % Check if any frame that do not receive yet exits
%                  end
           
                 if ~isempty(find(STAs.Queue_Frame_List( i, Temp_ReTX_Candidate) > 0, 1))
                     error('unexpected frame!');  % Check if any frame that do not receive yet exits
                 end
                 
%                  if ~isempty( find(STAs.Time_Table_FLD2_ReTX(i, Temp_ReTX_Candidate)/-1 <= Retry_Limit, 1) )
%                      Temp_ReTX_Candidate = find(STAs.Time_Table_FLD2_ReTX(i, STAs.Time_Table_FLD2_ReTX(i, ReTX_Candidate) <= DC_Threshold )/-1 <= Retry_Limit);
                     
                     STAs.Time_Table_FLD2_ReTX(i, Temp_ReTX_Candidate) = -3;  % These frames will be enqued to retransmit.
                     
                     if( ~isempty(find( STAs.Queue_Frame_List( i, Temp_ReTX_Candidate ) == -1,1))  )
                         error('unexpected frame!');  % Check if any frame that do not receive yet exits
                     end
                         STAs.Queue_Frame_List( i, Temp_ReTX_Candidate ) = -1;
                         STAs.Queue(i,3) = STAs.Queue(i,3) + length(Temp_ReTX_Candidate);

                         STAs.Queue(i,2) = find(STAs.Queue_Frame_List(i,:) == -1, 1, 'first' );
                    
%                  end
           end

        
        end
    end

    if( Opt_Src_Retransmission_Mode && Num_Src_Retry < 2 )  % '5' means to temporary boundary of source retry         
          
            if ( sum(STAs.MAC_STATE(1, NOW_in_Slots)) )
                IDLE_Period_Src = 0;
            else
                IDLE_Period_Src = IDLE_Period_Src + 1; 
            end
     
            if( Opt_Decision_Boundary_for_No_More_TX_RX_MODE <= IDLE_Period_Src...
                    && length(find(STAs.Overhearing_MAP(1,:) == 0)) > 0)
                
                for ii = 1: length(STAs.Queue_Frame_List)
                   if( length(find(STAs.Queue_Frame_List(:,ii) > 0)) == (N_STA-1) ) 
                       Actual_Failure_Frame_of_Src = [Actual_Failure_Frame_of_Src ii];  
                   elseif ( length(find(STAs.Queue_Frame_List(:,ii) > 0)) == 0 ) 
                       % Do Nothing
                   else
                       Normal_Failure_Frame = [Normal_Failure_Frame ii];
                   end
                end
                Actual_Failure_Frame_of_Src(Actual_Failure_Frame_of_Src == 0) = []; % eliminate value zero
                Actual_Failure_Frame_of_Src = [Actual_Failure_Frame_of_Src -1];   % mark the end of this time scope
                
                Normal_Failure_Frame(Normal_Failure_Frame==0) = []; % eliminate value zero
                Normal_Failure_Frame = [Normal_Failure_Frame -1];   % mark the end of this time scope
                
                % number of '-1' should be same as 'Num_Src_Retry'
                
                
                if ( length(find(STAs.Overhearing_MAP(1,:) == 0)) > 0)
                    Num_Src_Retry = Num_Src_Retry +1
                    % NOW_in_Slots
                    disp('Retransmission Time of Src STA');
                    SrcRetransmission_Time = (NOW_in_Slots)*9*10^-6   % Retransmission Time of Src STA
            
                    disp('Sequence Numbers of Frames to Re-TX'); 
                    Seq_Retry = [Seq_Retry find(STAs.Overhearing_MAP(1,:) == 0)];
                    Seq_Retry(Seq_Retry == 0) = [];
                    Seq_Retry = [Seq_Retry -1]; % mark the end of this time scope
                    STAs.Queue_Frame_List(1, find(STAs.Overhearing_MAP(1,:) == 0)) = -1;
                    STAs.Queue(1,3) = STAs.Queue(1,3) + length(find(STAs.Overhearing_MAP(1,:) == 0));
                    STAs.Queue(1,2) = find(STAs.Queue_Frame_List(1,:) == -1, 1, 'first' );
                    % Disable Bellows command for additional retransmission.
                    % STAs.Overhearing_MAP(1,find(STAs.Overhearing_MAP(1,:) == 0)) = 1;  % As this statement, src try to retransmit just one time.
                    IDLE_Period_Src = 0;  % So, this statement substitute above command insteadly.
                end
                    if ( Num_Src_Retry == 1)
              
                        N_1_Hop_Failure(Num_Src_Retry) = length(Actual_Failure_Frame_of_Src)-1;
                        N_Other_Failure(Num_Src_Retry) = length(Normal_Failure_Frame)-1;
                        N_Estimation(Num_Src_Retry) = length(Seq_Retry)-1;
                    
                    else
                        temp_index = find(Actual_Failure_Frame_of_Src==-1);
                        N_1_Hop_Failure(Num_Src_Retry) = length(Actual_Failure_Frame_of_Src)-1 - temp_index(Num_Src_Retry-1);
                        temp_index = find(Normal_Failure_Frame==-1);
                        N_Other_Failure(Num_Src_Retry) = length(Normal_Failure_Frame)-1- temp_index(Num_Src_Retry-1);
                        temp_index = find(Seq_Retry==-1);
                        N_Estimation(Num_Src_Retry) = length(Seq_Retry)-1- temp_index(Num_Src_Retry-1);
                        clear temp_index;
                    end
            end
    elseif ( Opt_All_Retransmission_Mode )    
            
         for i=1:N_STA
            if ( sum(STAs.MAC_STATE(i, NOW_in_Slots)) )
                IDLE_Period_All(i) = 0;
            else
                IDLE_Period_All(i) = IDLE_Period_All(i) + 1; 
            end
     
            if( Opt_Decision_Boundary_for_No_More_TX_RX_MODE <= IDLE_Period_All(i) )
                if ( length(find(STAs.Overhearing_MAP(i,:) == 0)) > 0)
                    % NOW_in_Slots
                    % disp('Retransmission Time of Src STA');
                    % SrcRetransmission_Time = (NOW_in_Slots)*9*10^-6   % Retransmission Time of Src STA
            
                    %disp('Sequence Numbers of Frames to Re-TX'); find(STAs.Overhearing_MAP(i,:) == 0)
                    % Debug Condition : NOW_in_Slots == 338235
                    STAs.Queue_Frame_List(i, find(STAs.Overhearing_MAP(i,:) == 0)) = -1;
                    STAs.Queue(i,3) = STAs.Queue(i,3) + length(find(STAs.Overhearing_MAP(i,:) == 0));
                    STAs.Queue(i,2) = find(STAs.Queue_Frame_List(i,:) == -1, 1, 'first' );
                    i; % Debug Condition : STAs.Queue(i,3) ~= length(find(STAs.Queue_Frame_List(i,:) == -1))
                    STAs.Overhearing_MAP(i,find(STAs.Overhearing_MAP(i,:) == 0)) = 1;  % As this statement, STAs try to retransmit just one time.
                    
                end
                
            end
         
             
         end
    
    end
   
    if (Opt_Fixed_Traffic_Volume)
        if ( sum(STAs.MAC_STATE(:, NOW_in_Slots)) )
            IDLE_Period = 0;
        else
            IDLE_Period = IDLE_Period + 1; 
        end
        
        if ( NOW_in_Slots + Opt_Decision_Boundary_for_No_More_TX > Sim_Time_in_Slots)
            STAs.MAC_STATE = [ STAs.MAC_STATE zeros(N_STA,Opt_Decision_Boundary_for_No_More_TX) ];
            STAs.RSSI_Record = [ STAs.RSSI_Record zeros(N_STA,Opt_Decision_Boundary_for_No_More_TX)+NaN ];
            Sim_Time_in_Slots = Sim_Time_in_Slots + Opt_Decision_Boundary_for_No_More_TX;
        end
        
        if( Opt_Decision_Boundary_for_No_More_TX <= IDLE_Period )  % Condition:  No Tx, No Frame who are waiting in the sQueue 
            IDLE_Period
            NOW_in_Slots
            disp('Acutal Ending Time');
            Actual_Ending_Time = (NOW_in_Slots - IDLE_Period)*9*10^-6   % Actual Ending Time
            
            disp('Traffic Volume(Bytes)'); Traffic_Volume
            break;
        end
        
%         STAs.Focused_Frame_Inform(GOD.ID_RX( Error_Decision_Result(GOD.ID_RX) <= 0), 3)
    end
    
    if (Opt_Coloring_On &&  Opt_Coloring_Completion_Time_Measurement)
            if Coloring_Completion_Time(Rep_Index, 1) <= 0 && sum(Target_Color - STAs.Color) == 0
                Coloring_Completion_Time(Rep_Index, 1) = NOW_in_Slots * U_Slot_Time;
                Coloring_Completion_Time(Rep_Index, 2) = NOW_in_Slots;
                %error('Coloring_Completion_Time has measured.');
                %break;
                %return;
            end
            
            if  Coloring_Completion_Time(Rep_Index, 3) <= 0 && isempty(find( (STAs.RGB_STA_MAP == Target_Color_MAP) == 0, 1))
                Coloring_Completion_Time(Rep_Index, 3) = NOW_in_Slots * U_Slot_Time;
                Coloring_Completion_Time(Rep_Index, 4) = NOW_in_Slots;
            end
            
            if Coloring_Completion_Time(Rep_Index, 1) > 0 && Coloring_Completion_Time(Rep_Index, 3) > 0
                break;
            end
    end
    
    if (Opt_Coloring_On  &&  Opt_RED_Retransmission_On)
            
            Candidates_ReTx = Overhearing_Time_Table( Overhearing_Time_Table(:,2) <= NOW_in_Slots,1);
            Candidates_ReTx( Candidates_ReTx == -1) = [];
            if ~isempty(Candidates_ReTx)
                for idx_Candidate_Re_Tx = 1:length(Candidates_ReTx)
                    if (Overhearing_Time_Table( Overhearing_Time_Table(:,1) == Candidates_ReTx(idx_Candidate_Re_Tx),3) <= Num_Retry) ...
                            && (Overhearing_Time_Table( Overhearing_Time_Table(:,1) == Candidates_ReTx(idx_Candidate_Re_Tx),4)  == 0)...
                            && (STAs.Queue_Frame_List(1, Candidates_ReTx(idx_Candidate_Re_Tx)) == -2)
                        STAs.Queue_Frame_List(1, Candidates_ReTx(idx_Candidate_Re_Tx)) = -1;
                        STAs.Queue(1,3) = STAs.Queue(1,3) + 1;
                        STAs.Queue(1,2) = find(STAs.Queue_Frame_List(1,:) == -1, 1, 'first' );
                        % Overhearing_Time_Table( Overhearing_Time_Table(:,1) == Candidates_ReTx,:) = [];   % Eliminating Re-TX Frame Information
                        Overhearing_Time_Table( Overhearing_Time_Table(:,1) == Candidates_ReTx(idx_Candidate_Re_Tx),3) ...
                        = Overhearing_Time_Table( Overhearing_Time_Table(:,1) == Candidates_ReTx(idx_Candidate_Re_Tx),3) + 1;
                    end
                end
            end
            
%             for idx_retry = 2:length(Overhearing_Time_Table(:,1))
%                 
%                 if Overhearing_Time_Table(idx_retry,2)  < NOW_in_Slots
%                     STAs.Queue_Frame_List(1, Overhearing_Time_Table(idx_retry,1)) = -1;
%                     STAs.Queue(1,3) = STAs.Queue(1,3) + 1;
%                     STAs.Queue(1,2) = find(STAs.Queue_Frame_List(1,:) == -1, 1, 'first' );
%                     Overhearing_Time_Table(idx_retry,:) = [];
%                 end
%                 
%             end
    end
    
    NOW_in_Slots = NOW_in_Slots + 1; % forward to a next slot.   
    
    if ( Opt_Time_Interval_Measurement )
        Current_Cummulative_Slots = Current_Cummulative_Slots + 1;
        
        if ( Current_Cummulative_Slots == Time_Interval_for_Measurement_in_Slot )
            Measurement_Sequence = Measurement_Sequence + 1;
            
%             Result_Time_Interval_Measurement(1, Measurement_Sequence)  = length(find(STAs.Queue_Frame_List(2:N_STA,:)==-2))/(N_STA-1); % for RX frame (cummulation)
%             Result_Time_Interval_Measurement(2, Measurement_Sequence)... 
%             = Result_Time_Interval_Measurement(1, Measurement_Sequence) - Result_Time_Interval_Measurement(1, Measurement_Sequence-1) ;% for RX Frame 
%             
%             Result_Time_Interval_Measurement(3, Measurement_Sequence) = length(find(STAs.Queue_Frame_List(2:N_STA,:)==-1))/(N_STA-1); % for TX frame (cummulation)
%             Result_Time_Interval_Measurement(4, Measurement_Sequence)...
%             = Result_Time_Interval_Measurement(3, Measurement_Sequence) - Result_Time_Interval_Measurement(3, Measurement_Sequence-1); % for TX Frame 
%             
%             Result_Time_Interval_Measurement(5, Measurement_Sequence) = length(find(STAs.Queue_Frame_List(1,:)==-2)); % for TX frame of Source STA(cummulation)
%             Result_Time_Interval_Measurement(6, Measurement_Sequence)...
%             = Result_Time_Interval_Measurement(5, Measurement_Sequence) - Result_Time_Interval_Measurement(5, Measurement_Sequence-1); % for TX Frame of Source STA
        
            %Result_Time_Interval_Measurement(1, Measurement_Sequence)  = length(find(STAs.Queue_Frame_List(2:N_STA,:)==-2 | STAs.Queue_Frame_List(2:N_STA,:)==-1 ))/(N_STA-1); % for RX frame (cummulation)
            Result_Time_Interval_Measurement(1, Measurement_Sequence)  = length(find(STAs.Queue_Frame_List(2:N_STA,:) < 0))/(N_STA-1); % for RX frame (cummulation)
            Result_Time_Interval_Measurement(2, Measurement_Sequence)... 
            = Result_Time_Interval_Measurement(1, Measurement_Sequence) - Result_Time_Interval_Measurement(1, Measurement_Sequence-1) ;% for RX Frame(Variation per measurement duration) 
            
            Result_Time_Interval_Measurement(3, Measurement_Sequence) = length(find(STAs.Queue_Frame_List(2:N_STA,:)==-1))/(N_STA-1); % for Current Queue Length
            Result_Time_Interval_Measurement(4, Measurement_Sequence)...
            = Result_Time_Interval_Measurement(3, Measurement_Sequence) - Result_Time_Interval_Measurement(3, Measurement_Sequence-1); % for Current Queue Length(Variation per measurement duration)
            
            Result_Time_Interval_Measurement(7, Measurement_Sequence) = mean(STAs.Queue(2:N_STA,3));
        
            Result_Time_Interval_Measurement(5, Measurement_Sequence) = length(find(STAs.Queue_Frame_List(1,:)==-2)); % for TX frame of Source STA(cummulation)
            Result_Time_Interval_Measurement(6, Measurement_Sequence)...
            = Result_Time_Interval_Measurement(5, Measurement_Sequence) - Result_Time_Interval_Measurement(5, Measurement_Sequence-1); % for TX Frame of Source STA
            
            % Plotting for the number of the duplicated frame
            Result_Time_Interval_Measurement(8, Measurement_Sequence) = mean(STAs.Count_Failure(2:N_STA, 5));
            
            % Plotting for the number of the transmitted frame
            Result_Time_Interval_Measurement(9, Measurement_Sequence) = mean(STAs.Queue(2:N_STA,1));
            
            % To measure performances for Neighbor STAs of a Source STA
            %---------------------------------------------------------------------------------------%
            
            Result_Time_Interval_Measurement_Neighbor(1, Measurement_Sequence)  = length(find(STAs.Queue_Frame_List(ID_Neighbor_STAs_of_Src,:) < 0))/(length(ID_Neighbor_STAs_of_Src)); % for RX frame (cummulation)
            Result_Time_Interval_Measurement_Neighbor(2, Measurement_Sequence)... 
            = Result_Time_Interval_Measurement_Neighbor(1, Measurement_Sequence) - Result_Time_Interval_Measurement_Neighbor(1, Measurement_Sequence-1) ;% for RX Frame(Variation per measurement duration) 
            
            Result_Time_Interval_Measurement_Neighbor(3, Measurement_Sequence) = length(find(STAs.Queue_Frame_List(ID_Neighbor_STAs_of_Src,:)==-1))/(length(ID_Neighbor_STAs_of_Src)); % for Current Queue Length
            Result_Time_Interval_Measurement_Neighbor(4, Measurement_Sequence)...
            = Result_Time_Interval_Measurement_Neighbor(3, Measurement_Sequence) - Result_Time_Interval_Measurement_Neighbor(3, Measurement_Sequence-1); % for Current Queue Length(Variation per measurement duration)
            
            Result_Time_Interval_Measurement_Neighbor(7, Measurement_Sequence) = mean(STAs.Queue(ID_Neighbor_STAs_of_Src,3));
        
%             Result_Time_Interval_Measurement_Neighbor(5, Measurement_Sequence) = length(find(STAs.Queue_Frame_List(1,:)==-2)); % for TX frame of Source STA(cummulation)
%             Result_Time_Interval_Measurement_Neighbor(6, Measurement_Sequence)...
%             = Result_Time_Interval_Measurement_Neighbor(5, Measurement_Sequence) - Result_Time_Interval_Measurement_Neighbor(5, Measurement_Sequence-1); % for TX Frame of Source STA
            
            % Plotting for the number of the duplicated frame
            Result_Time_Interval_Measurement_Neighbor(8, Measurement_Sequence) = mean(STAs.Count_Failure(ID_Neighbor_STAs_of_Src, 5));
            
            % Plotting for the number of the transmitted frame
            Result_Time_Interval_Measurement_Neighbor(9, Measurement_Sequence) = mean(STAs.Queue(ID_Neighbor_STAs_of_Src,1));
            
            
            %---------------------------------------------------------------------------------------%
            
            
            % To measure performances for Other STAs
            %---------------------------------------------------------------------------------------%
            
            Result_Time_Interval_Measurement_Others(1, Measurement_Sequence)  = length(find(STAs.Queue_Frame_List(ID_Others,:) < 0))/(length(ID_Others)); % for RX frame (cummulation)
            Result_Time_Interval_Measurement_Others(2, Measurement_Sequence)... 
            = Result_Time_Interval_Measurement_Others(1, Measurement_Sequence) - Result_Time_Interval_Measurement_Others(1, Measurement_Sequence-1) ;% for RX Frame(Variation per measurement duration) 
            
            Result_Time_Interval_Measurement_Others(3, Measurement_Sequence) = length(find(STAs.Queue_Frame_List(ID_Others,:)==-1))/(length(ID_Others)); % for Current Queue Length
            Result_Time_Interval_Measurement_Others(4, Measurement_Sequence)...
            = Result_Time_Interval_Measurement_Others(3, Measurement_Sequence) - Result_Time_Interval_Measurement_Others(3, Measurement_Sequence-1); % for Current Queue Length(Variation per measurement duration)
            
            Result_Time_Interval_Measurement_Others(7, Measurement_Sequence) = mean(STAs.Queue(ID_Others,3));
        

            % Plotting for the number of the duplicated frame
            Result_Time_Interval_Measurement_Others(8, Measurement_Sequence) = mean(STAs.Count_Failure(ID_Others, 5));
            
            % Plotting for the number of the transmitted frame
            Result_Time_Interval_Measurement_Others(9, Measurement_Sequence) = mean(STAs.Queue(ID_Others,1));
            
            
            %---------------------------------------------------------------------------------------%
            
            if Traffic_Volume*Measurement_Criteria_of_Received_Traffic_Volume(Index_Measurement_Criteria_of_Received_Traffic_Volume(1))...
               <= L_MPDU*Result_Time_Interval_Measurement(1, Measurement_Sequence)
               Measured_Time(1,Index_Measurement_Criteria_of_Received_Traffic_Volume(1)) =  NOW_in_Slots;
               Index_Measurement_Criteria_of_Received_Traffic_Volume(1) = Index_Measurement_Criteria_of_Received_Traffic_Volume(1) + 1;           
            end
            
            if Traffic_Volume*Measurement_Criteria_of_Received_Traffic_Volume(Index_Measurement_Criteria_of_Received_Traffic_Volume(2))...
               <= L_MPDU*Result_Time_Interval_Measurement_Neighbor(1, Measurement_Sequence)
               Measured_Time(2,Index_Measurement_Criteria_of_Received_Traffic_Volume(2)) =  NOW_in_Slots;
               Index_Measurement_Criteria_of_Received_Traffic_Volume(2) = Index_Measurement_Criteria_of_Received_Traffic_Volume(2) + 1;           
            end
            
            if Traffic_Volume*Measurement_Criteria_of_Received_Traffic_Volume(Index_Measurement_Criteria_of_Received_Traffic_Volume(3))...
               <= L_MPDU*Result_Time_Interval_Measurement_Others(1, Measurement_Sequence)
               Measured_Time(3,Index_Measurement_Criteria_of_Received_Traffic_Volume(3)) =  NOW_in_Slots;
               Index_Measurement_Criteria_of_Received_Traffic_Volume(3) = Index_Measurement_Criteria_of_Received_Traffic_Volume(3) + 1;           
            end
            

  
            Current_Cummulative_Slots = 0;
            
        end
        
       
    end

    
    
end 
 
   % STAs.Count_Failure(:,6) = STAs.Count_Failure(:,2) + STAs.Count_Failure(:,5) - STAs.Count_Failure(:,4); % 6-th col is total failed frame
STAs.Count_Failure(:,6) = STAs.Count_Failure(:,2) + STAs.Count_Failure(:,5); % 6-th col is total failed frame
STAs.Count_Failure(:,7) = STAs.Count_Failure(:,1) - STAs.Count_Failure(:,6); % 7-th col is total successful frame.
STAs.Count_Failure(:,8) = STAs.Queue(:,1); % update the number of TX for each STAs
STAs.Count_Failure
disp('[1]Total RX  [2]Failure(CH Error) [3]X [4]Failure(Duplication & CH Error) [5]Failure(Pure Duplication) [6]Total Failure [7]Total Sucess');


N_Shadow_STAs = sum(STAs.Count_Failure(:,7) == 0)-1
% N_TX_Frame_of_Src = STAs.Queue(1,2)-1   % number of frame that sent from source STA
% N_TX_Frame_of_Src = STAs.Queue(1,2)   % number of frame that sent from source STA

X = 1:N_MPDU; 
for i = 1:N_MPDU
        Result_Failure_Reason_for_MPDUs(3,i) = length(find(STAs.Queue_Frame_List(:,i) > 0));
        Result_Failure_Reason_for_MPDUs_Neighbors(3,i) = length(find(STAs.Queue_Frame_List(ID_Neighbor_STAs_of_Src,i) > 0));
        Result_Failure_Reason_for_MPDUs_Others(3,i) = length(find(STAs.Queue_Frame_List(ID_Others,i) > 0));
end
Y1 = Result_Failure_Reason_for_MPDUs(3,:);
Y2 = Result_Failure_Reason_for_MPDUs_Neighbors(3,:);
Y3 = Result_Failure_Reason_for_MPDUs_Others(3,:);

if (Opt_All_Figs_On)
% FIGUER DISABLE 01 -START-
figure;
plot(X, Result_Failure_Reason_for_MPDUs(3,:),'r.');
ylim([1,N_STA-1]);
title('Total');
figure;
plot(X, Result_Failure_Reason_for_MPDUs_Neighbors(3,:),'g.');
ylim([1,N_STA-1]);
title('Neighbor of Source');
figure;
plot(X, Result_Failure_Reason_for_MPDUs_Others(3,:),'b.');
ylim([1,N_STA-1]);
title('Others');
%clear X;

figure;
plot(X, Result_Failure_Reason_for_MPDUs(2,:),'r.');
ylim([1,N_STA-1]);
xlabel('Sequence Number of Frame');ylabel('Number of STAs');
title('Total: Number of STAs who have one and more Rx-attempt from adjacent STAs');

figure;
plot(X, Result_Failure_Reason_for_MPDUs_Neighbors(2,:),'g.');
ylim([1,N_STA-1]);
xlabel('Sequence Number of Frame');ylabel('Number of STAs');
title('Neighbor of Source: Number of STAs who have one and more Rx-attempt from adjacent STAs');

figure;
plot(X, Result_Failure_Reason_for_MPDUs_Others(2,:),'b.');
ylim([1,N_STA-1]);
xlabel('Sequence Number of Frame');ylabel('Number of STAs');
title('Others: Number of STAs who have one and more Rx-attempt from adjacent STAs');
clear X;

figure;
plot(Result_Failure_Reason_for_MPDUs(2,:), N_STA-1-Result_Failure_Reason_for_MPDUs(3,:), 'r.');
ylim([1,N_STA-1]);
title('Total');
xlabel('number of RX attempt');
ylabel('number of STA');

figure;
plot(Result_Failure_Reason_for_MPDUs_Neighbors(2,:), length(ID_Neighbor_STAs_of_Src)-Result_Failure_Reason_for_MPDUs_Neighbors(3,:), 'g.');
ylim([1,N_STA-1]);
title('Neighbor of Source');
xlabel('number of RX attempt');
ylabel('number of STA');

figure;
plot(Result_Failure_Reason_for_MPDUs_Others(2,:), length(ID_Others)-Result_Failure_Reason_for_MPDUs_Others(3,:), 'b.');
ylim([1,N_STA-1]);
title('Others');
xlabel('number of RX attempt');
ylabel('number of STA');

end
% FIGUER DISABLE 01 -END-

% for i = 1:N_STA-1
%     A(i,:) = find(STAs.Queue_Frame_List(i+1,:) > 0);
% end
if ( Opt_Time_Interval_Measurement )
    
%     if(isempty(Actual_Ending_Time))
%         Actual_Ending_Time = NaN
%     end
    
    Result_Avg = sum(STAs.Count_Failure(2:N_STA,:))/(N_STA-1);
    Result_Avg = [ Result_Avg Measured_Time(1,:) Actual_Ending_Time ];

    Result_Avg_Neighbor = sum(STAs.Count_Failure(ID_Neighbor_STAs_of_Src,:))/(length(ID_Neighbor_STAs_of_Src));
    Result_Avg_Neighbor = [ Result_Avg_Neighbor Measured_Time(2,:) Actual_Ending_Time ];

    Result_Avg_Others = sum(STAs.Count_Failure(ID_Others,:))/(length(ID_Others));
    Result_Avg_Others = [ Result_Avg_Others Measured_Time(3,:) Actual_Ending_Time ];
else
%     if(isempty(Actual_Ending_Time))
%         Actual_Ending_Time = NaN
%     end
    
    Result_Avg = sum(STAs.Count_Failure(2:N_STA,:))/(N_STA-1);
%     Result_Avg = [ Result_Avg length(find(STAs.Count_Failure(:,7) == N_MPDU)) Actual_Ending_Time N_1_Hop_Failure N_Other_Failure N_Estimation Num_Src_Retry ];
    Result_Avg = [ Result_Avg ...
                    length(find(STAs.Count_Failure(:,7) == N_MPDU))...
                    length(find(STAs.Count_Failure(:,7) >= N_MPDU*0.99))...
                    length(find(STAs.Count_Failure(:,7) >= N_MPDU*0.95))...
                    length(find(STAs.Count_Failure(:,7) >= N_MPDU*0.90))...
                    Actual_Ending_Time ];
     
    Result_Avg_Neighbor = sum(STAs.Count_Failure(ID_Neighbor_STAs_of_Src,:))/(length(ID_Neighbor_STAs_of_Src));
    Result_Avg_Neighbor = [ Result_Avg_Neighbor length(find(STAs.Count_Failure(ID_Neighbor_STAs_of_Src,7) == N_MPDU)) Actual_Ending_Time ];

    Result_Avg_Others = sum(STAs.Count_Failure(ID_Others,:))/(length(ID_Others));
    Result_Avg_Others = [ Result_Avg_Others length(find(STAs.Count_Failure(ID_Others, 7) == N_MPDU))  Actual_Ending_Time ];
end

if ( Opt_Mode_Discard_Probability > 0)
    ID_Tag_0 = find(STAs.Tag == 0);
    ID_Tag_1 = find(STAs.Tag == 1);
    ID_Tag_0_Neighbor = ID_Neighbor_STAs_of_Src(find(STAs.Tag(ID_Neighbor_STAs_of_Src) == 0));
    ID_Tag_1_Neighbor = ID_Neighbor_STAs_of_Src(find(STAs.Tag(ID_Neighbor_STAs_of_Src) == 1));
    ID_Tag_0_Others = ID_Others(find(STAs.Tag(ID_Others) == 0));
    ID_Tag_1_Others = ID_Others(find(STAs.Tag(ID_Others) == 1));
    
    Result_Avg_Tag_0 = sum(STAs.Count_Failure(ID_Tag_0,:))/(length(ID_Tag_0));
    Result_Avg_Tag_1 = sum(STAs.Count_Failure(ID_Tag_1,:))/(length(ID_Tag_1));
    
    Result_Avg_Tag_0_Neighbor = sum(STAs.Count_Failure(ID_Tag_0_Neighbor,:))/(length(ID_Tag_0_Neighbor));
    Result_Avg_Tag_1_Neighbor = sum(STAs.Count_Failure(ID_Tag_1_Neighbor,:))/(length(ID_Tag_1_Neighbor));
    
    Result_Avg_Tag_0_Others = sum(STAs.Count_Failure(ID_Tag_0_Others,:))/(length(ID_Tag_0_Others));
    Result_Avg_Tag_1_Others = sum(STAs.Count_Failure(ID_Tag_1_Others,:))/(length(ID_Tag_1_Others));
    
end

% N_TX_Frame_of_Src = length(find(STAs.Queue_Frame_List(1,:)==-2)) % N_TX_Frame_of_Src must be same as the result of this line.
N_TX_Frame_of_Src = STAs.Queue(1,3)

% Sorting_Results_by_Num_Neighbors = zeros(length(Array_Num_Neighbors), 9); % compared to 'STAs.Count_Failure', two of colums are added. one is 'the number of neighbors', another is number of STAs for each number of neighbor
% Sorting_Results_by_Num_Neighbors(:,1) = Array_Num_Neighbors;

Sorting_Results_by_Num_Neighbors = zeros(N_STA, 10); % compared to 'STAs.Count_Failure', two of colums are added. one is 'the number of neighbors', another is number of STAs for each number of neighbor
Sorting_Results_by_Num_Neighbors(:,1) = 1:N_STA;


for i = 2:N_STA
   for j = 1:N_STA
       
       if STAs.N_neigbors(i) == j
            Sorting_Results_by_Num_Neighbors(j,2) =  Sorting_Results_by_Num_Neighbors(j,2) + 1;
            Sorting_Results_by_Num_Neighbors(j, 3:10) = Sorting_Results_by_Num_Neighbors(j, 3:10) + STAs.Count_Failure(i,:);
       end
       
   end
    
end

if ( Opt_Time_Interval_Measurement )
% if ( 0 )
    % MOST FIGURE DISABLE -START -
    
    % TOTAL--------------------------------------------------------------------------------------%
    figure;
    X_Axis = (Time_Interval_for_Measurement_in_Slot*U_Slot_Time)*(1:length(Result_Time_Interval_Measurement(1,:)));
%     plot(X_Axis, L_MPDU*Result_Time_Interval_Measurement(1,:), 'r-', X_Axis, L_MPDU*Result_Time_Interval_Measurement(3,:), 'b--', X_Axis, L_MPDU*Result_Time_Interval_Measurement(5,:), 'm-.');
    subplot(1,2,1);
    plot(X_Axis, L_MPDU*Result_Time_Interval_Measurement(1,:), 'r-', X_Axis, L_MPDU*Result_Time_Interval_Measurement(3,:), 'b--', X_Axis, L_MPDU*Result_Time_Interval_Measurement(7,:), 'c--', X_Axis, L_MPDU*Result_Time_Interval_Measurement(5,:), 'm-.', X_Axis, L_MPDU*Result_Time_Interval_Measurement(8,:), 'k--', X_Axis, L_MPDU*Result_Time_Interval_Measurement(9,:), 'b:');
    xlabel('Time(sec)');ylabel('Bytes');%ylabel('Averge number of TX/RX Frame')
    xlim([0 Sim_Time*1.25]);
    ylim([0 Traffic_Volume*1.15]);
    TITLE = [' Total ' 'Prob=' num2str(Probability_List(Rep_Index)) '   ' 'Traffic ' 'Volume=' num2str(Traffic_Volume/10^6), ' MB'];
    title(TITLE);
    grid on;
    hold on
    plot(X_Axis, Traffic_Volume, 'g-');
    stem(Actual_Ending_Time, Traffic_Volume, '*k--');
    hold off;
    
    subplot(1,2,2);
    plot(X_Axis, L_MPDU*Result_Time_Interval_Measurement(1,:), 'r-', X_Axis, L_MPDU*Result_Time_Interval_Measurement(3,:), 'b--', X_Axis, L_MPDU*Result_Time_Interval_Measurement(7,:), 'c--', X_Axis, L_MPDU*Result_Time_Interval_Measurement(5,:), 'm-.', X_Axis, L_MPDU*Result_Time_Interval_Measurement(8,:), 'k--', X_Axis, L_MPDU*Result_Time_Interval_Measurement(9,:), 'b:');
    xlabel('Time(sec)');ylabel('Bytes');%ylabel('Averge number of TX/RX Frame')
    xlim([0 Sim_Time*1.25]);
    ylim([0 Traffic_Volume*10.15]);
    TITLE = [' Total ' 'Prob=' num2str(Probability_List(Rep_Index)) '   ' 'Traffic ' 'Volume=' num2str(Traffic_Volume/10^6), ' MB'];
    title(TITLE);
    grid on;
    hold on
    plot(X_Axis, Traffic_Volume, 'g-');
    stem(Actual_Ending_Time, Traffic_Volume, '*k--');
    
% %     legend('Tx(cummulation)','Queue Length', 'Src-Tx(cummulation)', 'Traffic Volume', 'Actual Ending Time' );
% %     legend('Rx(cummulation)','Current Queue Length', 'Src-Tx(cummulation)', 'Traffic Volume', 'Actual Ending Time' );
    set(gcf,'position',[0.5 0.5 1000 750])
    legend('Rx(cummulation)','Current Queue Length(from Frame List)','Current Queue Length(from Queue List)', 'Src-Tx(cummulation)','Duplicated Traffic(Fail)' , 'Other-TX' , 'Traffic Volume', 'Actual Ending Time', 'Location', 'Best' );
    hold off;
    saveas(gcf,strcat(num2str(Rep_Index), TITLE,'.png'));
    saveas(gcf,strcat(num2str(Rep_Index), TITLE,'.fig'));
%     close;
    %     figure;
%     plot(X_Axis, Result_Time_Interval_Measurement(2,:), 'r-', X_Axis, Result_Time_Interval_Measurement(4,:), 'b--', X_Axis, Result_Time_Interval_Measurement(6,:), 'm-.');
%     xlabel('Time(Sec)');ylabel('Averge number of TX/RX Frame')%ylabel('Bytes');%ylabel('Averge number of TX/RX Frame')
%     legend('Tx','Queue Length', 'Src-Tx');
%     hold on
%     %stem(Actual_Ending_Time, max(L_MPDU*Result_Time_Interval_Measurement(1,:))*0.1, '*k--');
%     legend('Actual Ending Time');
%     hold off;
    
    %-----------------------------------------------------------------------------------------%
    % Neighbors-------------------------------------------------------------------------------%
    figure;
    subplot(1,2,1);
% X_Axis = (Time_Interval_for_Measurement_in_Slot*U_Slot_Time)*(1:length(Result_Time_Interval_Measurement(1,:)));
%     plot(X_Axis, L_MPDU*Result_Time_Interval_Measurement(1,:), 'r-', X_Axis, L_MPDU*Result_Time_Interval_Measurement(3,:), 'b--', X_Axis, L_MPDU*Result_Time_Interval_Measurement(5,:), 'm-.');
    plot(X_Axis, L_MPDU*Result_Time_Interval_Measurement_Neighbor(1,:), 'r-', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Neighbor(3,:), 'b--', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Neighbor(7,:), 'c--', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Neighbor(5,:), 'm-.', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Neighbor(8,:), 'k--', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Neighbor(9,:), 'b:');
    xlabel('Time(sec)');ylabel('Bytes');%ylabel('Averge number of TX/RX Frame')
    xlim([0 Sim_Time*1.25]);
    ylim([0 Traffic_Volume*1.15]);
    TITLE = [' Neighbors' 'Prob=' num2str(Probability_List(Rep_Index)) '   ' 'Traffic ' 'Volume=' num2str(Traffic_Volume/10^6), ' MB'];
    title(TITLE);
    grid on;
    hold on
    plot(X_Axis, Traffic_Volume, 'g-');
    stem(Actual_Ending_Time, Traffic_Volume, '*k--');
% %     legend('Tx(cummulation)','Queue Length', 'Src-Tx(cummulation)', 'Traffic Volume', 'Actual Ending Time' );
% %     legend('Rx(cummulation)','Current Queue Length', 'Src-Tx(cummulation)', 'Traffic Volume', 'Actual Ending Time' );
   
    hold off;
    subplot(1,2,2);
    plot(X_Axis, L_MPDU*Result_Time_Interval_Measurement_Neighbor(1,:), 'r-', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Neighbor(3,:), 'b--', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Neighbor(7,:), 'c--', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Neighbor(5,:), 'm-.', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Neighbor(8,:), 'k--', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Neighbor(9,:), 'b:');
    xlabel('Time(sec)');ylabel('Bytes');%ylabel('Averge number of TX/RX Frame')
    xlim([0 Sim_Time*1.25]);
    ylim([0 Traffic_Volume*10.15]);
    TITLE = [' Neighbors' 'Prob=' num2str(Probability_List(Rep_Index)) '   ' 'Traffic ' 'Volume=' num2str(Traffic_Volume/10^6), ' MB'];
    title(TITLE);
    grid on;
    hold on
    plot(X_Axis, Traffic_Volume, 'g-');
    stem(Actual_Ending_Time, Traffic_Volume, '*k--');
    
    set(gcf,'position',[0.5 0.5 1000 750])
    legend('Rx(cummulation)','Current Queue Length(from Frame List)','Current Queue Length(from Queue List)', 'Src-Tx(cummulation)','Duplicated Traffic(Fail)' , 'Other-TX' , 'Traffic Volume', 'Actual Ending Time', 'Location', 'Best' );
    hold off;
        
    saveas(gcf,strcat(num2str(Rep_Index), TITLE,'.png'));
    saveas(gcf,strcat(num2str(Rep_Index), TITLE,'.fig'));
%     close;
    
    %-----------------------------------------------------------------------------------------%
    % Others-------------------------------------------------------------------------------%
    
    figure;
% X_Axis = (Time_Interval_for_Measurement_in_Slot*U_Slot_Time)*(1:length(Result_Time_Interval_Measurement(1,:)));
%     plot(X_Axis, L_MPDU*Result_Time_Interval_Measurement(1,:), 'r-', X_Axis, L_MPDU*Result_Time_Interval_Measurement(3,:), 'b--', X_Axis, L_MPDU*Result_Time_Interval_Measurement(5,:), 'm-.');
    subplot(1,2,1);
    plot(X_Axis, L_MPDU*Result_Time_Interval_Measurement_Others(1,:), 'r-', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Others(3,:), 'b--', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Others(7,:), 'c--', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Others(5,:), 'm-.', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Others(8,:), 'k--', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Others(9,:), 'b:');
    xlabel('Time(sec)');ylabel('Bytes');%ylabel('Averge number of TX/RX Frame')
    xlim([0 Sim_Time*1.25]);
    ylim([0 Traffic_Volume*1.15]);
    TITLE = [' Others' 'Prob=' num2str(Probability_List(Rep_Index)) '   ' 'Traffic ' 'Volume=' num2str(Traffic_Volume/10^6), ' MB'];
    title(TITLE);
    grid on;
    hold on
    plot(X_Axis, Traffic_Volume, 'g-');
    stem(Actual_Ending_Time, Traffic_Volume, '*k--');
% %     legend('Tx(cummulation)','Queue Length', 'Src-Tx(cummulation)', 'Traffic Volume', 'Actual Ending Time' );
% %     legend('Rx(cummulation)','Current Queue Length', 'Src-Tx(cummulation)', 'Traffic Volume', 'Actual Ending Time' );
    
    hold off;
    subplot(1,2,2);
    plot(X_Axis, L_MPDU*Result_Time_Interval_Measurement_Others(1,:), 'r-', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Others(3,:), 'b--', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Others(7,:), 'c--', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Others(5,:), 'm-.', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Others(8,:), 'k--', X_Axis, L_MPDU*Result_Time_Interval_Measurement_Others(9,:), 'b:');
    xlabel('Time(sec)');ylabel('Bytes');%ylabel('Averge number of TX/RX Frame')
    xlim([0 Sim_Time*1.25]);
    ylim([0 Traffic_Volume*10.15]);
    TITLE = [' Others' 'Prob=' num2str(Probability_List(Rep_Index)) '   ' 'Traffic ' 'Volume=' num2str(Traffic_Volume/10^6), ' MB'];
    title(TITLE);
    grid on;
    hold on
    plot(X_Axis, Traffic_Volume, 'g-');
    stem(Actual_Ending_Time, Traffic_Volume, '*k--');
    
    set(gcf,'position',[0.5 0.5 1000 750])
    legend('Rx(cummulation)','Current Queue Length(from Frame List)','Current Queue Length(from Queue List)', 'Src-Tx(cummulation)','Duplicated Traffic(Fail)' , 'Other-TX' , 'Traffic Volume', 'Actual Ending Time', 'Location', 'Best' );
    hold off;
    
    saveas(gcf,strcat(num2str(Rep_Index), TITLE,'.png'));
    saveas(gcf,strcat(num2str(Rep_Index), TITLE,'.fig'));
%     close;
    
    % figure;
% plot(STAs.Count_Failure(ID_Neighbor_STAs_of_Src,7),'r*');ylim([0 12000])
% hold on;
% plot(STAs.Count_Failure(ID_Others,7),'b+');ylim([0 12000]);
% hold on;
% legend('Neighbor of Src', 'Others')
% xlabel('STA ID');ylabel('Number of Received Frame');
% hold off;

%     figure;
%     colors = [1 0 0; 0 0 1; 0 0.5 0;]; 
%     C  = [ STAs.Count_Failure(ID_Neighbor_STAs_of_Src,7), STAs.Count_Failure(ID_Others,7)];
%     G = [zeros(1, length(ID_Neighbor_STAs_of_Src)), ones(1, length(ID_Others))];
%     boxplot(C,G, 'Colors',colors, 'labels',{'Neighbor of Src','Others'});
%     ylabel('Number of Received Frame');
%     saveas(gcf,strcat(' box_plot ', num2str(Rep_Index), TITLE,'.png'));
%     saveas(gcf,strcat(' box_plot ', num2str(Rep_Index), TITLE,'.fig'));
%     close;
% findall is used to find all the graphics objects with tag "box", i.e. the box plot
%hLegend = legend(findall(gca,'Tag','Box'), {'Group A','Group B'});

% MOST FIGURE DISABLE -END -

end

% if length(Sim_Result_Type_1) > length(Result_Avg)
% 
% elseif length(Sim_Result_Type_1) < length(Result_Avg)
%     
% end

if (Opt_Measurement_Duplication)
%     Measurement_Duplication( Measurement_Duplication == -1 ) = [];
%     Measurement_Duplication_ratio( Measurement_Duplication_ratio == -1 ) = [];
    for idx_Measurement_Duplication = 1: N_STA
        Measurement_Duplication_Summary(idx_Measurement_Duplication,1) ...
            = sum(Measurement_Duplication(idx_Measurement_Duplication,1:find(Measurement_Duplication(idx_Measurement_Duplication,:) == -1,1,'first')-1));
        Measurement_Duplication_Summary(idx_Measurement_Duplication,2) ...
            = mean(Measurement_Duplication(idx_Measurement_Duplication,1:find(Measurement_Duplication(idx_Measurement_Duplication,:) == -1,1,'first')-1));
        Measurement_Duplication_Summary(idx_Measurement_Duplication,3) ...
            = mean(Measurement_Duplication_ratio(idx_Measurement_Duplication,1:find(Measurement_Duplication_ratio(idx_Measurement_Duplication,:) == -1,1,'first')-1));
        Measurement_Duplication_Summary(idx_Measurement_Duplication,4) ...
            = length(find(Measurement_Duplication_ratio(idx_Measurement_Duplication,1:find(Measurement_Duplication_ratio(idx_Measurement_Duplication,:) == -1,1,'first')-1)== 1));
       % Measurement_Duplication_Summary(idx_Measurement_Duplication,5) ...
       %     = Measurement_Duplication_Summary(idx_Measurement_Duplication,4) /length(1:find(Measurement_Duplication_ratio(idx_Measurement_Duplication,:) == -1,1,'first')-1);
    end
    
    figure;
    bar(Measurement_Duplication_Summary(:,4))
    xlabel('Node #');
    ylabel('number of pure duplication');
    
    figure;
    plot(reshape(Measurement_Duplication_per_Frame_RX,1,numel(Measurement_Duplication_per_Frame_RX)), ... 
        reshape(Measurement_Duplication_per_Frame_TX,1,numel(Measurement_Duplication_per_Frame_TX)), ...
        'rx');
    ylim([0 1]);
    xlabel('number of duplication');
    ylabel('ratio');
    
    figure;
    plot(reshape(STAs.Overhearing_Count_Frame,1,numel(STAs.Overhearing_Count_Frame)), ... 
        reshape(Measurement_Duplication_per_Frame_TX,1,numel(Measurement_Duplication_per_Frame_TX)), ...
        'rx');
    
    figure;  % number of sample for each duplication-level(count)
    Filtered_Result_Dupl = [ reshape(Measurement_Duplication_per_Frame_RX,1,numel(Measurement_Duplication_per_Frame_RX)); ...
                            reshape(Measurement_Duplication_per_Frame_TX,1,numel(Measurement_Duplication_per_Frame_TX))];
%     Temp_Filtered_Result_Dupl = Filtered_Result_Dupl;
%     Temp_Filtered_Result_Dupl( :, Temp_Filtered_Result_Dupl(2,:) < 1) = [];  % ?
    Filtered_Result_Dupl( :, Filtered_Result_Dupl(2,:) < 1) = [];  % ?
    hold on;
    for idx_filter_dupl = 1: max(Filtered_Result_Dupl(1,:))
        plot(idx_filter_dupl, length(find(Filtered_Result_Dupl(1,:) == idx_filter_dupl)),'ro');
    end
    hold off;
    
    figure;
    hold on;
    Pure_Duplication_Event_Ratio = zeros(max(Filtered_Result_Dupl(1,:)), 2); 
    for idx_filter_dupl = 1: max(Filtered_Result_Dupl(1,:))
        plot(idx_filter_dupl, ...
            length(find(Filtered_Result_Dupl(1,:) == idx_filter_dupl)) ... 
            /length(find(reshape(Measurement_Duplication_per_Frame_RX,1,numel(Measurement_Duplication_per_Frame_RX)) == idx_filter_dupl)), ...
            'bx-');
        
        Pure_Duplication_Event_Ratio(idx_filter_dupl,1) ...
            = length(find(Filtered_Result_Dupl(1,:) == idx_filter_dupl)) ... 
            / length(find(reshape(Measurement_Duplication_per_Frame_RX,1,numel(Measurement_Duplication_per_Frame_RX)) == idx_filter_dupl));
        Pure_Duplication_Event_Ratio(idx_filter_dupl,2) = idx_filter_dupl; 
    end
    xlabel('number of duplication');
    ylabel('ratio');
    hold off;
    
    figure;
    plot(Measurement_Duplication_per_Frame_RX(3,:), Measurement_Duplication_per_Frame_TX(3,:),'bx');
    
end

Sim_Result_Type_1(Rep_Index, :) = [Seed_List(Rep_Index) Result_Avg] ;
% Sim_Result_Type_1_Neighbor(Rep_Index, :) = Result_Avg_Neighbor;
% Sim_Result_Type_1_Others(Rep_Index, :) = Result_Avg_Others;
filename = strcat(pwd, '\', Simulation_ID, '\', 'Sim_Result_Type_1.mat');
% save('Sim_Result_Type_1.mat', 'Sim_Result_Type_1');
save(filename, 'Sim_Result_Type_1');
    

Sim_Result_Type_2((N_STA*Rep_Index-N_STA+1):N_STA*Rep_Index, :) = Sorting_Results_by_Num_Neighbors;

% Post-Processing
Result_Failure_Reason_for_MPDUs(3,:) = N_STA-1-Result_Failure_Reason_for_MPDUs(3,:);
Result_Failure_Reason_for_MPDUs(1,:) = Result_Failure_Reason_for_MPDUs(1,:)./Result_Failure_Reason_for_MPDUs(3,:); 
% min_index = min(Result_Failure_Reason_for_MPDUs(2,:)); % for scaling
% max(Result_Failure_Reason_for_MPDUs(2,:)); % for scaling
% Index_N_RX_Attempt = unique(Result_Failure_Reason_for_MPDUs(2,:)); % for scaling

% for ii = 1 :length(Result_Failure_Reason_for_MPDUs(3,:))
%     if Result_Failure_Reason_for_MPDUs(2,ii) == 0
%         continue;
%     end
%     Sim_Result_Type_3(1, Result_Failure_Reason_for_MPDUs(2, ii)) = Sim_Result_Type_3(1, Result_Failure_Reason_for_MPDUs(2,ii)) + 1;
%     Sim_Result_Type_3(2, Result_Failure_Reason_for_MPDUs(2,ii)) = Sim_Result_Type_3(2, Result_Failure_Reason_for_MPDUs(2,ii)) + Result_Failure_Reason_for_MPDUs(3,ii);
% end
% 
% Sim_Reuslt_Type_4(Rep_Index, :) = Result_Failure_Reason_for_MPDUs(2,:);
% 
% %Sim_Result_Type_160204(Rep_Index, :) = [ Seed_List(Rep_Index) length(find(STAs.Tag == 0)) length(find(STAs.Tag == 1)) Result_Avg(7) Result_Avg_Neighbor(7) Result_Avg_Others(7) Result_Avg_Tag_0(7) Result_Avg_Tag_1(7) Result_Avg_Tag_0_Neighbor(7) Result_Avg_Tag_1_Neighbor(7) Result_Avg_Tag_0_Others(7) Result_Avg_Tag_1_Others(7) Actual_Ending_Time ];
% % Sim_Result_Type_160205(Rep_Index, :) = [ Seed_List(Rep_Index) N_TX_Frame_of_Src Result_Avg(7) Result_Avg_Neighbor(7) Result_Avg_Others(7) Actual_Ending_Time ];
%         
% Sim_Result_Type_3(3,:) = Sim_Result_Type_3(2,:)./Sim_Result_Type_3(1,:); % to get average.
% Sim_Result_Type_3(4,:) = Sim_Result_Type_3(3,:)./(N_STA-1); % to get average.
% Sim_Result_Type_3(5,:) = 1:length(Sim_Result_Type_3(3,:));
% 
% Sim_Result_Type_3(:,find(isnan(Sim_Result_Type_3(3,:)))) = [];
% if (Rep_Index == 1)
% Sim_Reuslt_Type_5_1(1,:) = Sim_Result_Type_3(5,:);
% Sim_Reuslt_Type_5_1(2,:) = Sim_Result_Type_3(4,:);
% end
% 
% if (Rep_Index == 2)
% Sim_Reuslt_Type_5_2(1,:) = Sim_Result_Type_3(5,:);
% Sim_Reuslt_Type_5_2(2,:) = Sim_Result_Type_3(4,:);
% end
% 
% if (Rep_Index == 3)
% Sim_Reuslt_Type_5_3(1,:) = Sim_Result_Type_3(5,:);
% Sim_Reuslt_Type_5_3(2,:) = Sim_Result_Type_3(4,:);
% end
% clear Sim_Reuslt_Type_3;
% close all

if (Opt_Building_Pruning_Table)
   if ( sum(STAs.Count_Failure(2:N_STA,7) == 0) == 0 )  % To check there exists any isolated nodes.
%     Get_Pruning_Probability_Table_2( N_STA, Measurement_Duplication_per_Frame_RX, Measurement_Duplication_per_Frame_TX, Seed_List(Rep_Index));
    Get_Pruning_Probability_Table_3( N_STA, Measurement_Duplication_per_Frame_RX, Measurement_Duplication_per_Frame_TX, Seed_List(Rep_Index), Simulation_ID);
   end
end

figure;
plot(STAs.pos_x, STAs.pos_y, 'bo');
xlabel('X-axis');ylabel('Y-axis');
hold on;

for i = 1 : N_STA
    text(STAs.pos_x(i)+3, STAs.pos_y(i)+3, num2str(STAs.Count_Failure(i,8)), 'Color', [1 0 0] );
    text(STAs.pos_x(i)-3, STAs.pos_y(i)-3, num2str(STAs.Count_Failure(i,7)), 'Color', [0 0 0] );
end

% Bellow statements are procedure to draw the coverage of a source STA based on CSTh and TX_Power.

% END of Drawing Coverage %
theta = 0:0.01:2*pi;
r = 1:0.01:300;
% r2 = 1:0.01:300;
for i=1:length(r)
    if Path_Loss(0,0,0,r(i), 10) <= STAs.CsTh(1)
        break;
    end
end
r = r(i);
r2 = r*2;
Circle_X = r*cos(theta) +STAs.pos_x(1);
Circle_Y = r*sin(theta) +STAs.pos_y(1);
Circle_X2 = r2*cos(theta) +STAs.pos_x(1);
Circle_Y2 = r2*sin(theta) +STAs.pos_y(1);
plot(Circle_X, Circle_Y,'k--', Circle_X2, Circle_Y2,'k--');
clear theta r r2 Circle_X Circle_Y Circle_X2 Circle_Y2;

if (Opt_Measure_Failure_MAP_Generation)   % Failure MAP Generation
    Save_Path =  strcat(pwd,'\',datestr(date),'_',num2str(round(rand*100000)));
    mkdir(Save_Path);
    for i = 1 :length(STAs.Queue_Frame_List)
        if sum( STAs.Queue_Frame_List(:,i) > 0 )
            Frame_Failure_MAP_Gen( i, STAs.Queue_Frame_List, STAs.pos_x, STAs.pos_y, STAs.CsTh(1), Save_Path )
        end
    end
end


Rep_Index
if (On_Save_STAs_Info)
    filename = strcat(pwd, '\', Simulation_ID, '\', 'Info_', num2str(N_STA), '_STAs_', num2str(Seed_List(Rep_Index)),'.mat');
    
%     filename = strcat('Info_', num2str(N_STA), '_STAs_', num2str(Seed_List(Rep_Index)),'.mat');
    save(filename, 'STAs','-v7.3');
end
clear STAs;
% if Rep_Index == 1
%     R1 = [STAs.N_neigbors(2:N_STA)' STAs.Count_Failure(2:N_STA,7) ];
%     R1_N(:,1) = R1(1:Num_of_STAs/2,1);
%     R1_N(:,2) = R1(1:Num_of_STAs/2,2);
%     R1_O(:,1) = R1(Num_of_STAs/2+1:Num_of_STAs,1);
%     R1_O(:,2) = R1(Num_of_STAs/2+1:Num_of_STAs,2);
% elseif Rep_Index == 2
%     R2 = [ STAs.N_neigbors(2:N_STA)' STAs.Count_Failure(2:N_STA,7)];
%     R2_N(:,1) = R2(1:Num_of_STAs/2,1);
%     R2_N(:,2) = R2(1:Num_of_STAs/2,2);
%     R2_O(:,1) = R2(Num_of_STAs/2+1:Num_of_STAs,1);
%     R2_O(:,2) = R2(Num_of_STAs/2+1:Num_of_STAs,2);
% elseif Rep_Index == 3
%     R3 = [STAs.N_neigbors(2:N_STA)' STAs.Count_Failure(2:N_STA,7)];
%     R3_N(:,1) = R3(1:Num_of_STAs/2,1);
%     R3_N(:,2) = R3(1:Num_of_STAs/2,2);
%     R3_O(:,1) = R3(Num_of_STAs/2+1:Num_of_STAs,1);
%     R3_O(:,2) = R3(Num_of_STAs/2+1:Num_of_STAs,2);
% end

end

% Disabled '17.07.07 START -------------------------------------------------------------%
% Sim_Result_Type_3(3,:) = Sim_Result_Type_3(2,:)./Sim_Result_Type_3(1,:); % to get average.
% Sim_Result_Type_3(4,:) = Sim_Result_Type_3(3,:)./(N_STA-1); % to get average.
% Sim_Result_Type_3(5,:) = 1:length(Sim_Result_Type_3(3,:));
% 
% Sim_Result_Type_3(:,find(isnan(Sim_Result_Type_3(3,:)))) = [];
% Disabled '17.07.07 END----------------------------------------------------------------%

%                     if ( Opt_Self_Pruning_On || Opt_Hybrid_On )
%                         cdf_end_of_sim = STAs.Overhearing_Count_Frame(:);
%                         cdf_tx_time = STAs.Overhearing_Count_Frame_at_TX_Time(:);
%                         figure;
%                         h1= cdfplot(cdf_end_of_sim);
%                         hold on;
%                         h2= cdfplot(cdf_tx_time);
%                         set(h1, 'Color', 'r'); set(h1,'LineWidth', 1.5); 
%                         set(h2, 'Color','b'); set(h2,'LineWidth', 2.0); set(h2,'LineStyle', '--');
%                         grid on;
%                         xlabel('number of overheared frame');
%                         ylabel('Cummulative distribution');
%                         legend('At end of sim', 'At tx time', 'Location', 'SouthEast');   
%                         ylim([0 1.05]);
%                         hold off;
%                     end

% figure;
% plot(Sim_Result_Type_3(5,:), Sim_Result_Type_3(4,:),'ro');
% hold on;
% figure;
% [f, xi] = ksdensity(Result_Failure_Reason_for_MPDUs(2,:), 'width', 0.55);
% [hAx, hLine1, hLine2] = plotyy([Sim_Result_Type_3(5,:)], [Sim_Result_Type_3(4,:)],[xi],[f]);
% % set(hLine1, 'Marker', 'o');
% set(hLine1, 'LineStyle', '-');
% set(hLine2, 'LineStyle', '-.');
% 
% figure;
% for i = 1:Rep_Index
%     [f(i,:), xi(i,:)] = ksdensity(Sim_Reuslt_Type_4(i,:), 'width', 0.5);
% end
% 
% plot(xi(1,:),f(1,:),'r-', xi(2,:),f(2,:),'b-', xi(3,:),f(3,:),'k-', Sim_Reuslt_Type_5_1(1,:), Sim_Reuslt_Type_5_1(2,:),'rs', Sim_Reuslt_Type_5_2(1,:), Sim_Reuslt_Type_5_2(2,:),'bd', Sim_Reuslt_Type_5_3(1,:), Sim_Reuslt_Type_5_3(2,:),'ko'); 
% legend('1.0','0.8','0.1', '1.0','0.8','0.1');
% xlabel('각 프레임의 전달 횟수');
% ylabel('전달 횟수에 대한 kspdf 또는 성공률');
% %xlim([0 N_STA]);
% grid on;


% figure;
% h(1) = cdfplot(Sim_Reuslt_Type_4(1,:));
% hold on;
% h(2) = cdfplot(Sim_Reuslt_Type_4(2,:));
% h(3) = cdfplot(Sim_Reuslt_Type_4(3,:));
% plot(Sim_Reuslt_Type_5_1(1,:), Sim_Reuslt_Type_5_1(2,:),'ro', 'MarkerSize', 10); 
% plot(Sim_Reuslt_Type_5_2(1,:), Sim_Reuslt_Type_5_2(2,:),'bx', 'MarkerSize', 10);
% plot(Sim_Reuslt_Type_5_3(1,:), Sim_Reuslt_Type_5_3(2,:),'ks', 'MarkerSize', 7); 
% set(h(1), 'Color', 'r', 'LineWidth', 1.5);
% set(h(2), 'Color', 'b', 'LineWidth', 1.5);
% set(h(3), 'Color', 'k', 'LineWidth', 1.5);
% ylim([-0.05 1.05])
% xlabel('각 프레임의 전달 횟수');
% ylabel('전달 횟수에 대한 cdf 또는 성공률');
% title('');
% hold off;
% grid on;
% legend('1.0','0.8','0.1', '1.0','0.8','0.1');


% beep;
% pause(0.75);
% beep;
% pause(0.75);
% beep;
% pause(0.75);
% beep;
% pause(0.75);
% beep;

% R1_N = Array_Integration(R1_N);
% R1_O = Array_Integration(R1_O);
% R2_N = Array_Integration(R2_N);
% R2_O = Array_Integration(R2_O);
% R3_N = Array_Integration(R3_N);
% R3_O = Array_Integration(R3_O);
% 
% figure;
% h(1) = cdfplot(R1_N(:,1))
% set(h(1), 'Color', 'r', 'LineWidth', 1.5);
% hold on
% h(2) = cdfplot(R1_O(:,1))
% set(h(2), 'Color', 'b', 'LineWidth', 1.5);
% % plot(R1(1:Num_of_STAs/2,1),R1(1:Num_of_STAs/2,2)/N_MPDU,'ro', R1(Num_of_STAs/2+1:Num_of_STAs,1),R1(Num_of_STAs/2+1:Num_of_STAs,2)/N_MPDU,'bo');
% plot(R1_N(:,1),R1_N(:,4)/N_MPDU,'ro', R1_O(:,1),R1_O(:,4)/N_MPDU,'bo');
% 
% h(3) = cdfplot(R2_N(:,1))
% set(h(3), 'Color', 'r', 'LineWidth', 1.5);
% h(4) = cdfplot(R2_O(:,1))
% set(h(4), 'Color', 'b', 'LineWidth', 1.5);
% % plot(R2(1:Num_of_STAs/2,1),R2(1:Num_of_STAs/2,2)/N_MPDU,'rs', R2(Num_of_STAs/2+1:Num_of_STAs,1),R2(Num_of_STAs/2+1:Num_of_STAs,2)/N_MPDU,'bs')
% plot(R2_N(:,1),R2_N(:,4)/N_MPDU,'rs', R2_O(:,1),R2_O(:,4)/N_MPDU,'bs');
% 
% h(5) = cdfplot(R3_N(:,1))
% set(h(5), 'Color', 'r', 'LineWidth', 1.5);
% h(6) = cdfplot(R3_O(:,1))
% set(h(6), 'Color', 'b', 'LineWidth', 1.5);
% % plot(R3(1:Num_of_STAs/2,1),R3(1:Num_of_STAs/2,2)/N_MPDU,'rd', R3(Num_of_STAs/2+1:Num_of_STAs,1),R3(Num_of_STAs/2+1:Num_of_STAs,2)/N_MPDU,'bd')
% plot(R3_N(:,1),R3_N(:,4)/N_MPDU,'rd', R3_O(:,1),R3_O(:,4)/N_MPDU,'bd');
% 
% legend('Neighbor(0.1)','Other(0.1)', 'N(0.1)', 'O(0.1)', 'Neighbor(0.3)','Other(0.3)', 'N(0.3)', 'O(0.3)', 'Neighbor(0.6)','Other(0.6)', 'N(0.6)', 'O(0.6)','Location','NorthEastOutside')
% % for ii = 1:Num_of_STAs/2
% %     if R1_N(ii,1) 
% %     R1_O
% %     R2_N
% %     R2_O
% %     R3_N
% %     R3_O
% % end







toc;
[Y1, FS]=audioread('Overwatch Soundtracks - Victory Theme_1.mp3',[1 Inf]);
sound(Y1, FS)
pause(7.0);
[Y2, FS2]=audioread('Macree.mp3',[1 Inf]);
sound(5*Y2, FS2)

N_STA
Probability_List
Opt_Simple_Flooding_Probabilty_Mode_Discard 
% The both bellow options are not allowed to enable.
Opt_Src_Retransmission_Mode
Opt_Coloring_On
datestr(now)