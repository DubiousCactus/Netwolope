% Plot data from experiment

%%%%% ============= THE FOLLOWING FILE INCLUDE ===========================
% 1) plot all compressions in a plot by it self
% 2) plot all together
% 3) Power calculations
% 4) Plot read from flash / preparing data 
%% ====== PLOT ALL COMPRESSION IN A PLOT BY IT SELF =====================

%%% figure 1 Netwolope 2. %%%%%%%%%%%%%%%%%%%%%%%
%       10 package sent 
%       ratio 1.6 
%%% figure 2 Netwolope 1) %%%%%%%%%%%%%%%%%%%%%%%
%       8 packages 
%       ratio 2.0
%%% figure 3 blocktruncation %%%%%%%%%%%%%%%%%%%%%%%
%       4 packages 
%       ratio 4.0
%%% figure 4 runlength algorithm %%%%%%%%%%%%%%%%%%% 
%       21 packages 
%       ratio 0.77
% the first package is smaller because its file begin. 
clear all; clc; close all;
netwolope2_32x32 = csvread('netwolope_compression2_32x32.csv',2,0);
netwolope1_32x32 = csvread('netwolope-1-32x32-harry.csv',2,0);
blocktruncation_32x32 = csvread('blocktruncation_32x32_scope_35.csv',2,0);
runlength_32x32 = csvread('runlength_32x32_scope_41.csv',2,0);
nocompression_32x32 = csvread('nocompression_32x32_scope_44.csv',2,0);
netwolope2_64x64 = csvread('netwolope_64x64_scope_48.csv',2,0);
%%% voltage across the Mote Umote(t) is given by:
Ubattery = 3; %[V]
%%% convert the measurements to mS and mV and set to zero.
netwolope2_32x32(:,1) = netwolope2_32x32(:,1)*1000; %mS
netwolope2_32x32(:,2) = netwolope2_32x32(:,2); %V
netwolope2_32x32(:,1)=netwolope2_32x32(:,1)-netwolope2_32x32(1,1); % to set 1 to zero
netwolope1_32x32(:,1) = netwolope1_32x32(:,1)*100; % to mS
netwolope1_32x32(:,2) = netwolope1_32x32(:,2)*1000;% to mV
netwolope1_32x32(:,1)=netwolope1_32x32(:,1)-netwolope1_32x32(1,1); % to set 1 to zero
blocktruncation_32x32(:,1) = blocktruncation_32x32(:,1)*1000; % mS
blocktruncation_32x32(:,2) = blocktruncation_32x32(:,2)*1000; %mV
blocktruncation_32x32(:,1)=blocktruncation_32x32(:,1)-blocktruncation_32x32(1,1); % to set 1 to zero
runlength_32x32(:,1) = runlength_32x32(:,1)*100; %[mS]
runlength_32x32(:,2) = runlength_32x32(:,2)*1000;%[mV]
runlength_32x32(:,1)=runlength_32x32(:,1)-runlength_32x32(1,1); % to set 1 to zero
nocompression_32x32(:,1) = nocompression_32x32(:,1)*100;  %[mS]
nocompression_32x32(:,2) = nocompression_32x32(:,2)*1000; %[mV]
nocompression_32x32(:,1)=nocompression_32x32(:,1)-nocompression_32x32(1,1); % to set 1 to zero
netwolope2_64x64(:,1) = netwolope2_64x64(:,1)*100; %mS
netwolope2_64x64(:,2) = netwolope2_64x64(:,2)*1000; %mV
netwolope2_64x64(:,1)=netwolope2_64x64(:,1)-netwolope2_64x64(1,1); % to set 1 to zero

%%% figure 1 Netwolope 2. %%%%%%%%%%%%%%%%%%%%%%%
% 10 package sent 
% ratio 1.6 
% Raw data without ending of file
fig = figure(1)
plot(netwolope2_32x32(:,1),netwolope2_32x32(:,2)); grid
ylim([-0.1 0.35])
%xlim([netwolope2_32x32 netwolope2_32x32(end,1)])
title('Netwolope compression 2')
xlabel('Time (ms)')
ylabel('Volt (V)')
print(fig,'netwolope_compression2_32x32','-dpng')
grid

%%% figure 2 Netwolope 1) %%%%%%%%%%%%%%%%%%%%%%%
% 8 packages 
% ratio 2.0
% Raw data without ending of file (2 ratio)
fig = figure(2)
plot(netwolope1_32x32(:,1),netwolope1_32x32(:,2))
grid
xlim([netwolope1_32x32(1,1) netwolope1_32x32(end,1)])
ylim([-10 240])
%xlim([netwolope2_32x32 netwolope2_32x32(end,1)])
title('Netwolope compression 1')
xlabel('Time (s)')
ylabel('Volt (mV)')
%print(fig,'netwolope_compression1_32x32','-dpng')
%grid


%%% figure 3 blocktruncation %%%%%%%%%%%%%%%%%%%%%%%
% blocktruncation 
% 4 packages 
% ratio 4.0
fig = figure(3)
plot(blocktruncation_32x32(:,1),blocktruncation_32x32(:,2))
grid
xlim([blocktruncation_32x32(121,1) blocktruncation_32x32(end,1)])
ylim([160 240])
%xlim([blocktruncation_32x32 blocktruncation_32x32(end,1)])
title('Blocktruncation compression')
legend('Blocktruncation')
xlabel('Time (mS)')
ylabel('Volt (mV)')
print(fig,'blocktruncation_32x32','-dpng')
grid

%%% figure 4 runlength algorithm %%%%%%%%%%%%%%%%%%% 
% 21 packages 
% ratio 0.77
fig = figure(4)
plot(runlength_32x32(:,1),runlength_32x32(:,2))
grid
xlim([0 runlength_32x32(end,1)])
ylim([-10 240])
%xlim([runlength_32x32 runlength_32x32(end,1)])
title('Runlength compression')
xlabel('Time (mS)')
ylabel('Volt (mV)')
%print(fig,'runlength_32x32','-dpng')
%grid

%%% figure 5 no compression algorithm      %%%%%%%%%%%%%%%%%%%
% 16 packages (ratio 1.0)
% Theres no differences between compression and nocompression 
% (the start of the plot). 
% the figure shows 37.5ms and 202.5mV to no compression
% we made a mistake to start the radio at the very beginning. 14mV.
fig = figure(5)
plot(nocompression_32x32(:,1),nocompression_32x32(:,2))
grid
xlim([0 nocompression_32x32(end,1)])
ylim([-10 220])
%xlim([runlength_32x32 runlength_32x32(end,1)])
title('Nocompression')
xlabel('Time (mS)')
ylabel('Volt (mV)')
%print(fig,'runlength_32x32','-dpng')
%grid


%%% figure 6 netwolope 2 64x64
% 40 packages
% ratio 1.6

fig = figure(6)
plot(netwolope2_64x64(:,1),netwolope2_64x64(:,2))
grid
xlim([0 netwolope2_64x64(end,1)])
ylim([-10 220])
%xlim([runlength_32x32 runlength_32x32(end,1)])
title('Netwolope 2 64x64')
xlabel('Time (mS)')
ylabel('Volt (mV)')
%print(fig,'runlength_32x32','-dpng')
%grid

%% ================ plot all together ====================================
%clear all; clc; close all;
netwolope2_32x32 = csvread('netwolope_compression2_32x32.csv',2,0);
netwolope1_32x32 = csvread('netwolope-1-32x32-harry.csv',2,0);
blocktruncation_32x32 = csvread('blocktruncation_32x32_scope_35.csv',2,0);
runlength_32x32 = csvread('runlength_32x32_scope_41.csv',2,0);
nocompression_32x32 = csvread('nocompression_32x32_scope_44.csv',2,0);
netwolope2_64x64 = csvread('netwolope_64x64_scope_48.csv',2,0);

%normalize data to 0.
nocompression_32x32(:,1) = nocompression_32x32(:,1);
netwolope2_32x32(:,1) = netwolope2_32x32(:,1); %netwolope 1
runlength_32x32(:,1) = runlength_32x32(:,1); %netwolope2

fig = figure(7)
plot(nocompression_32x32(:,1),nocompression_32x32(:,2))
hold on
plot(netwolope1_32x32(:,1),netwolope1_32x32(:,2))
hold on
plot(netwolope2_32x32(:,1),netwolope2_32x32(:,2))
hold on
plot(runlength_32x32(:,1),runlength_32x32(:,2))
hold on
plot(blocktruncation_32x32(1:600,1),blocktruncation_32x32(1:600,2))
hold off
xlim([-0.01584 0.9])
legend('No compression','Netwolope 1','Netwolope 2','Run length','Blocktruncation')
grid

%% ================== Power calculations =================================
% some math from blackboard https://blackboard.au.dk/bbcswebdav/pid-1730277-dt-content-rid-3806357_1/courses/BB-Cou-UUVA-72424/Lecture%205B%20-%20Lab%20exercise%20-%20Energy%20%26%20Power%20consumption%281%29.pdf
% Ushunt = Rshunt * ishunt; [V = Ohm*A]
% Imote = Ishunt = Ushunt/Rshunt
% where Rshunt is the value of the shunt resister [10Ohm]
% The voltage across the Mote Umote(t) is given by:
% Umote(t) = Ubattery(t) - Ushunt(t) [V]
% Where Ubattery(t) is the battery voltage of the 2xAA batteries in series.
% The power consumption by the Mote at any time t is then:
% Pmote(t) = Umote(t)*Imote(t) = (Ubattery(t)-Ushunt(t))*Ushunt(t)

netwolope2_32x32 = csvread('netwolope_compression2_32x32.csv',2,0);
netwolope1_32x32 = csvread('netwolope-1-32x32-harry.csv',2,0);
blocktruncation_32x32 = csvread('blocktruncation_32x32_scope_35.csv',2,0);
runlength_32x32 = csvread('runlength_32x32_scope_41.csv',2,0);
nocompression_32x32 = csvread('nocompression_32x32_scope_44.csv',2,0);
netwolope2_64x64 = csvread('netwolope_64x64_scope_48.csv',2,0);

nocompression_32x32(:,1)=nocompression_32x32(:,1)-nocompression_32x32(1,1); % to set 1 to zero
nocompression_32x32(nocompression_32x32 < 0 ) = 0;
netwolope1_32x32(:,1)=netwolope1_32x32(:,1)-netwolope1_32x32(1,1); % to set 1 to zero
netwolope1_32x32(netwolope1_32x32 < 0 ) = 0;
netwolope2_32x32(:,1)=netwolope2_32x32(:,1)-netwolope2_32x32(1,1); % to set 1 to zero
netwolope2_32x32(netwolope2_32x32 < 0 ) = 0;
runlength_32x32(:,1)=runlength_32x32(:,1)-runlength_32x32(1,1); % to set 1 to zero
runlength_32x32(runlength_32x32 < 0 ) = 0;
blocktruncation_32x32(:,1)=blocktruncation_32x32(:,1)-blocktruncation_32x32(1,1); % to set 1 to zero
blocktruncation_32x32(blocktruncation_32x32 < 0 ) = 0;
Ubattery = 3;   %[V] 2x AA battery in series.
Rshunt = 10;    %[0hms]

% NO COMPRESSION
measurements = [nocompression_32x32(80:end,1)-nocompression_32x32(80,1) nocompression_32x32(80:end,2)]; 
UshuntNoCompression = measurements(:,2);
IshuntNoCompression = UshuntNoCompression/Rshunt;   %[A]
UMoteNoCompression = Ubattery-UshuntNoCompression;  %[V]
PmoteNoCompression = UMoteNoCompression.*IshuntNoCompression; %[Watt]
% convert to milli watt and seconds
PmoteNoCompression = PmoteNoCompression;
measurements(:,1) = measurements(:,1);
areal = powerintegral(measurements(:,1),PmoteNoCompression);

figure;
plot(measurements(:,1),areal)
hold on

%%% netwolope1
measurements = [netwolope1_32x32(198:end,1)-netwolope1_32x32(198,1) netwolope1_32x32(198:end,2)]; 
UshuntNoCompression = measurements(:,2);
IshuntNoCompression = UshuntNoCompression/Rshunt;   %[A]
UMoteNoCompression = Ubattery-UshuntNoCompression;  %[V]
PmoteNoCompression = UMoteNoCompression.*IshuntNoCompression; %[Watt]
% convert to milli watt and seconds
PmoteNoCompression = PmoteNoCompression;
measurements(:,1) = measurements(:,1);
areal = powerintegral(measurements(:,1),PmoteNoCompression);

plot(measurements(:,1),areal)
hold on

%%% netwolope2
measurements = [netwolope2_32x32(67:end,1)-netwolope2_32x32(67,1) netwolope2_32x32(67:end,2)]; 
UshuntNoCompression = measurements(:,2);
IshuntNoCompression = UshuntNoCompression/Rshunt;   %[A]
UMoteNoCompression = Ubattery-UshuntNoCompression;  %[V]
PmoteNoCompression = UMoteNoCompression.*IshuntNoCompression; %[Watt]
% convert to milli watt and seconds
PmoteNoCompression = PmoteNoCompression;
measurements(:,1) = measurements(:,1);
areal = powerintegral(measurements(:,1),PmoteNoCompression);

plot(measurements(:,1),areal)
hold on

%%% runlength
measurements = [runlength_32x32(123:end,1)-runlength_32x32(123,1) runlength_32x32(123:end,2)] ; 
UshuntNoCompression = measurements(:,2);
IshuntNoCompression = UshuntNoCompression/Rshunt;   %[A]
UMoteNoCompression = Ubattery-UshuntNoCompression;  %[V]
PmoteNoCompression = UMoteNoCompression.*IshuntNoCompression; %[Watt]
% convert to milli watt and seconds
PmoteNoCompression = PmoteNoCompression;
measurements(:,1) = measurements(:,1);
areal = powerintegral(measurements(:,1),PmoteNoCompression);

plot(measurements(:,1),areal)
hold on
%%% blocktruncation
measurements = [blocktruncation_32x32(122:end,1)-blocktruncation_32x32(122,1),blocktruncation_32x32(122:end,2)]; 
UshuntNoCompression = measurements(:,2);
IshuntNoCompression = UshuntNoCompression/Rshunt;   %[A]
UMoteNoCompression = Ubattery-UshuntNoCompression;  %[V]
PmoteNoCompression = UMoteNoCompression.*IshuntNoCompression; %[Watt]
areal = powerintegral(measurements(:,1),PmoteNoCompression);

plot(measurements(:,1),areal)
hold on

xlabel('Time (S)')
ylabel('Energy (Joules)')
xlim([0 3.5])
title('Energy consumed by the Mote at any time t')
legend('No Compression','Netwolope1','Netwolope2','Runlength','Blocktruncation')
print('energy_consumed_by_all_motes','-dpng')
grid

%% =========== Plot read from flash / preparing data ======================
% plot all together
clear all; clc; close all;
netwolope2_32x32 = csvread('netwolope_compression2_32x32.csv',2,0);
netwolope1_32x32 = csvread('netwolope-1-32x32-harry.csv',2,0);
blocktruncation_32x32 = csvread('blocktruncation_32x32_scope_35.csv',2,0);
runlength_32x32 = csvread('runlength_32x32_scope_41.csv',2,0);
nocompression_32x32 = csvread('nocompression_32x32_scope_44.csv',2,0);
netwolope2_64x64 = csvread('netwolope_64x64_scope_48.csv',2,0);

%normalize data to 0.
nocompression_32x32(:,1) = nocompression_32x32(:,1);
netwolope2_32x32(:,1) = netwolope2_32x32(:,1); %netwolope 1
runlength_32x32(:,1) = runlength_32x32(:,1); %netwolope2

fig = figure(7)
plot(nocompression_32x32(160:431,1),nocompression_32x32(160:431,2)-0.00114)
hold on
plot(netwolope1_32x32(315:684,1),netwolope1_32x32(315:684,2))
hold on
plot(netwolope2_32x32(189:635,1),netwolope2_32x32(189:635,2))
hold on
plot(runlength_32x32(201:426,1)-0.00805,runlength_32x32(201:426,2))
hold on
plot(blocktruncation_32x32(141:202,1)-0.00309,blocktruncation_32x32(141:202,2)+0.00204)
hold off
xlim([0.0284 0.1403])
xlabel('Time (S)')
ylabel('Volt (V)')
%xlim([0 3596])
title('Read from flash / preparing data')
legend('No Compression','Netwolope1','Netwolope2','Runlength','Blocktruncation')
%legend('No compression','Netwolope 1','Netwolope 2','Run length')
grid