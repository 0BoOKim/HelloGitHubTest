function [ STAs ] = Initialization_STA( Num_STAs, Num_MPDU, Packet_Length, Target_Coverage, CW, L_Rec, Simple_Flooding_Probabilty)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
Num_STAs = Num_STAs + 1; % for a Source STA
STAs.pos_x = zeros(1, Num_STAs);
STAs.pos_y = zeros(1, Num_STAs);
% STAs.RSSI = zeros(1, Num_STAs); % Now, it is used to gather RSSI information from adjacent STAs.
% STAs.mW = zeros(1, Num_STAs); % not used
% STAs.Idx_Group = zeros(1, Num_STAs);
STAs.CW = CW*ones(1, Num_STAs);
STAs.bc = ceil( STAs.CW.*rand(1, Num_STAs) )+1;
% STAs.Time = zeros(1, Num_STAs); % not used
STAs.MAC_STATE = zeros(Num_STAs, L_Rec);  % 0:IDLE Odd #:TX  Even #:RX
STAs.CsTh = -82*ones(1, Num_STAs);      % dBm, default value: -82 dBm
STAs.TX_Power = 10*ones(1, Num_STAs);   % dBm, default value:  10 dBm
% STAs.CW_min = zeros(1, Num_STAs); % not used
STAs.DIFS = 3*ones(1,Num_STAs);

% STAs.Queue_Type = zeros(L_Queue, Num_STAs);   % whta kind of type packet is in the queue. i.e.,) RTS(1) or DATA frame(2)
% above statement is substitued to bellow 2 statements. 
% % % STAs.Queue = Num_MPDU*ones(1, Num_STAs);  % length of queue ( the number of packets in the queue of each STA )


% STAs.Queue_Pkt_Size = Packet_Length*ones(1, Num_STAs);  % length of each packet in queue  ( not used yet )
% STAs.Queue_TXnRX_Time = zeros(2, Num_MPDU);  % #1 col is for TX time, #2 col is for RX time ( not used yet )
% STAs.Queue_RX_Time = zeros(L_Queue, Num_STAs);

STAs.ID = 1:Num_STAs;
STAs.Queue = zeros(Num_STAs, 3); % 1st col: # of Transmitted frames, 2nd col: Sequence_ID of frame to send  3rd col: Current Queue Length (buffer overflow is not considered yet)
STAs.RGB = zeros(Num_STAs, 3);  % 1-col: # of Red-Neighbor STAs, 2-col: # of Green-Neighbor STAs, 3-col: # of Blue-Neighbor STAs
STAs.RGB_STA_MAP = zeros(Num_STAs, Num_STAs);  % 1-col: # of Red-Neighbor STAs, 2-col: # of Green-Neighbor STAs, 3-col: # of Blue-Neighbor STAs
STAs.Color = 2*ones(Num_STAs,1); % Color, 0: RED, 1: GREEN, 2: BLUE(default value)

STAs.RSSI_Record = zeros(Num_STAs, L_Rec);
STAs.RSSI_Record(STAs.RSSI_Record == 0) = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  FRAME STRUCTURE -START-                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RX-frame structure %
STAs.Focused_Frame_Inform = zeros(Num_STAs, 12); 
% 1st col: TX_ID
% 2nd col: Frame Length
% 3rd col : slot errorr count
% 4th col : RSSI
% 5th col: Frame Type: Full Frame(0), Partial Frame(1)
% 6th col: Sequence ID
% 7th col : Frame length for partial frame(to preserve)
% 8th col : Color, 0: RED, 1: GREEN, 2: BLUE
% 9~11th col: Its neighbor color information(i.e., number of neighbors for each color) 
% 12th col: Frame Type: non-protected(-1), Protected(-3)

% Bellows are no used longer for RX-Frame structure
% 12th col: Feedback is included? 0: no, 1: yes
% 13th col: Feedback : seq #
% 14th col: Feedback : destination


% TX-frame structure %
STAs.TX_Frame_Inform = zeros(Num_STAs, 8);      
% 1st col: Frame Type(0: None, 1: Data, 2: RTS)  
% 2nd col: remained TX_Time(in slot)  
% 3rd col: Sequence ID
% 4th col: Its own Color, 0: RED, 1: GREEN, 2: BLUE
% 5~7th col: Its neighbor color information(i.e., number of neighbors for each color) 
% 8th col: Frame Type: non-protected(-1), Protected(-3)

% Bellows are no used longer for TX-Frame structure 
% 8th col: Feedback is required? 0: no, 1: yes
% 9th col: Feedback : seq #
% 10th col: Feedback : destination(X), it dosen't need to build in TX frame.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  FRAME STRUCTURE -END-                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% When Opt_Simple_Pruning_Probability_Adaptation_Scheme is enable,
% STAs.Table_Feedback =  zeros(Num_STAs, Num_STAs); 



% STAs.RX_Frame_ID = zeros(Num_STAs, 1);
STAs.Group = zeros(Num_STAs, 3); % 1st col: near(0) or far(1), 2nd col: Many(0), few(1), 3rd col : Group#0(00), Group#1(01), Group#2(10), Group#3(11)
STAs.N_neigbors = zeros(Num_STAs, 1);
% STAs.Queue_Frame_List = zeros(Num_MPDU, Num_STAs);
STAs.Queue_Frame_List = meshgrid(1:Num_MPDU, 1: Num_STAs);  
% -2: leaved, 
% -1: Queued,  
% >0: Not received yet(its seq ID). 
% -4: discarding bt pruning schemes
% -3: Queued frame to retransmit(this frame is not allowed to discard by pruning schemes to gurantee retranmsission.

% The following record format records the route (i.e., the TX node) that has received a specific frame of each node.
STAs.Record_TX_Node_ID = zeros(Num_STAs, Num_MPDU)-1;  % -1: Not received yet. any Node ID: its TX NODEs.

%STAs.Frame_Error = zeros(Num_STAs, L_Rec);
% Uniform_On = 1;         % Uniform Distribution

STAs.Count_Failure = zeros(Num_STAs, 8); 
% 1st col: Total received?
% 2nd col: Failure (CH errorr) 
% 3rd col: Failure(In-order delivery)
% 4th col: Failure(Duplicated Frame & CH errorr) 
% 5th col: Failure(Only Duplicated Frame) 
% 6th col: 
% 7th col:
% 8th col:

STAs.Result_Partial_Frame = zeros(Num_STAs, 5); % only for partial frame, 1st col: Total received, 2nd col: sum of remained length (unit:slot), 3rd col: Failure(Duplication), 4th col: sum of remained length (unit:slot)- with duplication, 5th col: sum of remained length (unit:slot)- without duplication

STAs.Tag = zeros(1, Num_STAs);  % Tag. When the STAs do not get TX opprotunity,  1: the STAs have 0 will discard their frame, 0: the STAs have 1 will save their frame and try to TX again.
STAs.Overhearing_MAP = -1*ones(Num_STAs, Num_MPDU);  % Overhearing_MAP record the history of received frame.(How Many times received for each frame?)


STAs.Overhearing_Count_Frame = zeros(Num_STAs, Num_MPDU);   % errored frames are excluded.
STAs.Overhearing_Count_Frame2 = zeros(Num_STAs, Num_MPDU);  % errored frames are included.

STAs.SFProb = Simple_Flooding_Probabilty*ones(Num_STAs, 1);
     %The position of a Source STA
     STAs.pos_x(1) = Target_Coverage/2; 
     STAs.pos_y(1) = Target_Coverage/2;
     % STAs.SFProb(1) = 1.0;
     STAs.Queue(1,2) = 1;
     STAs.Queue(1,3) = Num_MPDU;
     STAs.Queue_Frame_List(1,:) = -1*ones(1, Num_MPDU);
     STAs.Group(1,1) = -1;
     STAs.Group(1,2) = -1;
     STAs.Group(1,3) = -1;
     STAs.Tag(1) = -1;
     STAs.Overhearing_MAP(1,:) = zeros(1, Num_MPDU);
     STAs.Color(1) = 0;  % the color of source STA should be 'RED'
     
Uniform_On = 0;
Uniform_In_Out_On = 0;%(Num_STAs-1)/2;  % Positive number means that corresponding option is enabled and the number of the sensible neigbor STAs of Source STA
Grid_On = 0;
Gaussian_On = 0;
Circular_On = 1;
Simple_Test_Set_On = 0;
Uniform_Grid_On = 0;  % This type of topology is a mixture of Uniform and Grid.
                      % The grid distribution serves to prevent loss of connection among stations,
                      % and it also provides a random distribution of stations through a uniform distribution.

 if (Uniform_On)
    
    for i=2:Num_STAs
    
        STAs.pos_x(i) = rand*Target_Coverage; 
        STAs.pos_y(i) = rand*Target_Coverage;
              
    end
 
 elseif (Uniform_In_Out_On)
    Count = 0;
    i = 2; 
    while ( i <= Num_STAs )
        
        STAs.pos_x(i) = rand*Target_Coverage; 
        STAs.pos_y(i) = rand*Target_Coverage;
        RSSI = Path_Loss( STAs.pos_x(1), STAs.pos_y(1), STAs.pos_x(i), STAs.pos_y(i), 10 );
        
        if ( Count < Uniform_In_Out_On)
            if ( RSSI >= STAs.CsTh(1))
                i = i + 1;
                Count = Count + 1;
            end
            
        else
            if ( RSSI < STAs.CsTh(1))
                i = i + 1;
            end
        end
        
    
         
    end
    
    
    
% elseif(Grid_On)
%                               
%     interval = Target_Coverage/sqrt(Num_STAs);
% %     Nodes(1).pos_x = Target_Coverage;  % Initial Position-x
% %     Nodes(1).pos_y = Target_Coverage;  % Initial Position-y
% %     
%     col = Target_Coverage + interval;
%     row = Target_Coverage;
%     Noise_Scale = 3;
%     for i=2:Num_STAs
%         
%         
%         col = col - interval;
%         
%         STAs.pos_x(i) = col + normrnd(0, Noise_Scale);     
%         STAs.pos_y(i) = row + normrnd(0, Noise_Scale);
%         
%         if ( col < interval )
%             row = row - interval;
%             col = Target_Coverage + interval;
%         end
%         
%          
%     end
%     
% %     STAs.pos_x  = STAs.pos_x + normrnd(0,5 ,length(Num_STAs),1);
% %     STAs.pos_y  = STAs.pos_y + normrnd(0,5 ,length(Num_STAs),1);
elseif(Grid_On)
                              
    interval = Target_Coverage/sqrt(Num_STAs);

    Noise_Scale = 3;
    
    [STAs.pos_x(2:Num_STAs), STAs.pos_y(2:Num_STAs)] = meshgrid(1:sqrt(Num_STAs-1));
    STAs.pos_x(2:Num_STAs) = STAs.pos_x(2:Num_STAs)*interval + normrnd(0, Noise_Scale,1,Num_STAs-1) ;
    STAs.pos_y(2:Num_STAs) = STAs.pos_y(2:Num_STAs)*interval + normrnd(0, Noise_Scale,1,Num_STAs-1);
    
    STAs.pos_x(1) = STAs.pos_x(1) + interval/2;
    STAs.pos_y(1) = STAs.pos_y(1) + interval/2;
    
elseif(Gaussian_On)
    
   X = normrnd(STAs.pos_x(1),Target_Coverage*0.20,Num_STAs-1,1);   % Standard-deviation is 15-% of Target Coverage(default)
   Y = normrnd(STAs.pos_y(1),Target_Coverage*0.20,Num_STAs-1,1);   % Standard-deviation is 15-% of Target Coverage(default)
%    STAs.pos_x(2:Num_STAs) = truncate(X, 0 , Target_Coverage); 
%    STAs.pos_y(2:Num_STAs) = truncate(Y, 0 , Target_Coverage);
   STAs.pos_x(2:Num_STAs) = X; 
   STAs.pos_y(2:Num_STAs) = Y;
    
elseif(Simple_Test_Set_On)
   interval = 10; % distance between nodes
   X = linspace(STAs.pos_x(1)+interval,STAs.pos_x(1)+interval+interval*(Num_STAs), Num_STAs-1)
   Y = STAs.pos_y(1)*ones(1,Num_STAs-1);
   STAs.pos_x(2:Num_STAs) = X; 
   STAs.pos_y(2:Num_STAs) = Y;
    
 elseif(Uniform_Grid_On)
    % Step 1) Grid Topology
    % interval = Target_Coverage/sqrt(Num_STAs);
%     
    interval = 80;
    N_interval = 2*floor((Target_Coverage/2)/80);
    Noise_Scale = 3;
    N_Grid = N_interval^2;
    
    [STAs.pos_x(2:N_Grid+1), STAs.pos_y(2:N_Grid+1)] = meshgrid(1:sqrt(N_Grid));
    STAs.pos_x(2:N_Grid+1) = STAs.pos_x(2:N_Grid+1)*interval + normrnd(0, Noise_Scale,1,N_Grid) ;
    STAs.pos_y(2:N_Grid+1) = STAs.pos_y(2:N_Grid+1)*interval + normrnd(0, Noise_Scale,1,N_Grid) ;
    
%     STAs.pos_x(1) = STAs.pos_x(1) + interval/2;
%     STAs.pos_y(1) = STAs.pos_y(1) + interval/2;
    
    % Step 2) Uniform Random Topology
    for i=N_Grid+2:Num_STAs
    
        STAs.pos_x(i) = rand*Target_Coverage; 
        STAs.pos_y(i) = rand*Target_Coverage;
              
    end
 elseif (Circular_On)
    %theta = 0:0.01:2*pi;
    r = 1:0.01:300;
    % r2 = 1:0.01:300;
    for i=1:length(r)
        if Path_Loss(0,0,0,r(i), 10) <= STAs.CsTh(1)
            break;
        end
    end
    r = r(i);
    r2 = r*2;
    radius_rand_set = rand(1,Num_STAs-1)*r2;
    theta_rand_set = rand(1,Num_STAs-1)*2*pi;
    STAs.pos_x(2:Num_STAs) = radius_rand_set.*cos(theta_rand_set) +STAs.pos_x(1);
    STAs.pos_y(2:Num_STAs) = radius_rand_set.*sin(theta_rand_set) +STAs.pos_y(1);
     
 else
   error('Any Topology Types are not selected...Simulation ends...'); 
    
end    
     
     
     
     
     
    
%     Avg_Neighbor = [ 9.0245 11.1672 13.3208 15.4563 17.6129 19.7543 21.8927];
%     
%     Index_Avg = (Num_STAs - 15)/5;
%     
    
        
   

