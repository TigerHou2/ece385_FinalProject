close all
clear;clc

imgName = 'map3';

im = imread([imgName '_orig.png']);

im = imresize(im,0.5);

[X_dither,map] = rgb2ind(im,6,'dither');
imshow(X_dither,map)
rgb2hex(map)

imwrite(X_dither,map,[imgName '.png'])
imwrite(X_dither,map,[imgName '.jpg'])