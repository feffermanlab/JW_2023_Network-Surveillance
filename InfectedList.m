
inf_mat = zeros(100,numel(NetworkPop));
focus_list = zeros(numel(NetworkPop),1);
for k = 1:numel(NetworkPop)
    G = NetworkPop{k};
    inf_status = GraphSI(G);
    inf_mat(:,k) = inf_status;
    Ports = find(G.Nodes.Type == "Port");
    infected_nodes = find(inf_status);
    testable_nodes = setdiff(infected_nodes,Ports);
    focus_idx = datasample(testable_nodes,1);
    focus_list(k) = focus_idx;
end