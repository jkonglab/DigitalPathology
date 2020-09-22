function edgeTF = pedge(peaks, edge_canny, D, minD)

LongDisTF = D>minD;

[M,N] = size(edge_canny);
[m, ~] = size(peaks);
edgeTF = false(1, m*(m-1)/2);
unit_d = 0.1;

ind = 1;
for i = 1:(m-1)
    p2 = peaks(i,:);
    
    for j = (i+1):m
        if LongDisTF(ind)
            ind = ind + 1;
            continue;
        end
            
        p1 = peaks(j,:);
        
        dis = sqrt(sum((p1-p2).^2));
        n = ceil(dis/unit_d) + 2;
        x = round(linspace(p1(1), p2(1), n));
        x = min(N, max(1, x));
        y = round(linspace(p1(2), p2(2), n));
        y = min(M, max(1, y));
        
        TF = diag(edge_canny(y, x));
        if any(TF)
            edgeTF(ind) =  true;
        end
        
        ind = ind + 1;
        
    end
    %fprintf('Progress: %f%%\n', ind*100/length(edgeTF));
end
    
    