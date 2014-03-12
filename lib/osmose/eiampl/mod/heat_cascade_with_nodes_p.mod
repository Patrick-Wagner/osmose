# Heatcascade_with_node_period 1857 2010-11-11 08:45:17Z Author:S.Fazlollahi
# $Id: Heatcascade_with_node_period 1857 2010-11-11 08:45:17Z fazlollahi $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Heat Cascade with Nodes 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




# Hot streams of Heat transfer system 
set HC_HTS_Hot {ly in HeatCascades, lc in LocationsOfLayer[ly], t in Time}  within Streams :=
	{s in StreamsOfLayer[ly] : Streams_Hout[ly,s,t]<Streams_Hin[ly,s,t] and s in HTSStreamsOfLocation[lc] and s in StreamsOfTime[t]};

	check {ly in HeatCascades, lc in LocationsOfLayer[ly], t in Time}: card(HC_HTS_Hot[ly,lc,t]) > 0;
	
# Cold streams of Heat transfer system 
set HC_HTS_Cold {ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time}  within Streams :=
	{s in StreamsOfLayer[ly] : Streams_Hout[ly,s,t]>Streams_Hin[ly,s,t] and s in HTSStreamsOfLocation[lc] and s in StreamsOfTime[t]};

check {ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time}: card(HC_HTS_Cold[ly,lc,t]) > 0;	

# Hot streams of Nodes 
set HC_Nodes_Hot{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc],t in Time} within Streams :=
{s in StreamsOfLayer[ly] : Streams_Hout[ly,s,t]<Streams_Hin[ly,s,t] and s in StreamsOfNode[n] and s in StreamsOfTime[t]};

#    check {ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc],t in Time}: card(HC_Nodes_Hot[ly,lc,n,t]) > 0;
	
# Cold streams of Nodes 
set HC_Nodes_Cold{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], t in Time} within Streams :=
{s in StreamsOfLayer[ly] : Streams_Hout[ly,s,t]>Streams_Hin[ly,s,t] and s in StreamsOfNode[n] and s in StreamsOfTime[t]};

#    check {ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], t Time}: card(HC_Nodes_Cold[ly,lc,n,t]) > 0;


#-------------------------------------------------------------------------

### Variables 
## ---------------------------------------------------------------------------------------------------------------------------------------------------

# Rk for the heat transfer system 
var HC_HTS_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time,k in HC_TempIntervals[ly,lc,t]}>=0;
var HC_Nodes_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc],t in Time, k in HC_TempIntervals[ly,lc,t]}>=0;
# Sum of HC_HTS_Rk and HC_Nodes_Rk (used to identify pinch points)
var HC_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time,k in HC_TempIntervals[ly,lc,t]}>=0;

# Heat supplied to nodes from heat transfer system 
var Qhtsmin{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc],t in Time, k in HC_TempIntervals[ly,lc,t]} >=0;

# Heat removed from nodes by the heat transfer system 
var Qhtsplus{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc],t in Time, k in HC_TempIntervals[ly,lc,t]} >=0;

# Heat cascade
#-------------------------------------------------------------------------
#CONSTRAINS

#CONSTRAINS

# Heat balance for heat transfers system 

subject to HC_HTS_heat_cascade{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, k in HC_TempIntervals[ly,lc,t]}:
sum{st in HC_HTS_Hot[ly,lc,t]:Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon} 
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tin[ly,st,t]-Streams_Tout[ly,st,t])) -
sum{st in HC_HTS_Cold[ly,lc,t]:Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon} 
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-Streams_Tin[ly,st,t])) +
sum{st in HC_HTS_Hot[ly,lc,t]:Streams_Tout[ly,st,t]<=HC_TI_tl[ly,lc,t,k] and Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tin[ly,st,t]-HC_TI_tl[ly,lc,t,k])) -
sum{st in HC_HTS_Cold[ly,lc,t]:Streams_Tin[ly,st,t]<=HC_TI_tl[ly,lc,t,k] and Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-HC_TI_tl[ly,lc,t,k]))
- sum{n in NodesOfLocation[lc]} Qhtsmin[ly,lc,n,t,k] + sum{n in NodesOfLocation[lc]} Qhtsplus[ly,lc,n,t,k] - HC_HTS_Rk[ly,lc,t,k]=0;


# Heat balance for each node 
subject to HC_Nodes_heat_cascade{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc],t in Time, k in HC_TempIntervals[ly,lc,t]}:
sum{st in HC_Nodes_Hot[ly,lc,n,t]:Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon} 
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tin[ly,st,t]-Streams_Tout[ly,st,t])) -
sum{st in HC_Nodes_Cold[ly,lc,n,t]:Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon} 
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-Streams_Tin[ly,st,t])) +
sum{st in HC_Nodes_Hot[ly,lc,n,t]:Streams_Tout[ly,st,t]<=HC_TI_tl[ly,lc,t,k] and Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tin[ly,st,t]-HC_TI_tl[ly,lc,t,k])) -
sum{st in HC_Nodes_Cold[ly,lc,n,t]:Streams_Tin[ly,st,t]<=HC_TI_tl[ly,lc,t,k] and Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-HC_TI_tl[ly,lc,t,k]))
+ Qhtsmin[ly,lc,n,t,k] - Qhtsplus[ly,lc,n,t,k] - HC_Nodes_Rk[ly,lc,n,t,k]=0;



subject to HC_Qhtsmin_constraint{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc],t in Time, k in HC_TempIntervals[ly,lc,t]}:
Qhtsmin[ly,lc,n,t,k] <= if (k>1) then Qhtsmin[ly,lc,n,t,prev(k)] else Infinity; 

subject to HC_Qhtsplus_constraint{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc],t in Time, k in HC_TempIntervals[ly,lc,t]}:
Qhtsplus[ly,lc,n,t,k] <= if (k>1) then Qhtsplus[ly,lc,n,t,prev(k)] else Infinity; 


param Min_T{ly in HeatCascades,lc in LocationsOfLayer[ly], t in Time} := min{s1 in HC_Cold_loc[ly,lc,t]} Streams_Tin[ly,s1,t]; 
param Max_T{ly in HeatCascades,lc in LocationsOfLayer[ly],t in Time} := max{s2 in HC_Hot_loc[ly,lc,t]} Streams_Tin[ly,s2,t]; 


subject to HC_HTS_lowerbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Min_T[ly,lc,t]}:
     HC_HTS_Rk[ly,lc,t,k] = 0;

subject to HC_HTS_upperbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Max_T[ly,lc,t]}:
     HC_HTS_Rk[ly,lc,t,k] = 0;
	 

subject to HC_Nodes_lowerbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc],t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Min_T[ly,lc,t]}:
     HC_Nodes_Rk[ly,lc,n,t,k] = 0;

subject to HC_Nodes_upperbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc],t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Max_T[ly,lc,t]}:
     HC_Nodes_Rk[ly,lc,n,t,k] = 0;

# No heat from hot streams below minimum input temperature
subject to HC_lowerbound_Balance{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Min_T[ly,lc,t]}:
	sum{st in HC_HTS_Hot[ly,lc,t]:Streams_Tout[ly,st,t]<=HC_TI_tl[ly,lc,t,k]-epsilon}
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(HC_TI_tl[ly,lc,t,k] - Streams_Tout[ly,st,t])) = 0;

# No heat from cold streams above maximum input temperature
subject to HC_upperbound_Balance{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Max_T[ly,lc,t]}:
	sum{st in HC_HTS_Cold[ly,lc,t]:Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t] - HC_TI_tl[ly,lc,t,k])) = 0;

	 
# Heat Balance for heat transfer system Hot streams (it is necessary to calculate the exchanged heat for each temperature interval with tl and tu, not the "summed" definition)
subject to HeatBalance_HTS_Hot{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, k in HC_TempIntervals[ly,lc,t]}:
if (k>1) then
sum{st in HC_HTS_Hot[ly,lc,t]:Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,prev(k)]+epsilon} (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*
     (Streams_Tin[ly,st,t]-Streams_Tout[ly,st,t])) 
+sum{st in HC_HTS_Hot[ly,lc,t]:Streams_Tout[ly,st,t]<=HC_TI_tl[ly,lc,t,prev(k)] and Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,prev(k)]+epsilon}
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tin[ly,st,t]-HC_TI_tl[ly,lc,t,prev(k)]))
-sum{st in HC_HTS_Hot[ly,lc,t]:Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon} (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*
     (Streams_Tin[ly,st,t]-Streams_Tout[ly,st,t])) 
-sum{st in HC_HTS_Hot[ly,lc,t]:Streams_Tout[ly,st,t]<=HC_TI_tl[ly,lc,t,k] and Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tin[ly,st,t]-HC_TI_tl[ly,lc,t,k]))	 	 
- sum{n in NodesOfLocation[lc]} Qhtsmin[ly,lc,n,t,prev(k)] + sum{n in NodesOfLocation[lc]} Qhtsmin[ly,lc,n,t,k] - HC_HTS_Rk[ly,lc,t,k] else 0 >= 0; 

# Heat Balance for heat transfer system Cold streams 
subject to HeatBalance_HTS_Cold{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, k in HC_TempIntervals[ly,lc,t]}:
if (k>1) then
- sum{st in HC_HTS_Cold[ly,lc,t]:Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,prev(k)]+epsilon} 
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-Streams_Tin[ly,st,t]))
- sum{st in HC_HTS_Cold[ly,lc,t]:Streams_Tin[ly,st,t]<=HC_TI_tl[ly,lc,t,prev(k)] and Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,prev(k)]+epsilon}
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-HC_TI_tl[ly,lc,t,prev(k)]))	
+ sum{st in HC_HTS_Cold[ly,lc,t]:Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon} 
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-Streams_Tin[ly,st,t]))
+ sum{st in HC_HTS_Cold[ly,lc,t]:Streams_Tin[ly,st,t]<=HC_TI_tl[ly,lc,t,k] and Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-HC_TI_tl[ly,lc,t,k]))		
+ sum{n in NodesOfLocation[lc]} Qhtsplus[ly,lc,n,t,prev(k)] - sum{n in NodesOfLocation[lc]} Qhtsplus[ly,lc,n,t,k]- HC_HTS_Rk[ly,lc,t,k] else 0 <= 0; 


subject to HC_Rk_sum{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, k in HC_TempIntervals[ly,lc,t]}:
HC_Rk[ly,lc,t,k] = HC_HTS_Rk[ly,lc,t,k] + sum{n in NodesOfLocation[lc]} HC_Nodes_Rk[ly,lc,n,t,k];