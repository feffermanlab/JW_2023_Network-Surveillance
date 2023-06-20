
function [selected_cost,tested_count,pos_count,rounds] = Category_Convenience(G,CND,focus_idx,inf_status,cost_bound,sampling_treshold,total_infected)
    options = optimoptions('intlinprog','Display','iter'); %set solver options
    selected_cost = G.Nodes.Cost(focus_idx);
    
    tested = [focus_idx];
    pos_nodes = [focus_idx];
    positive_samples = [];
    rounds = 1;
    G_affordable_logical = G.Nodes.Cost<cost_bound;
    G_affordable = find(G_affordable_logical);

    %Determine if a port has been put into category 0
    while numel(pos_nodes)/total_infected < sampling_treshold
    %while (selected_cost < sampling_treshold) && (numel(pos_nodes)< total_infected)  
        rounds = rounds+1;
        %Nodes that have already been tested need to be thrown out of
        %consideration for further testing
        %Need to remove nodes from EQ as well
        tested_logical = ismember(CND,tested);
        tested_remover = ~tested_logical;
        affordable_logical = G.Nodes.Cost(CND)<cost_bound; %Keep only nodes that can be paid for
        tested_remover = tested_remover & affordable_logical;
        untested = setdiff(CND,tested);
        too_expensive = setdiff(CND,CND(affordable_logical));

        if numel(setdiff(untested,too_expensive))==0
            %If the only nodes left to test are too expensive, select
            %randomly from G
            
            sample_pool = setdiff(G_affordable,CND);
            sample_pool = setdiff(sample_pool,tested);
            if numel(sample_pool)>0
                 intcon = 1:numel(sample_pool);
                lb = zeros(numel(sample_pool),1);
                ub = ones(numel(sample_pool),1);
                node_scores = ones(numel(sample_pool),1);
                costs = G.Nodes.Cost(sample_pool);
                x =intlinprog(-node_scores,intcon,costs',cost_bound,[],[],lb,ub,[],options);
                selected = sample_pool(logical(x));
                %selected = datasample(sample_pool,1);
            else
                break;
            end
        else

            node_scores = ones(numel(CND),1).*tested_remover; %0 out scores of tested nodes
    
            %Do the optimization
            intcon = 1:numel(CND);
            lb = zeros(numel(CND),1);
            ub = ones(numel(CND),1);
        
            %I want a second version that just tests as many nodes as possible for
            %the cheapest cost
            x =intlinprog(-node_scores,intcon,G.Nodes.Cost(CND)',cost_bound,[],[],lb,ub,[],options);
            %I want a third version that randomly picks as many nodes from
            %categories 1 and 2 as possible and otherwise picks randomly up to
            %cost_bound
            
            selected = CND(logical(x));
        end
        tested = [tested;selected]; %Keep track of tested nodes
        %Get infection status of infected nodes
        selected_cost = sum(G.Nodes.Cost(selected))+selected_cost;
        selected_logical = zeros(numnodes(G),1);
        selected_logical(selected) = 1;
        selected_logical = logical(selected_logical);
        positive_samples_logical = selected_logical & inf_status;
        new_positive_samples = find(positive_samples_logical);
        positive_samples = [positive_samples;new_positive_samples];
        pos_nodes = unique([pos_nodes;positive_samples]);
        
        if numel(new_positive_samples) >0
        for s = 1:numel(new_positive_samples)
            focus_idx= new_positive_samples(s);
            neighborhood1 = [predecessors(G,focus_idx);successors(G,focus_idx)];
            neighborhood2 = [];
            for i = 1:numel(neighborhood1)
                neighborhood2 = [neighborhood2;predecessors(G,neighborhood1(i));successors(G,neighborhood1(i))];
            end
            CND = unique([focus_idx;neighborhood1;neighborhood2;CND]);
        end
        end

    end
    tested_count = numel(tested);
    pos_count = numel(pos_nodes);   
end