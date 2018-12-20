function [d, n] = decimalDigits(number)
% decimalDigits
%   Detailed explanation goes here
    d = 0;
    n = number;
    while mod(n,1) ~= 0
        d = d + 1;
        n = number * 10.^d;
    end
end

