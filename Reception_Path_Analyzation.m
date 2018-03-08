function [ Results Results_summary ] = Reception_Path_Analyzation( Record_TX_Node_ID, Intf_MAP, Node_ID )
%UNTITLED2 이 함수의 요약 설명 위치
%   자세한 설명 위치

% Step 1) From Intf_MAP and Node_ID, get the neighbor nodes ID of the input node ID(Node_ID)
% Step 2) Seperate 1Hop/2Hop neighbors of Node_ID

Neighbor_ID_1H = find(Intf_MAP(Node_ID,:) == 1 & Intf_MAP(1,:) == 1); % find 1-Hop neighbor nodes
Neighbor_ID_2H = find(Intf_MAP(Node_ID,:) == 1 & Intf_MAP(1,:) == 0); % find 2-Hop neighbor nodes
Neighbor_ID_2H(Neighbor_ID_2H == 1) = []; % remove source node's Id(#1)

% Step 3) Get the number of frames that the node received from the source node.
Num_of_SRC_RX = length(find(Record_TX_Node_ID(Node_ID,:) == 1));

% Step 4) Get the number of frames that the node received from the other nodes except the source node.

Num_of_1H_RX = zeros(1,length(Neighbor_ID_1H)+1);
Num_of_2H_RX = zeros(1,length(Neighbor_ID_2H)+1);

    for i=1:length(Neighbor_ID_1H)
        % Num_of_1H_RX = Num_of_1H_RX + length(find(Record_TX_Node_ID(Node_ID,:) == Neighbor_ID_1H(i)));
        Num_of_1H_RX(i) = length(find(Record_TX_Node_ID(Node_ID,:) == Neighbor_ID_1H(i)));
    end
        Num_of_1H_RX(length(Neighbor_ID_1H)+1) = sum(Num_of_1H_RX(1:length(Neighbor_ID_1H)));
   
    for i=1:length(Neighbor_ID_2H)
        % Num_of_2H_RX = Num_of_2H_RX + length(find(Record_TX_Node_ID(Node_ID,:) == Neighbor_ID_2H(i)));
        Num_of_2H_RX(i) = length(find(Record_TX_Node_ID(Node_ID,:) == Neighbor_ID_2H(i)));
    end
        Num_of_2H_RX(length(Neighbor_ID_2H)+1) = sum(Num_of_2H_RX(1:length(Neighbor_ID_2H)));
        
        Neighbor_ID_1H
        Num_of_1H_RX
        Neighbor_ID_2H
        Num_of_2H_RX
   
        
        figure;  % 1st figure
        hold on;
        h1 = bar(1, Num_of_SRC_RX,'r');
        h2 = bar(2, Num_of_1H_RX(length(Num_of_1H_RX)), 'g');        
        h3 = bar(3, Num_of_2H_RX(length(Num_of_2H_RX)), 'b');
        
        set(h1, 'BarWidth', 0.35);
        set(h2, 'BarWidth', 0.35);
        set(h3, 'BarWidth', 0.35);
        
        grid on;
        legend('Source','1-Hop','2-Hop','Location','Best');
        ylim([0 1000]);
        set(gca, 'xTick',1:3);
        set(gca, 'xTickLabel',{'Source', '1-Hop', '2-Hop'});
        set(gca, 'yTick',unique(sort([ Num_of_SRC_RX Num_of_1H_RX(length(Num_of_1H_RX)) Num_of_2H_RX(length(Num_of_2H_RX))])) );
        ylabel('number of frames');
        title('Reception Path(Hop)');
%         xticks([1 2 3]); Available on only R2017? 2016?
        hold off;
        
        figure;  % 2nd figure
        hold on;
       
        if ~isempty(Neighbor_ID_1H)
            hh1 = bar(Neighbor_ID_1H, Num_of_1H_RX(1:length(Num_of_1H_RX)-1),'g');
        end
        if ~isempty(Neighbor_ID_2H)
            hh2 = bar(Neighbor_ID_2H, Num_of_2H_RX(1:length(Num_of_2H_RX)-1),'b');
        end
        
        if ~isempty(Neighbor_ID_1H) && ~isempty(Neighbor_ID_2H)
            legend('1-Hop','2-Hop','Location','Best');
        elseif ~isempty(Neighbor_ID_1H)
            legend('1-Hop','Location','Best');
        else
            legend('2-Hop','Location','Best');
        end
        
        set(gca, 'xTick',[Neighbor_ID_1H Neighbor_ID_2H]);
%         set(hh1, 'BarWidth', 0.5);
%         set(hh2, 'BarWidth', 0.1);
        set(gca, 'yTick', unique(sort([ Num_of_1H_RX(1:length(Num_of_1H_RX)-1) Num_of_2H_RX(1:length(Num_of_2H_RX)-1)])));
        grid on;
        xlabel('Node ID');
        ylabel('number of frames');
        title('Reception Path(Node)');
        hold off;    
        
        % Step 5)   When the nodes receive a frame from the source node,
        % Step 5-1) Measurement 1) For any other 1-Hop neighbor nodes, how many frames are delivered from the node without duplication?
        % Step 5-2) Measurement 2) For any other 2-Hop neighbor nodes, how many frames are delivered from the node without duplication?
        Num_of_1H_Frames = zeros(1,length(Neighbor_ID_1H)+1);
        Num_of_2H_Frames = zeros(1,length(Neighbor_ID_2H)+1);
        
        for i = 1: length(Record_TX_Node_ID)
             if Record_TX_Node_ID(Node_ID, i ) == 1    % If the nodes receive a frame from the source node,
                
                for j = 1:length(Neighbor_ID_1H)
                    
                    if( Record_TX_Node_ID(Neighbor_ID_1H(j), i) == Node_ID ) 
                       % encount
                       Num_of_1H_Frames(j) = Num_of_1H_Frames(j) + 1;
                    end
                    
                end

                for k = 1:length(Neighbor_ID_2H)
                     
                    if( Record_TX_Node_ID(Neighbor_ID_2H(k), i) == Node_ID ) 
                        % encount
                        Num_of_2H_Frames(k) = Num_of_2H_Frames(k) + 1;
                    end
                    
                end
            end
        end
        
       Num_of_1H_Frames(length(Neighbor_ID_1H)+1) = sum(Num_of_1H_Frames(1:length(Neighbor_ID_1H))); 
       Num_of_2H_Frames(length(Neighbor_ID_2H)+1) = sum(Num_of_2H_Frames(1:length(Neighbor_ID_2H)));
       
       
        figure;
        hold on;
        bar(1, Num_of_1H_Frames(length(Num_of_1H_Frames)), 'g');        
        bar(2, Num_of_2H_Frames(length(Num_of_2H_Frames)), 'b');
        grid on;
        
        if ~isempty(Neighbor_ID_1H) && ~isempty(Neighbor_ID_2H)
            legend('1-Hop','2-Hop','Location','Best');
        elseif ~isempty(Neighbor_ID_1H)
            legend('1-Hop','Location','Best');
        else
            legend('2-Hop','Location','Best');
        end
        
        
        set(gca, 'xTick',1:2);
        set(gca, 'xTickLabel',{'1-Hop', '2-Hop'});
        set(gca, 'yTick',unique(sort([ Num_of_1H_Frames(length(Num_of_1H_Frames)) Num_of_2H_Frames(length(Num_of_2H_Frames))])) );
%         ylim([0 1000]);
        ylim([0 max([ Num_of_1H_Frames(length(Num_of_1H_Frames)) Num_of_2H_Frames(length(Num_of_2H_Frames))])]);
        ylabel('number of frames');
        title('Delivered frame from the node(Hop)');
        ylabel('number of frames');
        hold off;
        
        figure;
        hold on;
        %bar(1, Num_of_SRC_RX,'r');
        if ~isempty(Neighbor_ID_1H)
            bar(Neighbor_ID_1H, Num_of_1H_Frames(1:length(Num_of_1H_Frames)-1),'g');
        end
        if ~isempty(Neighbor_ID_2H)
            bar(Neighbor_ID_2H, Num_of_2H_Frames(1:length(Num_of_2H_Frames)-1),'b');
        end
        
        if ~isempty(Neighbor_ID_1H) && ~isempty(Neighbor_ID_2H)
            legend('1-Hop','2-Hop','Location','Best');
        elseif ~isempty(Neighbor_ID_1H)
            legend('1-Hop','Location','Best');
        else
            legend('2-Hop','Location','Best');
        end
        set(gca, 'xTick',[Neighbor_ID_1H Neighbor_ID_2H]);
%         set(hh1, 'BarWidth', 0.5);
%         set(hh2, 'BarWidth', 0.1);
        set(gca, 'yTick', unique(sort([ Num_of_1H_Frames(1:length(Num_of_1H_Frames)-1) Num_of_2H_Frames(1:length(Num_of_2H_Frames)-1)])));
        ylim([0 max([ Num_of_1H_Frames(1:length(Num_of_1H_Frames)-1) Num_of_2H_Frames(1:length(Num_of_2H_Frames)-1) ]) ]);
        grid on;
        title('Delivered frame from the node(Node)');
        xlabel('Node ID');
        ylabel('number of frames');
        hold off;
        
        Results(:,1) = [ Neighbor_ID_1H Neighbor_ID_2H ];
        Results(:,2) = [ Num_of_1H_RX(1:length(Num_of_1H_RX)-1) Num_of_2H_RX(1:length(Num_of_2H_RX)-1) ];
        Results(:,3) = [ Num_of_1H_Frames(1:length(Num_of_1H_Frames)-1) Num_of_2H_Frames(1:length(Num_of_2H_Frames)-1) ];
        
        Results_summary = zeros(3,2);
        Results_summary(:,1) = [Num_of_SRC_RX Num_of_1H_RX(length(Num_of_1H_RX)) Num_of_2H_RX(length(Num_of_2H_RX))];
        Results_summary(:,2) = [ 0 Num_of_1H_Frames(length(Num_of_1H_Frames)) Num_of_2H_Frames(length(Num_of_2H_Frames))];
end

