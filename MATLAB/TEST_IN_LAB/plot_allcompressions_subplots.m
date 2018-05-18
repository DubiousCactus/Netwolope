% ============ plot net1, net2, run-length together in one plot ==========
% Plot data from experiment
% ============ load data =================================================
%clear all; clc; close all;
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
netwolope2_32x32(:,2) = netwolope2_32x32(:,2)*1000; %mV
netwolope2_32x32(:,1)=netwolope2_32x32(:,1)-netwolope2_32x32(1,1); % to set 1 to zero
netwolope1_32x32(:,1) = netwolope1_32x32(:,1)*1000; % to mS
netwolope1_32x32(:,2) = netwolope1_32x32(:,2)*1000;% mV
netwolope1_32x32(:,1)=netwolope1_32x32(:,1)-netwolope1_32x32(1,1); % to set 1 to zero
blocktruncation_32x32(:,1) = blocktruncation_32x32(:,1)*1000; % mS
blocktruncation_32x32(:,2) = blocktruncation_32x32(:,2)*1000; %mV
blocktruncation_32x32(:,1)=blocktruncation_32x32(:,1)-blocktruncation_32x32(1,1); % to set 1 to zero
runlength_32x32(:,1) = runlength_32x32(:,1)*1000; %[mS]
runlength_32x32(:,2) = runlength_32x32(:,2)*1000;%[mV]
runlength_32x32(:,1)=runlength_32x32(:,1)-runlength_32x32(1,1); % to set 1 to zero
nocompression_32x32(:,1) = nocompression_32x32(:,1)*1000;  %[mS]
nocompression_32x32(:,2) = nocompression_32x32(:,2)*1000; %[mV]
nocompression_32x32(:,1)=nocompression_32x32(:,1)-nocompression_32x32(1,1); % to set 1 to zero
netwolope2_64x64(:,1) = netwolope2_64x64(:,1)*1000; %mS
netwolope2_64x64(:,2) = netwolope2_64x64(:,2)*1000; %mV
netwolope2_64x64(:,1)=netwolope2_64x64(:,1)-netwolope2_64x64(1,1); % to set 1 to zero
% ================= Start plotting the different algorithms ==============

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

%%% figure 2 Netwolope 1) %%%%%%%%%%%%%%%%%%%%%%%
% 8 packages 
% ratio 2.0
% Raw data without ending of file (2 ratio)

figure;
h1 = subplot(3,1,1);
plot(netwolope1_32x32(685:1720,1)-netwolope1_32x32(685,1),netwolope1_32x32(685:1720,2))
xlim([0,269])
ylim([150 220])
grid minor;
ylabel('Volt (mV)')
title('netwolope1')
hold on

%%% figure 1 Netwolope 2. %%%%%%%%%%%%%%%%%%%%%%%
% 10 package sent 
% ratio 1.6 
% Raw data without ending of file
h2 = subplot(3,1,2);
plot(netwolope2_32x32(631:end,1)-netwolope2_32x32(631,1),netwolope2_32x32(631:end,2));
xlim([0,342])
ylim([150 220])
grid minor;
ylabel('Volt (mV)')
title('netwolope2')
hold on

%%% figure 4 runlength algorithm %%%%%%%%%%%%%%%%%%% 
% 21 packages 
% ratio 0.77
h3 = subplot(3,1,3);
plot(runlength_32x32(421:1880,1)-runlength_32x32(421,1),runlength_32x32(421:1880,2))
xlim([0 700])
ylim([150 220])
xlabel('Time (mS)')
ylabel('Volt (mV)')
grid minor;
title('runlength')
hold on

%%% figure 3 blocktruncation %%%%%%%%%%%%%%%%%%%%%%%
% blocktruncation 
% 4 packages 
% ratio 4.0
% subplot(4,1,4);
% plot(blocktruncation_32x32(:,1),blocktruncation_32x32(:,2))
% title('blocktruncation')
% hold off