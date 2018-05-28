function areal = powerintegral(x,y)
% calculate effect (integral)

areal = zeros(1,length(y));

for i = 2:(length(y)-1)
    t_next = x(i+1,1);
    t_prev = x(i,1);
    v_next = y(i+1);
    areal(i) = (t_next-t_prev)*v_next + areal(i-1);
        
end
