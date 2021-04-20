close all
clear;clc

imgName = 'map2_orig';

im = imread([imgName '.png']);

[X_dither,map] = rgb2ind(im,6,'dither');
imshow(X_dither,map)
rgb2hex(map)

% imwrite(X_dither,map,[imgName '.png'])
% imwrite(X_dither,map,[imgName '.jpg'])