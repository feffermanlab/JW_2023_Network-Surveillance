% TieredNetworkPop={TieredTradeNetwork(40)};
% for i = 1:300
%     TieredNetworkPop=cat(1,TieredNetworkPop,{TieredTradeNetwork(40)});
% end
% NetworkPop={TradeNetwork};
% for i = 1:100
%     NetworkPop=cat(1,NetworkPop,{TradeNetwork});
% end

NetworkPop={AdjustableNetwork(100,0.0251,10)};
            for i = 1:500-1
                NetworkPop=cat(1,NetworkPop,{AdjustableNetwork(100,0.0251,10)});
            end