function bwMask = segmentObject(Intensity, G1, G2, diskSize, areaThr, SEPARATION, SMOOTH)

Intensity = imcomplement(Intensity);
Intensity_open = imopen(Intensity, strel('disk', diskSize));
Intensity_recon = imreconstruct(Intensity_open, Intensity);
Intensity_enh = Intensity - Intensity_recon;
bw1 = Intensity_enh > G1;
bw2 = Intensity_enh > G2;
ind = find(bw1);
if ~isempty(ind)
    [rows, cols] = ind2sub(size(Intensity_enh),ind);
    bwMask = bwselect(bw2,cols,rows,8);
    bwMask = bwareaopen(bwMask, areaThr(1));
else
    bwMask = zeros(size(Intensity_enh));
end



if SEPARATION
    distance = -bwdist(~bwMask);
    distance(~bwMask) = -Inf;
    distance2 = imhmin(distance, 1);
    bwMask(watershed(distance2)==0) = 0;

end


bwMask = imfill(bwMask, 'holes');
[L] = bwlabel(bwMask, 4);
stats = regionprops(L, 'Area');
areas = [stats.Area];
ind = find(areas>areaThr(1) & areas<areaThr(2));
bwMask = ismember(L, ind);


if SMOOTH
    boundaries = bwboundaries(bwMask);
    num = length(boundaries);
    bwMask(bwMask==1) = 0;
    for i = 1:num
        fprintf('%d out of %d is being smoothed.\n', i, num);
        
        b = boundaries{i};
        if size(b,1) > 15
            b(:,2) = lowB(b(:,2));
            b(:,1) = lowB(b(:,1));
            if any(b(:)<0 | b(:)>size(bwMask,1))
                continue;
            end
            boundaries{i} = b;
        end
        
        tempBW = roipoly(bwMask,b(:,2),b(:,1));
        bwMask = bwMask | tempBW;
    end
end

function low_s = lowB(s)
S = fft(s);

order = 30;
cutoff_freq = 30;
c = fir1(order, cutoff_freq/length(s)/2);
C = fft(c,length(s));
low_s = ifft(C'.*S);
low_s(end) = low_s(1);