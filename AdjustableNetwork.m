% close all;

function G=AdjustableNetwork(node_number,goal_density,num_ports)

% p_p = 0.1;

A= zeros(20,20);
G = digraph(A);

G.Nodes.Name = {'1' '2' '3' '4' '5' '6' '7' '8' '9' '10' '11' '12' '13' '14' '15' '16' '17' '18' '19' '20'}';
G.Nodes.Type = repelem(["Port", "Distributer","Retailer"],[4,7,9])';

out_nodes = [ 1 1 2 2 3 4 4 5 6 7 8 9 10 10 11 11 3] ;
in_nodes = [5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 12];

G = addedge(G,out_nodes,in_nodes,1);
new_nodes = 0;
node_count = 21;
while (new_nodes < node_number-20) %node_number minus nodes in seed graph
    new_name = num2str(node_count);
    q = rand();
    if 0 <= q && q < 5/20 %Add port connect the port to existing Distributer
        if sum(G.Nodes.Type=="Port") >= num_ports
            continue;
        end
        G = addnode(G,table({new_name},"Port",'VariableNames',{'Name','Type'}));
        curr_rec = [G.Nodes.Name(G.Nodes.Type=="Distributer")];
        pick_rec = datasample(curr_rec,1,'Weights',indegree(G,curr_rec));
        G = addedge(G,new_name,pick_rec,1);
        new_nodes = new_nodes+1;
        node_count = node_count+1;
% The code below attaches the new port to additional distributers
%         r = poissrnd(1,1);
%         curr_opts = [G.Nodes.Name(G.Nodes.Type=="Distributer")];
%         curr_connections = [successors(G,new_name);new_name];
%         allowed_opts = setdiff(curr_opts,curr_connections);
%         pick_opts = datasample(allowed_opts,r,'Replace',false,'Weights',indegree(G,allowed_opts)+outdegree(G,allowed_opts));
%         pick_opts = str2num(str2mat(pick_opts));
%         new_name = str2num(new_name);
%         G = addedge(G, repelem(new_name,numel(pick_opts)),pick_opts',ones(numel(pick_opts),1));

    elseif 5/20 <= q && q < 13/20 %Add a distributer and connect to a (Port or Distributer) and a (Distributer or Retailer)
        G = addnode(G,table({new_name},"Distributer",'VariableNames',{'Name','Type'}));
        curr_senders = [G.Nodes.Name(G.Nodes.Type=="Port");G.Nodes.Name(G.Nodes.Type=="Distributer")];
        curr_senders = setdiff(curr_senders,new_name); %Ensure the added node isn't picked
        pick_sender = datasample(curr_senders,1,'Weights',outdegree(G,curr_senders));
        curr_rec = [G.Nodes.Name(G.Nodes.Type=="Distributer");G.Nodes.Name(G.Nodes.Type=="Retailer")];
        curr_rec = setdiff(curr_rec,new_name); %Ensure the added node isn't picked
        curr_rec = setdiff(curr_rec,pick_sender); %Ensure sending node isn't picked
        pick_rec = datasample(curr_rec,1,'Weights',indegree(G,curr_rec));
        G = addedge(G,[pick_sender new_name],[new_name pick_rec],[1 1]);
        new_nodes = new_nodes+1;
        node_count = node_count+1;
% The code below connects the new distributer to additional nodes
%         r = poissrnd(1,1);
%         curr_opts = [G.Nodes.Name(G.Nodes.Type=="Port");G.Nodes.Name(G.Nodes.Type=="Distributer");G.Nodes.Name(G.Nodes.Type=="Retailer")];
%         curr_connections = [predecessors(G,new_name);successors(G,new_name);new_name];
%         allowed_opts = setdiff(curr_opts,curr_connections);
%         pick_opts = datasample(allowed_opts,r,'Replace',false,'Weights',indegree(G,allowed_opts)+outdegree(G,allowed_opts));
%         pick_opts = str2num(str2mat(pick_opts));
%         for k = 1:numel(pick_opts)
%             if G.Nodes.Type(pick_opts(k))=="Port"
%                 G = addedge(G,pick_opts(k),str2num(new_name),1);
%             elseif G.Nodes.Type(pick_opts(k))=="Retailer"
%                 G = addedge(G,str2num(new_name),pick_opts(k),1);
%             else
%                 s = rand();
%                 if s<.5
%                     G = addedge(G,str2num(new_name),pick_opts(k),1);
%                 else
%                     G = addedge(G,pick_opts(k),str2num(new_name),1);
%                 end
%             end
%         end
    else
        G = addnode(G,table({new_name},"Retailer",'VariableNames',{'Name','Type'})); %Add a retailer and connect to a Port or Distributer
        curr_senders = [G.Nodes.Name(G.Nodes.Type=="Distributer")];
        r = 1; %poissrnd(1,1)+1;
        pick_senders = datasample(curr_senders,r,'Replace',false,'Weights',outdegree(G,curr_senders));
        new_name=repmat({new_name},r,1);
        G = addedge(G,pick_senders,new_name,ones(r,1));
        new_nodes = new_nodes+1;
        node_count = node_count+1;
    end
end

G.Edges.Weight = ones(numedges(G),1);

for k=1:numnodes(G)
    type = G.Nodes.Type{k};
    if type == "Port"
        G.Nodes.NodeColor{k}=[1 0 0];
    elseif type == "Distributer"
        G.Nodes.NodeColor{k}=[0 1 0];
    else
        G.Nodes.NodeColor{k}=[0 0 0];
    end
end

%Add edges to get the desired density
density = numedges(G)/(numnodes(G)*(numnodes(G)-1));
Ports = G.Nodes.Name(G.Nodes.Type=="Ports");
Distributers = G.Nodes.Name(G.Nodes.Type=="Distributer");
Retailers = G.Nodes.Name(G.Nodes.Type=="Retailer");
while density<goal_density
    node1 = datasample(G.Nodes.Name,1);
    if NodeType(G,node1)=="Port"
        succs = successors(G,node1);
        non_succs = setdiff(Distributers,succs); %Could be empty
        node2 = datasample(non_succs,1);
        G = addedge(G,node1,node2,1);
    elseif NodeType(G,node1)=="Retailer"
        preds = predecessors(G,node1);
        non_preds = setdiff(Distributers,preds);
        node2 = datasample(non_preds,1);
        G = addedge(G,node2,node1,1);
    else %node1 is a Distributer
        neighs = [node1;predecessors(G,node1);successors(G,node1)];
        non_neighs = setdiff([Ports;Distributers;Retailers],neighs);
        node2 = datasample(non_neighs,1);
        if NodeType(G,node2)=="Port"
            G = addedge(G,node2,node1,1);
        else %node2 is retailer or distributer
            G=addedge(G,node1,node2,1);
        end
    end
    
    density = numedges(G)/(numnodes(G)*(numnodes(G)-1));
end

G.Nodes.CostUni = .6*rand(numnodes(G),1)+.2; %Uniform
G.Nodes.CostExp = exprnd(.25,numnodes(G),1)+0.25 ; %exponential
end

%figure();
%plot(G,'Layout','Layered','Source',G.Nodes.Name(G.Nodes.Type=="Port"),'Sinks',G.Nodes.Name(G.Nodes.Type=="Retailer"))



function type = NodeType(G,name)
    idx = find(ismember(G.Nodes.Name,name));
    type = G.Nodes.Type(idx);
end