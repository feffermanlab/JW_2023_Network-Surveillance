
function [selected_cost,tested_count,pos_count,rounds] = Category_Informed(G,CND,focus_idx,inf_status,cost_bound,sampling_treshold,total_infected)
    options = optimoptions('intlinprog','Display','off'); %set solver options
    selected_cost = G.Nodes.Cost(focus_idx);
    focus = G.Nodes.Name(focus_idx);
    og_focus = focus; %a lazy fix to needing this later

    cats_mat = inf*ones(numnodes(G),numnodes(G));

    local_cats = CategorizeTemp(G,CND,focus_idx);
    cats_mat(focus_idx,CND) = local_cats';
    cats = min(cats_mat);
    cats(cats == inf) = [];
        
    %% Plotting the Local Graph

%         H = subgraph(G,CND);
%     %Remove edges that are between nodes that are 2 away from the focus
%     neighborhood1 = [predecessors(G,focus);successors(G,focus)];
%     outer = setdiff(H.Nodes.Name,neighborhood1);
%     outer = setdiff(outer,focus);
%     % Matlab's subgraph command is based on nodes and will include any edges
%     % that exist between nodes.  Our subgraphs have all the graph information
%     % for the focal node and its predecessors and successors (1-neighborhood),
%     % but not for nodes that are 2 edges away from the focal node.  The loop
%     % removes any edges that exist between nodes in the outer 2-radius ring.
%     for outer1 = 1:numel(outer)
%         for outer2 = 1:numel(outer)
%             idx = findedge(H,outer(outer1),outer(outer2));
%             if idx ~=0
%                 H = rmedge(H,idx);
%             end
%         end
%     end
%     figure();
%     h2 = GraphLayerPlot(H);
%     h2.MarkerSize=7;
%     highlight(h2,cats==0,'NodeColor',[0.6350 0.0780 0.1840]);
%     highlight(h2,cats==1,'NodeColor',[0.8500 0.3250 0.0980]);
%     highlight(h2,cats == 2,'NodeColor',[0.92, 0.92, 0.20]);
%     highlight(h2,cats==3,'NodeColor','green');
%     highlight(h2,cats==4,'Marker','h','MarkerSize',10);
%     highlight(h2,cats==5,'NodeColor',[0.8500 0.3250 0.0980],'Marker','h','MarkerSize',10);
%     highlight(h2,cats==6,'NodeColor','black','Marker','h');
%     highlight(h2,cats==7,'NodeColor','cyan');
%     highlight(h2,cats==8,'NodeColor','black');
%     highlight(h2,focus,'Marker','p','MarkerSize',10);
%%

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
        tested_remover = ~tested_logical; %Need 0s at tested nodes
        affordable_logical = G.Nodes.Cost(CND)<cost_bound; %Keep only nodes that can be paid for
        
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
            tested_remover = tested_remover & affordable_logical;
        
            cat_scores = 0*(cats==0)+3*(cats==1)+1*(cats==2)+0.25*(cats==3)+1*(cats==4)+1*(cats==5)+0.1*(cats==6)+0.1*(cats==7)+0.1*(cats==8); %0 1 0.8 0.5 0.8 1 0.5 0.25 0.1
            
            node_scores = cat_scores;
            
            node_scores = node_scores.*tested_remover'; %0 out scores of tested nodes
            
            %Do the optimization
            intcon = 1:numel(CND);
            lb = zeros(numel(CND),1);
            ub = ones(numel(CND),1);
        
            x = intlinprog(-node_scores,intcon,G.Nodes.Cost(CND)',cost_bound,[],[],lb,ub,[],options);
     
        
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
    
        if numel(new_positive_samples)>0
         for s = 1:numel(new_positive_samples)
            focus_idx= new_positive_samples(s);
            neighborhood1 = [predecessors(G,focus_idx);successors(G,focus_idx)];
            neighborhood2 = [];
            for i = 1:numel(neighborhood1)
                neighborhood2 = [neighborhood2;predecessors(G,neighborhood1(i));successors(G,neighborhood1(i))];
            end
            CND = unique([focus_idx;neighborhood1;neighborhood2;CND]);
        end

        for s = 1:numel(new_positive_samples) 
            focus_idx= new_positive_samples(s);
            neighborhood1 = [predecessors(G,focus_idx);successors(G,focus_idx)];
            neighborhood2 = [];
            for i = 1:numel(neighborhood1)
                neighborhood2 = [neighborhood2;predecessors(G,neighborhood1(i));successors(G,neighborhood1(i))];
            end
            local_CND = sort(unique([focus_idx;neighborhood1;neighborhood2]));
            local_cats = CategorizeTemp(G,local_CND,new_positive_samples(s));
            %% Plotting the Local Graph

                    H = subgraph(G,local_CND);
                    focus = G.Nodes.Name(focus_idx);
                    %Remove edges that are between nodes that are 2 away from the focus
                    neighborhood1 = [predecessors(G,focus);successors(G,focus)];
                    outer = setdiff(H.Nodes.Name,neighborhood1);
                    outer = setdiff(outer,focus);
                    % Matlab's subgraph command is based on nodes and will include any edges
                    % that exist between nodes.  Our subgraphs have all the graph information
                    % for the focal node and its predecessors and successors (1-neighborhood),
                    % but not for nodes that are 2 edges away from the focal node.  The loop
                    % removes any edges that exist between nodes in the outer 2-radius ring.
                    for outer1 = 1:numel(outer)
                        for outer2 = 1:numel(outer)
                            idx = findedge(H,outer(outer1),outer(outer2));
                            if idx ~=0
                                H = rmedge(H,idx);
                            end
                        end
                    end
%                     figure();
%                     h2 = GraphLayerPlot(H);
%                     h2.MarkerSize=7;
%                     highlight(h2,local_cats==0,'NodeColor',[0.6350 0.0780 0.1840]);
%                     highlight(h2,local_cats==1,'NodeColor',[0.8500 0.3250 0.0980]);
%                     highlight(h2,local_cats == 2,'NodeColor',[0.92, 0.92, 0.20]);
%                     highlight(h2,local_cats==3,'NodeColor','green');
%                     highlight(h2,local_cats==4,'Marker','h','MarkerSize',10);
%                     highlight(h2,local_cats==5,'NodeColor',[0.8500 0.3250 0.0980],'Marker','h','MarkerSize',10);
%                     highlight(h2,local_cats==6,'NodeColor','black','Marker','h');
%                     highlight(h2,local_cats==7,'NodeColor','cyan');
%                     highlight(h2,local_cats==8,'NodeColor','black');
%                     highlight(h2,focus,'Marker','p','MarkerSize',10);
%%
            cats_mat(focus_idx,local_CND) = local_cats';
        end
        end
    cats = min(cats_mat);
    cats(cats == inf) = [];
    end
    tested_count = numel(tested);
    pos_count = numel(pos_nodes);
end