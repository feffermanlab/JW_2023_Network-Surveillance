function h =  GraphLayerPlot(G)
if sum(ismember(G.Nodes.Type,"Port"))>0 && sum(ismember(G.Nodes.Type,"Retailer"))>0
    h = plot(G,'Layout','Layered','Sources',G.Nodes.Name(G.Nodes.Type=="Port"),'Sinks',G.Nodes.Name(G.Nodes.Type=="Retailer"));
elseif sum(ismember(G.Nodes.Type,"Retailer"))>0
    h = plot(G,'Layout','Layered','Sinks',G.Nodes.Name(G.Nodes.Type=="Retailer"));
elseif sum(ismember(G.Nodes.Type,"Port"))>0
    h = plot(G,'Layout','Layered','Sources',G.Nodes.Name(G.Nodes.Type=="Port"));
end
highlight(h,G.Nodes.Type=="Port",'Marker','v')  %'NodeColor',[0.6350 0.0780 0.1840])
highlight(h,G.Nodes.Type=="Distributer",'Marker','o') %'NodeColor',[0.8500 0.3250 0.0980])
highlight(h,G.Nodes.Type=="Retailer", 'Marker','s') %'NodeColor',[0.9290 0.6940 0.1250])

