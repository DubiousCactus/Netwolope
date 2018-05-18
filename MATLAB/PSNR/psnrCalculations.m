%PSNR calculations for the 256 x 256 images

org = imread('lena-original.pgm');
net1 = imread('lena-256x256-netwolope-v1.pgm');
net2 = imread('lena-256x256-netwolope-v2.pgm');
rle = imread('lena-256x256-run-length.pgm');
btc = imread('lena-256x256-block-truncation.pgm');

% net1
[peaksnr, snr] = psnr(org,net1);
fprintf('\n The Peak-SNR value for net1 is %0.4f', peaksnr);
% net2
[peaksnr, snr] = psnr(org,net2);
fprintf('\n The Peak-SNR value for net2 is %0.4f', peaksnr);
% rle
[peaksnr, snr] = psnr(org,rle);
fprintf('\n The Peak-SNR value for rle is %0.4f', peaksnr);
% btc
[peaksnr, snr] = psnr(org,btc);
fprintf('\n The Peak-SNR value for btc is %0.4f', peaksnr);