function low_s = lowB(s)
S = fft(s);

order = 30;
cutoff_freq = 30;
c = fir1(order, cutoff_freq/length(s)/2);
C = fft(c,length(s));
low_s = ifft(C'.*S);
low_s(end) = low_s(1);