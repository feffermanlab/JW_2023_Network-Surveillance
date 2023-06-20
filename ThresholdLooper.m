close all;
pop_size = numel(NetworkPop);
range =.1:.05:.9;
results_mat = -1*ones(pop_size,numel(range));
parfor pop_count =1:numel(NetworkPop)
%G = AdjustableNetwork(100,0.0,16);
G = NetworkPop{pop_count};
%steps = 20;
inf_status = inf_mat(:,pop_count);
total_infected = sum(inf_status);
focus_idx = focus_list(pop_count);
%focus = {'49'};
G.Nodes.Cost = G.Nodes.CostUni;
%G.Nodes.Cost = G.Nodes.CostExp;
cost_bound = .05*sum(G.Nodes.Cost); %Reset cost bound as percentage of total network cost here
toutcome = zeros(1,numel(range));
TIcol = 1;
for TI = range
threshold = TI;%*sum(G.Nodes.Cost);

%Build the 2-neighborhood
neighborhood1 = [predecessors(G,focus_idx);successors(G,focus_idx)];
neighborhood2 = [];
for i = 1:numel(neighborhood1)
    neighborhood2 = [neighborhood2;predecessors(G,neighborhood1(i));successors(G,neighborhood1(i))];
end
CND = sort(unique([focus_idx;neighborhood1;neighborhood2]));

[cost1,tested1,pos1,rounds1] = Category_Informed(G,CND,focus_idx,inf_status,cost_bound,threshold,total_infected);
[cost2,tested2, pos2,rounds2] = Category_Convenience(G,CND,focus_idx,inf_status,cost_bound,threshold,total_infected);

%toutcome(TIcol) =pos1>=pos2;
toutcome(TIcol) = cost1 <= cost2;
TIcol = TIcol+1;
%outcome_mat = [str2num(str2mat(G.Nodes.Name)) inf_status EQ1];
end
results_mat(pop_count,:) = toutcome;
end
%save('results_mat_SIS_uni_n100_trange.mat');