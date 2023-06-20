function infection_status = GraphSI(G)

infected_port_name = datasample(G.Nodes.Name(G.Nodes.Type=="Port"),1);
infected_idx = find(ismember(G.Nodes.Name,infected_port_name));

dec = bfsearch(G,infected_idx);
infection_status = zeros(numnodes(G),1);
infection_status(dec) = 1;