function [ RSSI ] = Path_Loss( Pos_X1, Pos_Y1, Pos_X2, Pos_Y2, TX_Power_X)

fc = 5.25; % GHz
c = 0.299792458; % velocity of light, 299,792,458 m/s or physconst('LightSpeed')*10^-10
lamda = c/fc;

d_BP = 5; % from MODEL C(Indoor and Outdoor)

TX_Power = TX_Power_X; % dBm

d = sqrt( abs( ( Pos_X1-Pos_X2)^2+(Pos_Y1-Pos_Y2)^2 ) );

if ( d <= d_BP)
    Path_loss =  2*10*log10(4*pi/lamda) + 20*log10(d); % L_FS_before_BP
else 
    Path_loss = 2*10*log10(4*pi/lamda) + 20*log10(d_BP) +  3.5*10*log10(d/d_BP);  % L_FS_after_BP
end

    RSSI = TX_Power - Path_loss;
end

