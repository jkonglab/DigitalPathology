function [New_good_pts_num, New_good_Ps,New_good_Qs]=Find_New_Good_Pts(list_ind,b,cann_pts,conn_lines,line_num,Connected_Pts,count,close_nonadj_pts,count_nonadj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find_New_Good_Pts finds those point pairs that need to be connected after
% a new point pair is connected
% Params:
%   list_ind is the index number of candidate points
%   b is the clumped nuclei boundary point coordinates
%   cann_pts is the candidate points
%   conn_lines records the connected lines
%   line_num is the number of connected point pairs
%   Connected_Pts records the connected points
%   count is the number of connected lines
%   close_nonadj_pts records the close nonadjacent point pairs
%   count_nonadj is the number of close nonadjacent point pairs
% Return:
%   ret indicates whether the point pair (p,q) is close nonadjacent or not
%
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global UNUSED;
global ANGLE;
global ARC;
global QUAL;
bpt = @(pt) b(list_ind(pt),:);
bpts = @(pt1, pt2) b(list_ind(pt1):list_ind(pt2),:);
N=length(list_ind);
k=line_num;
New_good_pts_num=0;
New_good_Ps=[];
New_good_Qs=[];
[unused_num,~]=Left_Unconnected(cann_pts,Connected_Pts);
% we stop splitting when unused points are less than the value of UNUSED
if unused_num<UNUSED
    return;
end

split_pts=Find_Split_pts(cann_pts,list_ind,close_nonadj_pts,count_nonadj);
if split_pts(1,1)&&split_pts(1,2)&&split_pts(2,1)&&split_pts(2,2)
    L=2;
elseif split_pts(1,1)&&split_pts(1,2)
    L=1;
else
    L=0;
end

if count>0||L
    for i=1:(count+L)
        diff=0;
        if i>count %I want to detect the case |--------|
            old_p=split_pts(i-count,1);
            old_q=split_pts(i-count,2);
            [old_p,old_q]=Swap_pq(old_p,old_q);
            [ret,num]=In_Connected_Pts(old_p,old_q,Connected_Pts);
            if num==0|| ~ret
                continue;
            end
            line=conn_lines{1,num};
        else
            if k-i+1>0         
            old_p=Connected_Pts(k-i+1,1);
            old_q=Connected_Pts(k-i+1,2);
            [old_p,old_q]=Swap_pq(old_p,old_q);
            line=conn_lines{1,k-i+1};
            else
                if L
                    continue;
                else
                    return;
                end
            end
        end
        p=Find_Before(old_p,cann_pts);
        %find the right next points in candidate points
        q=Find_Next(old_q,cann_pts);
        if p==old_q && q==old_p
            p=Find_Next(old_p,cann_pts);
            %find the right next points in candidate points
            q=Find_Before(old_q,cann_pts);
        end
        if Find_Same_In_Four_Pts(p,old_p,old_q,q)
            return;
        end
        curve=[]; 
        curve_1=[];
        curve_2=[];
        qual=[];
        c1=[];
        c2=[];
        c3=[];
        [In_1,num_1]=In_Connected_Pts(p,old_p,Connected_Pts);
        [In_2,num_2]=In_Connected_Pts(old_q,q,Connected_Pts);
        [~,num_3]=In_Connected_Pts(old_p,old_q,Connected_Pts);
        [In,num]=In_Connected_Pts(1,N,Connected_Pts);
        if In&&num~=0 % if (N,1) is connected, here we don't 
            if In_1&&num_1~=0
                curve_1 = [curve_1; conn_lines{1,num_1}];
            else
                [temp_p,temp_old_p]=Swap_pq(p,old_p);
                curve_1 = [curve_1; bpts(temp_p,temp_old_p)];
            end
            curve = [curve; conn_lines{1,num_3}];
            if In_2&&num_2~=0
                curve_2 = [curve_2; conn_lines{1,num_2}];
            else
                [temp_old_q,temp_q]=Swap_pq(old_q,q);
                curve_2 = [curve_2; bpts(temp_old_q,temp_q)];
            end       
        else%%%% if in&& num~=0
            if In_1&&num_1~=0
                 curve_1 = [curve_1; conn_lines{1,num_1}];
            elseif (old_p==N&&p==1)|| (old_p==1&&p==N)
                curve_1 = [curve_1; b(list_ind(end):end,:); b(1:list_ind(1),:)];
            else
                [temp_p,temp_old_p]=Swap_pq(p,old_p);
                curve_1 = [curve_1; bpts(temp_p,temp_old_p)];
            
            end
            curve = [curve; conn_lines{1,num_3}];
            if In_2&&num_2~=0
                curve_2 = [curve_2; conn_lines{1,num_2}];
            elseif (old_q==N&&q==1)|| (old_q==1&&q==N)
                curve_2 = [curve_2; b(list_ind(end):end,:); b(1:list_ind(1),:)];
            else
                [temp_old_q,temp_q]=Swap_pq(old_q,q);
                curve_2 = [curve_2; bpts(temp_old_q,temp_q)];
            end
        
        end
        c1=[c1;curve_1];
        c1=[c1;curve];
        c2=[c2;c1];
        c2=[c2;curve_2];
        c3=[c3,curve];
        c3=[c3;curve_2];
        
        qual(1) = measurequality(c1);
        qual(2) = measurequality(c2);
        qual(3) = measurequality(c3);
        max=0;
        max_qual=0;
        for t=1:3
            if qual(t)>max_qual
                max_qual=qual(t);
                max=t;
            end
        end
        if max_qual>QUAL        
            New_good_pts_num=New_good_pts_num+1;
            if max==1
            	diff=Compute_Angle_of_Two_Lines(old_p,old_q,p,b,list_ind);
                if abs(diff)<ANGLE
                	max=2;
                    New_good_Ps(New_good_pts_num)=p;
                    New_good_Qs(New_good_pts_num)=q;
                else
                    New_good_Ps(New_good_pts_num)=p;
                    New_good_Qs(New_good_pts_num)=old_q;
                end
            end
            if max==2
                New_good_Ps(New_good_pts_num)=p;
                New_good_Qs(New_good_pts_num)=q;
            end
            if max==3
                pt=Connected_Pts(num_3,1);
                qt=Connected_Pts(num_3,2);
                if In_2&&num_2~=0    
                    p_2=Connected_Pts(num_2,1);
                    q_2=Connected_Pts(num_2,2);
                    if p_2==pt
                        diff=Compute_Angle_of_Two_Lines(qt,q_2,pt,b,list_ind);
                    elseif p_2==qt
                        diff=Compute_Angle_of_Two_Lines(pt,q_2,qt,b,list_ind);
                    elseif q_2==pt
                        diff=Compute_Angle_of_Two_Lines(qt,p_2,pt,b,list_ind);
                    elseif q_2==qt
                        diff=Compute_Angle_of_Two_Lines(pt,p_2,qt,b,list_ind);
                    end 
                    if abs(diff)<ANGLE 
                    	max=2;
                        New_good_Ps(New_good_pts_num)=p;
                        New_good_Qs(New_good_pts_num)=q;
                    else       
                        New_good_Ps(New_good_pts_num)=old_p;
                        New_good_Qs(New_good_pts_num)=q;
                    end
                else
                	New_good_Ps(New_good_pts_num)=old_p;
                    New_good_Qs(New_good_pts_num)=q;
                end
            
            end
        end   
        
    end


if New_good_pts_num>0
    for t=1:New_good_pts_num
        temp_p=New_good_Ps(t);
        temp_q=New_good_Qs(t);
        [In_p,new_q,num_p]=A_Pt_In_Connected(temp_p,Connected_Pts);
        [In_q,new_p,num_q]=A_Pt_In_Connected(temp_q,Connected_Pts);
        if temp_p==new_p
            for j=t:New_good_pts_num-1
                New_good_Ps(j)=New_good_Ps(j+1);
                New_good_Qs(j)=New_good_Qs(j+1);
            end
            New_good_Ps(New_good_pts_num)=0;
            New_good_Qs(New_good_pts_num)=0;
            New_good_pts_num=New_good_pts_num-1;
            continue;
        end

        if New_good_Ps(t)&&New_good_Qs(t)
            if (abs(New_good_Ps(t)-New_good_Qs(t))==1)
                if t<New_good_pts_num
                    for m=t:New_good_pts_num-1
                        New_good_Ps(m)=New_good_Ps(m+1);
                        New_good_Qs(m)=New_good_Qs(m+1); 
                    end
                    New_good_pts_num=New_good_pts_num-1;
                    t=t-1;
                    continue;
                else
                    New_good_Ps(t)=0;
                    New_good_Qs(t)=0;
                    New_good_pts_num=New_good_pts_num-1;
                    return;
                end
            else
                New_good_Ps(t)=temp_p;
                New_good_Qs(t)= temp_q;
            end
        end
    end
    end
end

