function [candidate_pts,curvature,new_close_adj_pts,new_count_adj,close_nonadj_pts,count_nonadj]=Merge_Close_Adj_Pts(b,close_adj_pts,curvature,list_ind,close_nonadj_pts,count_nonadj,count_adj,nonadj_close_distance,candidate_pts,remove_list)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Merge_Close_Adj_Pts function determines which point should be removed
% according to detected close adjacent point pairs
% Params:
%   b is the clumped nuclei boundary point coordinates
%   close_adj_pts records the close adjacent point pairs
%   curvature is the curvature value of candidate point pairs
%   close_nonadj_pts stores those close nonadjacent point pairs
%   list_ind is the index number of candidate points
%   close_nonadj_pts records the close nonadjacent point pairs
%   count_nonadj is the number of close nonadjacent point pairs
%   count_adj is the number of close adjacent point pairs
%   nonadj_close_distance records the distance of each close nonadjacent
%   point pair
%   candidate_pts records the candidate points
%   remove_list records the points that need to be removed
% Return:
%   candidate_pts records the updated candidate points
%   curvature is the unpdated curvature value of candidate point pairs
%   new_close_adj_pts is the updated close adjacent point pairs
%   new_count_adj is the number of the updated close adjacent point pairs
%   close_nonadj_pts is the updated close nonadjacent point pairs
%   count_nonadj is the number of the updated close nonadjacent point pairs
%   =======================================================================================
%   Copyright (C) 2018  Xiaoyuan Guo
%   Email: xiaoyuan.guo@emory.edu
%   =======================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global ARC;
new_close_adj_pts=zeros(count_adj,2);
new_count_adj=0;
count=0;
% Ls=[];

if count_adj
    close_adj_pts=Reduce_Null_Close_Pts(close_adj_pts,count_adj);
end
if count_adj>0
    for i=1:count_adj
        p=close_adj_pts(i,1);
        q=close_adj_pts(i,2);
        if p==0||q==0
            return;
        end
        if (p==length(list_ind)&&q==1)||(q==length(list_ind)&&p==1)
            temp=b(list_ind(end):end,:); b(1:list_ind(1),:);
            L=0;
            for m=q:length(temp(:,1))
                L =L+(sqrt(1+(temp(:,2)/temp(:,1))^2));
            end
%         Ls(i)=L;
        if L>ARC
            new_count_adj=new_count_adj+1;
            new_close_adj_pts(new_count_adj,1)=p;
            new_close_adj_pts(new_count_adj,2)=q;
            continue;   
        end    
    else
%         Ls(i)=arc_length(b, list_ind(p), list_ind(q));
        if arc_length(b, list_ind(p), list_ind(q)) > ARC
            new_count_adj=new_count_adj+1;
            new_close_adj_pts(new_count_adj,1)=p;
            new_close_adj_pts(new_count_adj,2)=q;
            continue;
        end
    end
     
    cur_p=curvature(p);
    cur_q=curvature(q);
    ret1=In_nonadj_cand_pts(p,0,close_nonadj_pts,count_nonadj);
    ret2=In_nonadj_cand_pts(q,0,close_nonadj_pts,count_nonadj);
    if cur_p<cur_q%remove low curvature points,in this case,it's p 
        count=count+1;
        if ret2&&~ret1
            if close_nonadj_pts(ret2,1)==q
               close_nonadj_pts(ret2,1)=p;
            else
               close_nonadj_pts(ret2,2)=p;
            end
        end
            remove_list(count)=q;      
    else
        count=count+1;
        if ret1&&~ret2
            if close_nonadj_pts(ret1,1)==p
               close_nonadj_pts(ret1,1)=q;
            else
               close_nonadj_pts(ret1,2)=q;
            end
        remove_list(count)=p;
        end
         
    end
end
end

L=length(remove_list);

for j=1:L-1
    pt=remove_list(j);
    for k=j+1:L
      qt=remove_list(k); 
      if pt==qt||qt==0
          for t=k:L-1
             remove_list(t)=remove_list(t+1);
          end
          remove_list(L)=0;
          L=L-1;
      end
    end
end

minus=0;
  for j=1:count_adj-1
      a1=close_adj_pts(j,1);
      b1=close_adj_pts(j,2);
      for t=j+1:count_adj
          a2=close_adj_pts(t,1);
          b2=close_adj_pts(t,2);
          if (a1==a2&&b1==b2)||(a1==b2&&a2==b1)
              for s=t:count_adj-1
                  close_adj_pts(s,1)=close_adj_pts(s+1,1);
                  close_adj_pts(s,2)=close_adj_pts(s+1,2);
              end
              close_adj_pts(s,1)=0;
              close_adj_pts(s,2)=0;
              minus=minus+1;
          end
      
      end
  end
count_adj=count_adj-minus;
if ~count_adj
    return
end

candidate_pts=Remove_Pts(candidate_pts,remove_list);

if length(count_adj)
    [close_nonadj_pts,count_nonadj]=Update_Close_Nonadj_pts(close_adj_pts,count_adj,close_nonadj_pts,count_nonadj,remove_list,nonadj_close_distance);
end



