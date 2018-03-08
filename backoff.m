function [ bc ] = backoff( cw, N_STA )
% backoff calculation
% Input  1: cw (current contention window size)
% Output 1: bo (backoff counter)

bc = ceil(rand(1,N_STA)*cw)+1;

end

