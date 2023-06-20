
function categories = CategorizeTemp(G,CND,focus_idx)
    categories = -1*ones(numel(CND),1);
    categories(CND==focus_idx) = 0;
    focus = G.Nodes.Name(focus_idx);
    focus_idx = find(CND == focus_idx);
H = subgraph(G,CND);

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
    
% hplot = GraphLayerPlot(H);
% highlight(hplot,focus,'Marker','p','MarkerSize',10);

    %Get the ancestor graph
    anc_idx = bfsearch(flipedge(H),focus);
    anc = H.Nodes.Name(anc_idx);
    anc_digraph = subgraph(H,anc);
    og_anc_digraph = anc_digraph; %storing for later in case it's needed
    og_anc = anc;
    %Check to see if the focus appears in a cycle.
    if hascycles(H)
        cycles = allcycles(H);
        for k = 1:numel(cycles)
            if sum(ismember(cycles{k},focus))>0 %focus is in a cycle, use graph condensation
                C = condensation(anc_digraph);
                bins = conncomp(anc_digraph);
                focus_anc_idx = find(ismember(anc_digraph.Nodes.Name,focus)); %get focus index in ancestor graph
                focus_comp = bins(focus_anc_idx); %get the focus bin number
                focus_comp_idx = find(bins==focus_comp); %get the indices for the other nodes in the focus cycle
                name_list = anc_digraph.Nodes.Name; %create a new name list for naming nodes in the condensation graph
                focus_cycle_names = name_list(focus_comp_idx); %get the focus cycle node names to set their category
                name_list(focus_comp_idx(2:end)) = []; %rename the nodes in the focus cycle with the focus name
                bins = unique(bins,'stable'); %cut out the repeats in bins but keep the same order
                [~,binsort] = sort(bins); %get a permutation vector that would order the bin numbers
                C.Nodes.Name = name_list(binsort); %sort the name list according to the permutation and pass to the condensation graph
    
                categories(ismember(H.Nodes.Name,setdiff(focus_cycle_names,focus))) = 1;
    
                anc_digraph = C;
                anc = C.Nodes.Name;
            end
        end
    end
    

    %Get paths from sources to focus
     sources_logical = indegree(anc_digraph)==0;
    sources = anc_digraph.Nodes.Name(sources_logical);
      true_anc = setdiff(anc,focus);
    if numel(true_anc)>0
      all_paths = cell(numel(true_anc),1);
    path_count = zeros(numel(true_anc),1);
  
    for n = 1:numel(true_anc)
        paths = allpaths(anc_digraph,true_anc(n),focus);
        path_count(n) = numel(paths);
        all_paths{n} = paths;
    end
    %Clean up paths into something easier to work with
    all_paths_list = cell(sum(path_count),1);
    adder = 0;
    for k = 1:numel(all_paths)
        for j = 1:path_count(k)
        all_paths_list{k+adder} = all_paths{k}{j};
            if j ~= path_count(k)
                adder = adder+1;
            end
        end
    end
    
    if numel(sources)>1 || indegree(anc_digraph,focus)>1 %multiple paths to focus
        preds_name = predecessors(anc_digraph,focus);
        preds_logical = ismember(H.Nodes.Name,preds_name);
        categories(preds_logical) = 2;
    
        %Intersect across all paths
        if (indegree(H,focus)==1 || numel(sources)==1) && (numel(all_paths_list)>1)
            intersection = intersect(all_paths_list{1},all_paths_list{2});
            for n = 3:numel(all_paths_list)
                intersection = intersect(intersection,all_paths_list{n});
            end
            intersection_logical = ismember(H.Nodes.Name,intersection);
            intersection_logical(focus_idx) = 0;
            categories(intersection_logical) = 1; %any nonfocus node appearing along each path is category 1
        end
        
        %Categorize nodes that lie along a single path to the focus
        sp_sources_idx = find(path_count==1); %Gives index in all_paths
        dec_idx = bfsearch(H,focus);
        dec = H.Nodes.Name(dec_idx);
        dec = setdiff(dec,focus);
        for k = 1:numel(sp_sources_idx)
            intersection = [focus];
            ref_path = all_paths{sp_sources_idx(k)}{1};
            for j = 1:numel(all_paths_list) %numel(sp_sources_idx)
                comp_path = all_paths_list{j}; %all_paths{sp_sources_idx(j)}{1};
                if numel(setdiff(ref_path,comp_path))~=0 && numel(setdiff(comp_path,ref_path))~=0
                    intersection = [intersection intersect(ref_path,comp_path)];
                end
            end
            cat1_nodes = [H.Nodes.Name(categories==1); focus];
            cat1_nodes = setdiff(cat1_nodes,dec);
            intersection = unique(intersection);
            if numel(setdiff(cat1_nodes,intersection))==0 && numel(setdiff(intersection,cat1_nodes))==0 %all paths contain focus, ref path didn't intersect other paths
                ref_path = setdiff(ref_path,cat1_nodes); %Don't want to reassign the focus
                ref_path_logical = ismember(H.Nodes.Name,ref_path);
                categories(ref_path_logical) = 2;
            end
        end
        uncat_logical = categories==-1;
        sources_logical = ismember(H.Nodes.Name,sources);
        categories(uncat_logical & sources_logical) = 3;
    
        uncat_logical = categories == -1;
        uncat_names = H.Nodes.Name(uncat_logical);
        multipath_sources = true_anc(path_count>1);
        uncat_multipath_sources = intersect(multipath_sources,uncat_names);
        for k=1:numel(uncat_multipath_sources)
            pathset = all_paths(ismember(true_anc,uncat_multipath_sources(k)));
            second_nodes = [];
            for j=1:numel(pathset{1})
                second_nodes = [second_nodes {pathset{1}{j}{2}}];
            end
            if numel(unique(second_nodes))==1
                categories(ismember(H.Nodes.Name,uncat_multipath_sources(k))) = 3;
            end
        end
        %categorize nodes 2 edges from the focus in the ancestor graph that have nonzero indegree
        anc_distances = min(distances(og_anc_digraph,og_anc,focus),distances(og_anc_digraph,focus,og_anc)');
        anc_2edges = anc_distances==2;
        anc_2edges_name = og_anc_digraph.Nodes.Name(anc_2edges);
        anc_2edges_H_logical = ismember(H.Nodes.Name,anc_2edges_name);
        anc_indegree_logical = indegree(og_anc_digraph)>0;
        anc_indegree_name = og_anc_digraph.Nodes.Name(anc_indegree_logical);
        anc_indegree_H_logical = ismember(H.Nodes.Name,anc_indegree_name);
        dec_idx = bfsearch(H,focus);
        dec_names = H.Nodes.Name(dec_idx);
        dec_H_logical = ismember(H.Nodes.Name,dec_names);
    
        categories(anc_2edges_H_logical & anc_indegree_H_logical & ~dec_H_logical) = 4;
        categories(anc_2edges_H_logical & anc_indegree_H_logical & dec_H_logical) = 5;
    
    else %single path to focus must be cat 1
        inf_path = all_paths{1};
        inf_path_logical = ismember(H.Nodes.Name,setdiff(inf_path{1},focus));
        categories(inf_path_logical) = 1;
    end
end
    %At this point, the ancestor graph is fully categorized.  
    %Categorize focus descendants as cat 1
    dec_idx = bfsearch(H,focus);
    dec_names = H.Nodes.Name(dec_idx); %takes 2 steps to convert to a logical vector anyway
    dec_logical = ismember(H.Nodes.Name,dec_names);
    uncat_logical = categories==-1;
    categories(dec_logical & uncat_logical) = 1;
    
    %Categorize nodes exactly 2 edges away from the focus that are not part of
    %the ancestor graph
    uncat_logical = categories == -1;
    focus_preds = predecessors(H,focus);
    preds_logical = ismember(H.Nodes.Name,focus_preds);
    A = adjacency(H);
    dec_logical = logical(A'*preds_logical);
    H_0_outdegrees_logical = outdegree(H)==0;
    categories(uncat_logical & dec_logical & ~H_0_outdegrees_logical) = 6;
    
    %Categorize predecessor descendants as cat 7
    uncat_logical = categories ==-1;
    categories(uncat_logical & H_0_outdegrees_logical) = 7;
    
    %Categorize descendant predecessors as cat 8
    uncat_logical = categories == -1;
    H_0_indegrees_logical = indegree(H)==0;
    categories(uncat_logical & H_0_indegrees_logical) = 8;
    
    
    % anc_digraph = og_anc_digraph; %reset for graphing
    % 
%      figure();
%         h2 = GraphLayerPlot(H);
%         h2.MarkerSize=7;
%         highlight(h2,categories==0,'NodeColor',[0.6350 0.0780 0.1840]);
%         highlight(h2,categories==1,'NodeColor',[0.8500 0.3250 0.0980]);
%         highlight(h2,categories == 2,'NodeColor',[0.92, 0.92, 0.20]);
%         highlight(h2,categories==3,'NodeColor','green');
%         highlight(h2,categories==4,'Marker','h','MarkerSize',10);
%         highlight(h2,categories==5,'NodeColor',[0.8500 0.3250 0.0980],'Marker','h','MarkerSize',10);
%         highlight(h2,categories==6,'NodeColor','black','Marker','h');
%         highlight(h2,categories==7,'NodeColor','cyan');
%         highlight(h2,categories==8,'NodeColor','black');
%         highlight(h2,focus,'Marker','p','MarkerSize',10);
    % 
    % anc_categories = zeros(numnodes(anc_digraph),1);
    % for k = 1:numnodes(anc_digraph)
    %     node_name = anc_digraph.Nodes.Name(k);
    %     node_H_logical = ismember(H.Nodes.Name,node_name);
    %     anc_categories(k) = categories(node_H_logical);
    % end
    %  figure();
    %     h3 = GraphLayerPlot(anc_digraph);
    %     h3.MarkerSize=7;
    %     highlight(h3,anc_categories==0,'NodeColor',[0.6350 0.0780 0.1840]);
    %     highlight(h3,anc_categories==1,'NodeColor',[0.8500 0.3250 0.0980]);
    %     highlight(h3,anc_categories == 2,'NodeColor',[0.92, 0.92, 0.20]);
    %     highlight(h3,anc_categories==3,'NodeColor','green');
    %     highlight(h3,anc_categories==4,'Marker','h','MarkerSize',10);
    %     highlight(h3,anc_categories==5,'NodeColor',[0.8500 0.3250 0.0980],'Marker','h','MarkerSize',10);
    %     highlight(h3,focus,'Marker','p','MarkerSize',10);
end