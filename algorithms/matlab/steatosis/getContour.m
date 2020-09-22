function B = getContour(bw, ARC_LIMIT)
bw = imfill(bw, 'holes');
    B = bwboundaries(bw, 8);
    num = length(B);
    for i = 1:num
        b = B{i};
        if size(b,1) > ARC_LIMIT
            b(:,2) = lowB(b(:,2));
            b(:,1) = lowB(b(:,1));
            if any(b(:, 1)<0 | b(:, 2)<0 | b(:, 1)>size(bw,1) | b(:, 2)>size(bw,2))
                continue;
            end
            B{i} = b;
        end
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
end