clear;
close all;
%%
SE_cr5 = imfill(circse(5));
SE_cr10 = imfill(circse(10));%가장 마지막에 추가
SE_cr20 = imfill(circse(20));
SE_cr30 = imfill(circse(30));

%%
path="2023 드론대회 3차 과제 이미지\"
image1=imread(path+"문제1.png");
image2=imread(path+"문제2.png");
image3=imread(path+"문제3.png");
image4=imread(path+"문제4.png");
image5=imread(path+"문제5.png");

image=image1;% 여기에 원하는 이미지 적용
figure();
image1HSV = rgb2hsv(image);
imshow(image1HSV)
image1H = image1HSV(:,:,1);
image1S = image1HSV(:,:,2);
image1V = image1HSV(:,:,3);

imageG_H = image1H >= 0.3 & image1H <= 0.36;
imageG_S = image1S >= 0.53 & image1S <= 0.73;
imageG_V = image1V >= 0.36 & image1V <= 0.62;
imageG_combi = imageG_H & imageG_S & imageG_V;
imageG_combi_bin=im2gray(double(imageG_combi));

figure();
imshow(imageG_combi_bin);

notimageG_combi=~imageG_combi;
figure();
imshow(notimageG_combi);

green_d1 = imdilate(imageG_combi_bin,SE_cr20);
green_e1 = imerode(green_d1,SE_cr20);
figure();
subplot(2,2,1);
imshow(green_d1);
subplot(2,2,2);
imshow(green_e1);hold on;
% green_e1_bin = im2gray(green_e1);
% subplot(2,2,3);
% imshow(green_e1_bin);




green_e1_canny = edge(green_e1,'canny');
subplot(2,2,4);
imshow(green_e1_canny);hold on;

stats = regionprops(green_e1_canny);
for i = 1:numel(stats)
    rectangle('Position', stats(i).BoundingBox, ...
    'Linewidth', 3, 'EdgeColor', 'r', 'LineStyle', '--');
end


w0=0;
b1=0;
w1=0;
targetIdx=zeros(1,2);
targetIdxTmp=zeros(1,2);
green_e1_copy=green_e1;


% g1=green_e1(300,:);
% [r,c]=size(g1)
% g1_=zeros(1,c);
% 

% for i=1:1:c-1
%     if (Gin==0) && (g1(i)==1) && (g1(i+1)==0)
%         Gin=i;
%     end
% 
%     if (Gin~=0) && (g1(i)==0) && (g1(i+1)==1)
%         Gout=i;
%     end
% end
% if (Gin~=0) && (Gout~=0)
%     g1_(Gin:Gout)=ones()
% end

[r c]=size(green_e1);%c=960 열
greenIn=zeros(r,c);
Gin=0;
Gout=0;
for i = 1:1:r
    for j=1:1:c-1
        if (Gin==0) && (green_e1_copy(i,j)==1) && (green_e1_copy(i,j+1)==0)
            Gin=j;
        end
    
        if (Gin~=0) && (green_e1_copy(i,j)==0) && (green_e1_copy(i,j+1)==1)
            Gout=j;
        end
    end
    if (Gin~=0) && (Gout~=0)
        greenIn(i,Gin:Gout)=ones();
    end
    Gin=0;
    Gout=0;
end

figure('Name', 'greenIn')
imshow(greenIn);


greenIn_d1 = imdilate(greenIn,SE_cr20);
greenIn_e1 = imerode(greenIn_d1,SE_cr20);

figure('Name', 'greenIn_e1')
imshow(greenIn_e1);

notgreenIn_e1=~greenIn_e1;
ngreenIn_d1 = imdilate(notgreenIn_e1,SE_cr20);
ngreenIn_e1 = imerode(ngreenIn_d1,SE_cr20);

figure('Name', 'ngreenIn_e1')
imshow(ngreenIn_e1);


% figure('Name', 'notgreen_copy_e1')
% imshow(notgreenIn_e1);hold on;
figure();
imshow(image);hold on;
[row col]=find(~ngreenIn_e1);
rf=mean(row)
cf=mean(col)
viscircles([cf rf],3);
disp(['x=' num2str(cf)])
disp(['y=' num2str(rf)])
% mean(notgreen_copy_e1)


% notgreen_d1 = imdilate(notimageG_combi,SE_cr30);
% notgreen_e1 = imerode(notgreen_d1,SE_cr30);
% figure();
% subplot(2,1,1);
% imshow(notgreen_d1);hold on;
% subplot(2,1,2);
% imshow(notgreen_e1);

% stats = [regionprops(imageG_combi); regionprops(not(imageG_combi))]

% 
% centerIdx=1;
% 
% for i = 1:numel(stats)
%     if stats(i).Area<stats(centerIdx).Area
%         centerIdx=i;
%     end
% end
% 
% figure()
% imshow(green_e1_canny);hold on;
% rectangle('Position', stats(centerIdx).BoundingBox, ...
%     'Linewidth', 3, 'EdgeColor', 'r', 'LineStyle', '--');
% viscircles(stats(centerIdx).Centroid,3);
% 





