function I=badStea_eachBlob_Xiaoyuan(I)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Given a binary mask that contains bad steatosis cases, seperate the clustered
% steatosis into individual ones, return the segmentation results
% Params:
%   I is an binary mask that contains bad steatosis cases 
% Return:
%   I is the segmentation result mask 
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%xiaoyuan
global Min_Distance;
Min_Distance=40;
global Max_Distance;
Max_Distance=50;
global Val_Nonclose;
Val_Nonclose=120;%150
SIGMA = 3;%6
global avg_area;
avg_area=60;%10
global QUALTHRESH;
QUALTHRESH= 1.3;%2.0
global QUAL;
QUAL= 1.0;%1.90
global ARC;
ARC = 10;
UNUSED=1;

if sum(I)==0
    fprintf("No bad steatosis need to be separated!\n")
    return
end

I1 = mat2gray(I);
I1 = imgaussfilt(I1, 2);
[B1, L1] = bwboundaries(I, 'noholes');
[Gmag, Gdir] = imgradient(I1,'prewitt');
stats = regionprops(L1, 'Area');
I = bwareaopen(I, round(mean([stats.Area])/10));
[B, L] = bwboundaries(I);
stats = regionprops(L, 'Area','Centroid');

% define gaussian kernel and its derivatives
t = ceil(3*SIGMA);
h = exp(-(-t:t).^2/(2*SIGMA^2)) / (SIGMA*sqrt(2*pi));
h = h/sum(h);

h1 = conv(h, [1 0 -1], 'valid');
h1 = h1 - sum(h1)/length(h1); %VERY IMPORTANT TO BRING sum(h1) to ZERO
h2 = conv(h1, [1 0 -1], 'valid');
h2 = h2 - sum(h2)/length(h2); %VERY IMPORTANT TO BRING sum(h2) to ZERO


for i = 1:length(B)
%      fprintf("Segment clump nuclei %d\n",i);
%      fprintf("***************************\n\n")
    b = B{i};
    ar=area(b);
%     if ar>1e4
%         continue
%     end
    %plot clumped nuclei boundaries 
    boundary=B{i};
%     plot(boundary(:,2),boundary(:,1),'g','linewidth',3);
   
    b(:,1) = imfilter(b(:,1), h' , 'circular', 'same', 'conv');
    b(:,2) = imfilter(b(:,2), h' , 'circular', 'same', 'conv');
%     plot(b(:,2), b(:,1), 'w', 'LineWidth', 2);
    
    % convolution with 1st and 2nd derivative of gaussian filter
    x1 = imfilter(B{i}(:,2), h1', 'circular', 'same', 'conv'); % conv2(B{i}(:,2), h1,'same') also works
    y1 = imfilter(B{i}(:,1), h1', 'circular', 'same', 'conv');
    x2 = imfilter(B{i}(:,2), h2', 'circular', 'same', 'conv');
    y2 = imfilter(B{i}(:,1), h2', 'circular', 'same', 'conv');
    %eps for return the minimum point precision
    %compute curvature values of every boundary point
    k = (x1.*y2 - y1.*x2)./(eps+(x1.^2+y1.^2).^(3/2));
    
       %% High curvature candidate point voting
%     fprintf("***Step1: High curvature points voting\n")
    [curvature,list_ind,n]=Find_Curv_Candidate_Points(k,b);
 
    if n>1
%         plot(b(list_ind,2), b(list_ind,1), 'yo', 'MarkerSize', 10);
%          for t = 1:length(list_ind)
%              str=sprintf('%2d',t);
%              text(b(list_ind(t),2),b(list_ind(t),1),str,'fontsize',20,'color',[1,0,1]);
%          end  
%          
        % When the area of the cluster is too small, return
        if  ar<1.5*avg_area
            continue;   
        end
        candidate_pts=linspace(1,n,n);%generate points index
         fprintf("***Step2:Detect close Adjacent points and Nonadjacent points using radius r_1\n")
        %% compute Euclidean distance between two points
        close_Mat=Close_Detection(list_ind,b);%close_Mat stores the distance value of each two points 
        [close_adj_pts,close_nonadj_pts,count_nonadj,count_adj,nonadj_close_distance]=close_pts(close_Mat,curvature,list_ind,b,Gmag, Gdir);
        Connected_Pts=zeros(2*n,2);%store connection information
        line_num=0;% record the number of connected lines
        conn_lines={1,n};% Init the conn_lines set
        %We split the whole boundary with close nonadjacent pointpairs 
        Candidate_pts={};%store the candidate pts for each seperated boundary
        % to filter those point pairs that don't need to merge
        
        [Ny, Nx, ~] = size(I1);
        %convert region of interest polygon to region mask
        bw_poly = poly2mask(b(:,2), b(:,1), size(I1,1),size(I1,2));
        bw_poly = imdilate(bw_poly, ones(1,1));    
        D = graydist(double(I1), ~bw_poly, 'quasi-euclidean');
        [gradDX,gradDY] = gradient(double(D),0.1,0.1);
        L2 = sqrt(gradDX.^2 + gradDY.^2);
        gradDX1=gradDX;
        gradDY1=gradDY;
        gradDX = gradDX./L2;
        gradDY = gradDY./L2;
%         fprintf("***Step2: Close Point Pair Screening\n");
%         fprintf("*******Step2.1: Analysis for Pairs of Adjacent Points in Proximit\n")
        [I,close_adj_pts,count_adj,conn_lines,Connected_Pts,line_num]=Augment_adj_Close(I,close_adj_pts,count_adj,list_ind,k,b,Gdir,conn_lines,Connected_Pts,line_num,Nx,Ny,gradDX,gradDY,close_nonadj_pts,count_nonadj);   
        remove_list=[];
%         fprintf("*******Step2.2: Analysis for Pairs of Non-Adjacent Points in Proximity\n")
        if count_adj>0
            [candidate_pts,curvature,new_close_adj_pts,new_count_adj,close_nonadj_pts,count_nonadj]=Merge_Close_Adj_Pts(b,close_adj_pts,curvature,list_ind,close_nonadj_pts,count_nonadj,count_adj,nonadj_close_distance,candidate_pts,remove_list);            
        elseif count_nonadj>0
            [close_nonadj_pts,count_nonadj]=Update_Close_Nonadj_pts(close_adj_pts,count_adj,close_nonadj_pts,count_nonadj,remove_list,nonadj_close_distance);
           
        end
        num_Candi_sets=1;
        if count_nonadj>0
            Candidate_pts={1,length(candidate_pts)+1};
            for j=1:count_nonadj
                p=close_nonadj_pts(j,1);
                q=close_nonadj_pts(j,2);
                if j==1||(j>1&&line_num==0)
                    last_line_num=line_num;
                    [I,conn_lines,Connected_Pts,line_num]=Connect_pts(I,p,q,b,list_ind,conn_lines,Connected_Pts,line_num);
                    if last_line_num==line_num
                        continue;
                    end
                    [cand_pts1,cand_pts2]=Split_Candidate_Pts(p,q,candidate_pts);
                    Candidate_pts{1,1}=cand_pts1;
                    Candidate_pts{1,2}=cand_pts2;
                    num_Candi_sets=num_Candi_sets+1;
                else
                    [p,q]=Swap_pq(p,q);
                    is_conn=line_num;
                    [I,conn_lines,Connected_Pts,line_num]=Connect_pts(I,p,q,b,list_ind,conn_lines,Connected_Pts,line_num);
                    is_conn=abs(is_conn-line_num);
                    if is_conn==0
                        continue
                    end

                    [new_candidate_pts,where]=In_Where_Candidatet(p,q, Candidate_pts,num_Candi_sets);
                    if ~where&&line_num
                          continue
                    end
                     
                    [cand_pts1,cand_pts2]=Split_Candidate_Pts(p,q,new_candidate_pts);
                    num_Candi_sets=num_Candi_sets+1;
                    Candidate_pts{1,where}=cand_pts1;
                    Candidate_pts{1,num_Candi_sets}=cand_pts2;                       
                end
            end
        
        end
        %%%%%%%%%%%%%%Split Candidate Points(End)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%         fprintf("***Step 3: Point Pair Segmentation Assessment by Ellipse Fitting\n");
        for it=1:num_Candi_sets
            if num_Candi_sets==1
                cann_pts=candidate_pts;           
            else 
            %evaluate the situation, if point number is small and the area
            %is small, stop segmentation
                ret=Eval_Cann_pts_Seg(Candidate_pts{1,it},b,list_ind,close_nonadj_pts,Connected_Pts,conn_lines,count_nonadj);
                if length(Candidate_pts{1,it})<=3
                    continue
                elseif ret
                    continue
                elseif length(Candidate_pts{1,it})==4
                    cann_pts_temp=Candidate_pts{1,it};
                    [ret1,num]=In_Connected_Pts(cann_pts_temp(1),cann_pts_temp(2),Connected_Pts);
                    [ret2,num]=In_Connected_Pts(cann_pts_temp(3),cann_pts_temp(4),Connected_Pts);
                    [ret3,num]=In_Connected_Pts(cann_pts_temp(1),cann_pts_temp(4),Connected_Pts);
                    [ret4,num]=In_Connected_Pts(cann_pts_temp(2),cann_pts_temp(3),Connected_Pts);
                if (ret1&&ret2)||(ret3&&ret4)
                    continue
                end 
            end           
            cann_pts= Candidate_pts{1,it};      
            end      
       [good_conn_pts_p,good_conn_pts_q,count]=Compute_Good_adj_Qual(list_ind,b,cann_pts,conn_lines,Connected_Pts);       
       go_on=true;

       if count 
           unused_num=length(cann_pts);
            for j=1:count%count is the number of good pts
                if (unused_num<UNUSED&& go_on==false)
                     continue
                end
                new_p=good_conn_pts_p(j);
                new_q=good_conn_pts_q(j);
                last_line_num=line_num;
                [I,conn_lines,Connected_Pts,line_num]=Connect_pts(I,new_p,new_q,b,list_ind,conn_lines,Connected_Pts,line_num);
                if last_line_num==line_num
                    continue
                end
                [unused_num,~,go_on]=Left_Unconnected(cann_pts,Connected_Pts);
                 
            end
       end
        
        %use count we could find the last filled connect lies
        [New_good_pts_num, New_good_Ps,New_good_Qs]=Find_New_Good_Pts(list_ind,b,cann_pts,conn_lines,line_num,Connected_Pts,count,close_nonadj_pts,count_nonadj);
        %To control the same point ptpairs repeated
        
        while New_good_pts_num       
            for t=1:New_good_pts_num
                st=false;
                new_p=New_good_Ps(t);
                new_q=New_good_Qs(t);
                last_line_num=line_num;
                [I,conn_lines,Connected_Pts,line_num]=Connect_pts(I,new_p,new_q,b,list_ind,conn_lines,Connected_Pts,line_num); 
                [unused_num,~,go_on]=Left_Unconnected(cann_pts,Connected_Pts);
                 if unused_num<=UNUSED|| ~go_on || (line_num==last_line_num)
                     st=true;
                    break;
                 end 
            end
             if unused_num<=UNUSED|| ~go_on ||st
                 break;
             end            
                [New_good_pts_num, New_good_Ps,New_good_Qs]=Find_New_Good_Pts(list_ind,b,cann_pts,conn_lines,line_num,Connected_Pts,count,close_nonadj_pts,count_nonadj);           
        end          
    end
        
    end
    
end

