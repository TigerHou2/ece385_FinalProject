close all
clear;clc

imgName = 'tile_stone';
im = imread([imgName '_orig.png']);

palette_hex = ...
['0x24415D';'0xBC7284';'0xF8B293';'0x525575';'0xF9CD95';'0xEF7580'; ... map 1 colors
 '0x035852';'0x2FBDA1';'0x9BE0BE';'0x06847F';'0x62D7B6';'0xDDECCF'; ... map 2 colors
 '0x252033';'0x5F4F71';'0x9D728F';'0x342845';'0x7A5E7E';'0x443D5D'; ... map 3 colors
 '0x000000';'0x555555';'0xBBBBBB';'0xFFFFFF';'0x844731';'0x987632'; ... common colors
 '0x0055AA';'0x4E89C4';'0xBA3420';'0xEF5953'; ...  team colors
 '0x231F20';'0xEB1A27';'0xF1EB30';'0xFBAF3A' ...   bomb colors
];

palette = hex2rgb(palette_hex);

[X,map] = rgb2ind(im,8,'nodither');
newMap = map;

for i = 1:size(map,1)
    temp = repmat(map(i,:),size(palette,1),1);
    similarity = vecnorm(temp-palette,2,2);
    [~,idx] = min(similarity);
    newMap(i,:) = palette(idx,:);
end

imshow(X,newMap)

imwrite(X,newMap,[imgName '.png'])
% imwrite(X_dither,map,[imgName '.jpg'])