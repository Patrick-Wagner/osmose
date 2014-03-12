# $Id: thermal.mod 1847 2009-11-05 08:45:17Z bolliger $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Heat Cascade with Nodes 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


# Hot streams of Heat transfer system 
set HC_HTS_Hot {ly in HeatCascades, lc in LocationsOfLayer[ly]}  within Streams :=
	{s in StreamsOfLayer[ly] : Streams_Hout[ly,s]<Streams_Hin[ly,s] and s in HTSStreamsOfLocation[lc]};

	check {ly in HeatCascades, lc in LocationsOfLayer[ly]}: card(HC_HTS_Hot[ly,lc]) > 0;
	
# Cold streams of Heat transfer system 
set HC_HTS_Cold {ly in HeatCascades, lc in LocationsOfLayer[ly]}  within Streams :=
	{s in StreamsOfLayer[ly] : Streams_Hout[ly,s]>Streams_Hin[ly,s] and s in HTSStreamsOfLocation[lc]};

check {ly in HeatCascades, lc in LocationsOfLayer[ly]}: card(HC_HTS_Cold[ly,lc]) > 0;	

# Hot streams of Nodes 
set HC_Nodes_Hot{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc]} within Streams :=
{s in StreamsOfLayer[ly] : Streams_Hout[ly,s]<Streams_Hin[ly,s] and s in StreamsOfNode[n]};

#    check {ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc]}: card(HC_Nodes_Hot[ly,lc,n]) > 0;
	
# Cold streams of Nodes 
set HC_Nodes_Cold{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc]} within Streams :=
{s in StreamsOfLayer[ly] : Streams_Hout[ly,s]>Streams_Hin[ly,s] and s in StreamsOfNode[n]};

#    check {ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc]}: card(HC_Nodes_Cold[ly,lc,n]) > 0;


#-------------------------------------------------------------------------

### Variables 
## ---------------------------------------------------------------------------------------------------------------------------------------------------

var HC_HTS_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly],k in HC_TempIntervals[ly,lc]}>=0;
var HC_Nodes_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], k in HC_TempIntervals[ly,lc]}>=0;
# Sum of HC_HTS_Rk and HC_Nodes_Rk (used to identify pinch points)
var HC_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly],k in HC_TempIntervals[ly,lc]}>=0;

# Heat supplied to nodes from heat transfer system 
var Qhtsmin{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], k in HC_TempIntervals[ly,lc]} >=0;

# Heat removed from nodes by the heat transfer system 
var Qhtsplus{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], k in HC_TempIntervals[ly,lc]} >=0;

# Heat cascade
#-------------------------------------------------------------------------
#CONSTRAINS

# Heat balance for heat transfers system 

subject to HC_HTS_heat_cascade{ly in HeatCascades, lc in LocationsOfLayer[ly], k in HC_TempIntervals[ly,lc]}:
sum{st in HC_HTS_Hot[ly,lc]:Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon} 
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tin[ly,st]-Streams_Tout[ly,st])) -
sum{st in HC_HTS_Cold[ly,lc]:Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon} 
    (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-Streams_Tin[ly,st])) +
sum{st in HC_HTS_Hot[ly,lc]:Streams_Tout[ly,st]<=HC_TI_tl[ly,lc,k] and Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon}
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tin[ly,st]-HC_TI_tl[ly,lc,k])) -
sum{st in HC_HTS_Cold[ly,lc]:Streams_Tin[ly,st]<=HC_TI_tl[ly,lc,k] and Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon}
    (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-HC_TI_tl[ly,lc,k]))
- sum{n in NodesOfLocation[lc]} Qhtsmin[ly,lc,n,k] + sum{n in NodesOfLocation[lc]} Qhtsplus[ly,lc,n,k] - HC_HTS_Rk[ly,lc,k]=0;

# Heat balance for each node 
subject to HC_Nodes_heat_cascade{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], k in HC_TempIntervals[ly,lc]}:
sum{st in HC_Nodes_Hot[ly,lc,n]:Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon} 
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tin[ly,st]-Streams_Tout[ly,st])) -
sum{st in HC_Nodes_Cold[ly,lc,n]:Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon} 
    (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-Streams_Tin[ly,st])) +
sum{st in HC_Nodes_Hot[ly,lc,n]:Streams_Tout[ly,st]<=HC_TI_tl[ly,lc,k] and Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon}
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tin[ly,st]-HC_TI_tl[ly,lc,k])) -
sum{st in HC_Nodes_Cold[ly,lc,n]:Streams_Tin[ly,st]<=HC_TI_tl[ly,lc,k] and Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon}
    (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-HC_TI_tl[ly,lc,k]))
+ Qhtsmin[ly,lc,n,k] - Qhtsplus[ly,lc,n,k] - HC_Nodes_Rk[ly,lc,n,k]=0;

subject to HC_Qhtsmin_constraint{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], k in HC_TempIntervals[ly,lc]}:
Qhtsmin[ly,lc,n,k] <= if (k>1) then Qhtsmin[ly,lc,n,prev(k)] else Infinity; 

subject to HC_Qhtsplus_constraint{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], k in HC_TempIntervals[ly,lc]}:
Qhtsplus[ly,lc,n,k] <= if (k>1) then Qhtsplus[ly,lc,n,prev(k)] else Infinity; 


param Min_T{ly in HeatCascades,lc in LocationsOfLayer[ly]} := min{s1 in HC_Cold_loc[ly,lc]} Streams_Tin[ly,s1]; 
param Max_T{ly in HeatCascades,lc in LocationsOfLayer[ly]} := max{s2 in HC_Hot_loc[ly,lc]} Streams_Tin[ly,s2]; 


subject to HC_HTS_lowerbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Min_T[ly,lc]}:
     HC_HTS_Rk[ly,lc,k] = 0;

subject to HC_HTS_upperbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Max_T[ly,lc]}:
     HC_HTS_Rk[ly,lc,k] = 0;
	 

subject to HC_Nodes_lowerbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Min_T[ly,lc]}:
     HC_Nodes_Rk[ly,lc,n,k] = 0;

subject to HC_Nodes_upperbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Max_T[ly,lc]}:
     HC_Nodes_Rk[ly,lc,n,k] = 0;

# No heat from hot streams below minimum input temperature
subject to HC_lowerbound_Balance{ly in HeatCascades, lc in LocationsOfLayer[ly], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Min_T[ly,lc]}:
	sum{st in HC_HTS_Hot[ly,lc]:Streams_Tout[ly,st]<=HC_TI_tl[ly,lc,k]-epsilon}
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(HC_TI_tl[ly,lc,k] - Streams_Tout[ly,st])) = 0;

# No heat from cold streams above maximum input temperature
subject to HC_upperbound_Balance{ly in HeatCascades, lc in LocationsOfLayer[ly], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Max_T[ly,lc]}:
	sum{st in HC_HTS_Cold[ly,lc]:Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon}
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st] - HC_TI_tl[ly,lc,k])) = 0;

	 
# Heat Balance for heat transfer system Hot streams (it is necessary to calculate the exchanged heat for each temperature interval with tl and tu, not the "summed" definition)
subject to HeatBalance_HTS_Hot{ly in HeatCascades, lc in LocationsOfLayer[ly], k in HC_TempIntervals[ly,lc]}:
if (k>1) then
sum{st in HC_HTS_Hot[ly,lc]:Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,prev(k)]+epsilon} (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*
     (Streams_Tin[ly,st]-Streams_Tout[ly,st])) 
+sum{st in HC_HTS_Hot[ly,lc]:Streams_Tout[ly,st]<=HC_TI_tl[ly,lc,prev(k)] and Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,prev(k)]+epsilon}
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tin[ly,st]-HC_TI_tl[ly,lc,prev(k)]))
-sum{st in HC_HTS_Hot[ly,lc]:Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon} (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*
     (Streams_Tin[ly,st]-Streams_Tout[ly,st])) 
-sum{st in HC_HTS_Hot[ly,lc]:Streams_Tout[ly,st]<=HC_TI_tl[ly,lc,k] and Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon}
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tin[ly,st]-HC_TI_tl[ly,lc,k]))	 	 
- sum{n in NodesOfLocation[lc]} Qhtsmin[ly,lc,n,prev(k)] + sum{n in NodesOfLocation[lc]} Qhtsmin[ly,lc,n,k] - HC_HTS_Rk[ly,lc,k] else 0 >= 0; 

# Heat Balance for heat transfer system Cold streams 
subject to HeatBalance_HTS_Cold{ly in HeatCascades, lc in LocationsOfLayer[ly], k in HC_TempIntervals[ly,lc]}:
if (k>1) then
- sum{st in HC_HTS_Cold[ly,lc]:Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,prev(k)]+epsilon} 
    (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-Streams_Tin[ly,st]))
- sum{st in HC_HTS_Cold[ly,lc]:Streams_Tin[ly,st]<=HC_TI_tl[ly,lc,prev(k)] and Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,prev(k)]+epsilon}
    (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-HC_TI_tl[ly,lc,prev(k)]))	
+ sum{st in HC_HTS_Cold[ly,lc]:Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon} 
    (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-Streams_Tin[ly,st]))
+ sum{st in HC_HTS_Cold[ly,lc]:Streams_Tin[ly,st]<=HC_TI_tl[ly,lc,k] and Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon}
    (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-HC_TI_tl[ly,lc,k]))		
+ sum{n in NodesOfLocation[lc]} Qhtsplus[ly,lc,n,prev(k)] - sum{n in NodesOfLocation[lc]} Qhtsplus[ly,lc,n,k]- HC_HTS_Rk[ly,lc,k] else 0 <= 0; 


subject to HC_Rk_sum{ly in HeatCascades, lc in LocationsOfLayer[ly], k in HC_TempIntervals[ly,lc]}:
HC_Rk[ly,lc,k] = HC_HTS_Rk[ly,lc,k] + sum{n in NodesOfLocation[lc]} HC_Nodes_Rk[ly,lc,n,k];