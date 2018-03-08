function [ ] = Highlighting_Node_Positions( x, y, Nodes_List, PP )
%UNTITLED 이 함수의 요약 설명 위치
%   특정 노드의 위치를 하이라이트하여 강조합니다. 그리고 각 노드의 DR curve를 그립니다.
    figure;
    hold on;
    
    % Plotting every Nodes
    plot(x, y, 'bo');
    xlabel('X-axis');ylabel('Y-axis');
    
    % Highlighting by color
    plot(x(Nodes_List), y(Nodes_List), 'ko', 'MarkerSize',12, 'MarkerFaceColor',[1 0 0]);

    % Highlighting by Node ID
    for i = 1 : length(Nodes_List)
       text(x(Nodes_List(i))-1, y(Nodes_List(i))+1, num2str(Nodes_List(i)), 'Color', [0 0 0], 'FontSize', 11 );
    end
    
    % Draw Coverage Lines
    theta = 0:0.01:2*pi;
    r = 1:0.01:300;
    % r2 = 1:0.01:300;
    for i=1:length(r)
        if Path_Loss(0,0,0,r(i), 10) <= -82
            break;
        end
    end
    r = r(i);
    r2 = r*2;
    Circle_X = r*cos(theta) + x(1);
    Circle_Y = r*sin(theta) + y(1);
    Circle_X2 = r2*cos(theta) + x(1);
    Circle_Y2 = r2*sin(theta) + y(1);
    plot(Circle_X, Circle_Y,'k--', Circle_X2, Circle_Y2,'k--');
    
    hold off;
        
    for i = 1: length(Nodes_List)
    figure;
    plot(PP(Nodes_List(i),:), 'k-.');
    title(strcat('#', num2str(Nodes_List(i)),' node'));
    xlim([0 35]);
    ylim([0 1.05]);
    end
    
    
end

