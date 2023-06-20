# Network-Surveillance
Final Code for the Bsal/Network Surveillance paper

This contains the primary code files for generating the tiered, directed networks; assigning infected nodes and initial foci in those networks; plotting those networks; running the analysis on the population; and the files for the population used in the paper.

PRIMARY FUNCTIONS

AdjustableNetwork(num_nodes,goal_density,num_ports)
  Function for creating tiered directed networks with surveillance costs drawn from a uniform and exponential distribution.  Uses a seed graph of 20 nodes stored in code
  -num_nodes - desired number of nodes in graph
  -goal_density - desired graph density of the result.  Setting to 0 will result in a graph with densiity near 0.01
  -num_ports - desired number of ports in the graph
  Details for the cost distributions must be set explicitely in lines 131 and 132

NetworkList
  Script for producing and storing a population of networks produced with AdjustableNetwork


  
