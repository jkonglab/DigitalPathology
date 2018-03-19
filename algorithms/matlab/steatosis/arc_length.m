function arclen = arc_length(contour, a, b)

if a <= b
    start = a;
    dest = b;
else
    start = b;
    dest = a;
end

arclen = 0;
for i = start:dest-1
   d = sqrt((contour(i+1,2)-contour(i,2))^2+(contour(i+1,1)-contour(i,1))^2); 
   arclen = arclen + d;
end