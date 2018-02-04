function B = hysteresis_main_function(Intensity, high_t, low_t, areaThr, SEPARATION, SMOOTH)
%Inputs:
%Intensity: grayscale image
%high_t: higher threshold
%low_t: lower threshold
%areaThr: threshold for area
%SEPARATION: boolean indicator for watershed
%SMOOTH: boolean for boundary smoothing

%Output:
%B: cell for coordinates in (row, col) pairs

high_bw = Intensity > high_t;
low_bw = Intensity > low_t;
ind = find(high_bw);
if ~isempty(ind)
    [rows, cols] = ind2sub(size(Intensity),ind);
    bwMask = bwselect(low_bw,cols,rows,8);
    bwMask = bwareaopen(bwMask, areaThr(1));
else
    bwMask = zeros(size(Intensity));
end



if SEPARATION
    distance = -bwdist(~bwMask);
    distance(~bwMask) = -Inf;
    bwMask(watershed(imhmin(distance, 1))==0) = 0;

end

bwMask = imfill(bwMask, 'holes');
% [L] = bwlabel(bwMask, 4);
% stats = regionprops(L, 'Area');
% areas = [stats.Area];
% ind = find(areas>areaThr(1) & areas<areaThr(2));
% bwMask = ismember(L, ind);


if SMOOTH
    boundaries = bwboundaries(bwMask);
    num = length(boundaries);
    bwMask(bwMask==1) = 0;
    for i = 1:num
        %fprintf('%d out of %d is being smoothed.\n', i, num);

        b = boundaries{i};
        if size(b,1) > 15
            b(:,2) = lowB(b(:,2));
            b(:,1) = lowB(b(:,1));
            cols = b(:,2);
            rows = b(:,1);
        end

        if any(b(:)<0) || any(rows(:)>size(bwMask,1)) || any(cols(:)>size(bwMask,2))
                continue;
        end

        boundaries{i} = b;

        tempBW = roipoly(bwMask,b(:,2),b(:,1));
        bwMask = bwMask | tempBW;
    end
end


B = bwboundaries(bwMask,4,'noholes');

[B,L] = bwboundaries(bwMask,'noholes');
imshow(label2rgb(L, @jet, [.5 .5 .5]))
hold on
for k = 1:length(B)
 boundary = B{k};
 plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
end



function low_s = lowB(s)
S = fft(s);

order = 30;
cutoff_freq = 30;
c = fir1(order, cutoff_freq/length(s)/2);
C = fft(c,length(s));
low_s = ifft(C'.*S);
low_s(end) = low_s(1);
