%plot data from experiment
% [second , volts]
clear all; clc; close all;
scope_8 = csvread('scope_8.csv',2,0);
scope_9 = csvread('scope_9.csv',2,0);
scope_13 = csvread('scope_13.csv',2,0);
scope_14 = load('scope_14.csv');
scope_17 = csvread('scope_17.csv',2,0);
scope_18 = csvread('scope_18.csv',2,0);
scope_21 = csvread('scope_21.csv',2,0);
scope_22 = csvread('scope_22.csv',2,0);
scope_24 = csvread('scope_24.csv',2,0);

%%% figure 8 (No compression (44 seconds))
fig = figure(8)
scope_8(:,1)=scope_8(:,1)-scope_8(1,1); % to set 1 to zero
plot(scope_8(:,1),scope_8(:,2)*1000)
xlim([scope_8(600,1) scope_8(end,1)])
title('No compression (44 seconds)')
xlabel('Time (s)')
ylabel('Volt (mV)')
grid
print(fig,'nocompression_44_seconds1','-dpng')
%%% figure 9 (No compression (44 seconds))
fig = figure(9)
scope_9(:,1)=scope_9(:,1)-scope_9(1,1); % to set 1 to zero
plot(scope_9(:,1),scope_9(:,2)*1000)
xlim([0 scope_9(end-75,1)])
title('No compression (44 seconds)')
xlabel('Time (s)')
ylabel('Volt (mV)')
grid
print(fig,'nocompression_44_seconds2','-dpng')

%%% figure 13 (not usefull as I see it)
figure(13)
scope_13(:,1)=scope_13(:,1)-scope_13(1,1); % to set 1 to zero
plot(scope_13(:,1),scope_13(:,2)*1000)
xlim([0 scope_13(end,1)])
title('Not usefull as I see it')
xlabel('Time (s)')
ylabel('Volt (mV)')
grid

%%% figure 14 (not usefull as I see it)
figure(14)
scope_14(:,1)=scope_14(:,1)-scope_14(1,1); % to set 1 to zero
scope_14(494:end,1) = scope_14(494:end,1)/1000; % to remove the wierd measurement
plot(scope_14(:,1),scope_14(:,2))
title('Not usefull plot as I see it')

%%% figure 17 (no compression (44 seconds)
% note the -19 in xlim (to remove it from plot)
fig = figure(17)
scope_17(:,1)=scope_17(:,1)-scope_17(1,1); % to set 1 to zero
plot(scope_17(:,1),scope_17(:,2)*1000)
xlim([0 scope_17(end-19,1)])
title('No compression (44 seconds)')
xlabel('Time (s)')
ylabel('Volt (mV)')
grid
print(fig,'nocompression_44_seconds3','-dpng')

%%% figure 18 (PLOT: Radio on (idle))
% note the -1 in xlim (to remove it from plot)
fig = figure(18)
scope_18(:,1)=scope_18(:,1)-scope_18(1,1); % to set 1 to zero
plot(scope_18(:,1),scope_18(:,2)*1000)
xlim([0 scope_18(end-1,1)])
title('Radio on (idle)')
xlabel('Time (s)')
ylabel('Volt (mV)')
grid
print(fig,'radion_on_iddle','-dpng')

%%% figure 21 (No compression (82 seconds)
fig = figure(21)
scope_21(:,1)=scope_21(:,1)-scope_21(1,1); % to set 1 to zero
plot(scope_21(:,1),scope_24(:,2)*1000)
xlim([0 scope_21(end,1)])
title('No compression (82 seconds)')
xlabel('Time (s)')
ylabel('Volt (mV)')
grid
print(fig,'nocompression_82_seconds','-dpng')

%%% figure 22: 
figure(22)
scope_22(:,1)=scope_22(:,1)-scope_22(1,1); % to set 1 to zero
plot(scope_22(:,1),scope_22(:,2)*1000)
xlim([0 scope_22(301,1)])
title('Radio on / Mote reset button pushed')
xlabel('Time (s)')
ylabel('Volt (mV)')
grid

%%% figure 24: (Run time algorithm (26 seconds)
figure(24)
scope_24(:,1)=scope_24(:,1)-scope_24(1,1); % to set 1 to zero
plot(scope_24(:,1),scope_24(:,2)*1000)
xlim([0 scope_24(end,1)])
title('Run time algorithm (26 seconds)')
xlabel('Time (s)')
ylabel('Volt (mV)')
grid