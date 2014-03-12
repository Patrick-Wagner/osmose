# $Id: thermal.mod 1847 2009-11-05 08:45:17Z bolliger $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Heat Cascade with Nodes 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


# Hot streams of Heat transfer system 
set HC_HTS_Hot {ly in HeatCascades, lc in LocationsOfLayer[ly], pn in ParentNodesOfLocation[lc], t in Time}  within Streams :=
	{s in StreamsOfLayer[ly] : Streams_Hout[ly,s,t]<Streams_Hin[ly,s,t] and s in HTSStreamsOfParentNode[pn] and s in StreamsOfTime[t]};

#	check {ly in HeatCascades, lc in LocationsOfLayer[ly], pn in ParentNodesOfLocation[lc], t in Time}: card(HC_HTS_Hot[ly,lc,pn,t]) > 0;
	
# Cold streams of Heat transfer system 
set HC_HTS_Cold {ly in HeatCascades, lc in LocationsOfLayer[ly], pn in ParentNodesOfLocation[lc], t in Time}  within Streams :=
	{s in StreamsOfLayer[ly] : Streams_Hout[ly,s,t]>Streams_Hin[ly,s,t] and s in HTSStreamsOfParentNode[pn] and s in StreamsOfTime[t]};

#  check {ly in HeatCascades, lc in LocationsOfLayer[ly], pn in ParentNodesOfLocation[lc], t in Time}: card(HC_HTS_Cold[ly,lc,pn,t]) > 0;	

# Hot streams of Nodes 
set HC_Nodes_Hot{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], t in Time} within Streams :=
{s in StreamsOfLayer[ly] : Streams_Hout[ly,s,t]<Streams_Hin[ly,s,t] and s in StreamsOfNode[n] and s in StreamsOfTime[t]};

#    check {ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], t in Time}: card(HC_Nodes_Hot[ly,lc,n,t]) > 0;
	
# Cold streams of Nodes 
set HC_Nodes_Cold{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], t in Time} within Streams :=
{s in StreamsOfLayer[ly] : Streams_Hout[ly,s,t]>Streams_Hin[ly,s,t] and s in StreamsOfNode[n] and s in StreamsOfTime[t]};

#    check {ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], t in Time}: card(HC_Nodes_Cold[ly,lc,n,t]) > 0;


#-------------------------------------------------------------------------

### Variables 
## ---------------------------------------------------------------------------------------------------------------------------------------------------

# Rk for the heat transfer system 
var HC_HTS_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], t in Time, k in HC_TempIntervals[ly,lc,t]}>=0;
var HC_Nodes_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], t in Time, k in HC_TempIntervals[ly,lc,t]}>=0;

# Sum of HC_HTS_Rk and HC_Nodes_Rk (used to identify pinch points)
var HC_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], t in Time, k in HC_TempIntervals[ly,lc,t]}>=0;


# Heat supplied to nodes from heat transfer system of parentnode
var Qhtsmin{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], n in NodesOfLocation[lc], t in Time, k in HC_TempIntervals[ly,lc,t]} >=0;

# Heat removed from nodes by the heat transfer system 
var Qhtsplus{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], n in NodesOfLocation[lc], t in Time, k in HC_TempIntervals[ly,lc,t]} >=0;


# Heat cascade
#-------------------------------------------------------------------------
#CONSTRAINS


# Heat balance for heat transfers system for HTS of ParentNodes

subject to HC_HTS_heat_cascade{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], t in Time, k in HC_TempIntervals[ly,lc,t]}:
sum{st in HC_HTS_Hot[ly,lc,np,t]:Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon} 
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tin[ly,st,t]-Streams_Tout[ly,st,t])) -
sum{st in HC_HTS_Cold[ly,lc,np,t]:Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon} 
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-Streams_Tin[ly,st,t])) +
sum{st in HC_HTS_Hot[ly,lc,np,t]:Streams_Tout[ly,st,t]<=HC_TI_tl[ly,lc,t,k] and Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tin[ly,st,t]-HC_TI_tl[ly,lc,t,k])) -
sum{st in HC_HTS_Cold[ly,lc,np,t]:Streams_Tin[ly,st,t]<=HC_TI_tl[ly,lc,t,k] and Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-HC_TI_tl[ly,lc,t,k]))
- sum{n in NodesOfParentNode[np]} Qhtsmin[ly,lc,np,n,t,k] + sum{n in NodesOfParentNode[np]} Qhtsplus[ly,lc,np,n,t,k] 
+ sum{gn in ParentNodeOfNode[np]} Qhtsmin[ly,lc,gn,np,t,k] - sum{gn in ParentNodeOfNode[np]} Qhtsplus[ly,lc,gn,np,t,k]
- HC_HTS_Rk[ly,lc,np,t,k]=0;


# Heat balance for each node 
subject to HC_Nodes_heat_cascade{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], t in Time, k in HC_TempIntervals[ly,lc,t]}:
sum{st in HC_Nodes_Hot[ly,lc,n,t]:Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon} 
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tin[ly,st,t]-Streams_Tout[ly,st,t])) -
sum{st in HC_Nodes_Cold[ly,lc,n,t]:Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon} 
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-Streams_Tin[ly,st,t])) +
sum{st in HC_Nodes_Hot[ly,lc,n,t]:Streams_Tout[ly,st,t]<=HC_TI_tl[ly,lc,t,k] and Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tin[ly,st,t]-HC_TI_tl[ly,lc,t,k])) -
sum{st in HC_Nodes_Cold[ly,lc,n,t]:Streams_Tin[ly,st,t]<=HC_TI_tl[ly,lc,t,k] and Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-HC_TI_tl[ly,lc,t,k])) 
+ sum{np in ParentNodeOfNode[n]} Qhtsmin[ly,lc,np,n,t,k] - sum{np in ParentNodeOfNode[n]} Qhtsplus[ly,lc,np,n,t,k] - HC_Nodes_Rk[ly,lc,n,t,k]=0;


## Ordered definition
## create an index set 
set TK{ly in HeatCascades,lc in LocationsOfLayer[ly], t in Time}:= {1..card(HC_TempIntervals[ly,lc,t])}; 

## create a set of sets 
set trk_p{ly in HeatCascades,lc in LocationsOfLayer[ly], t in Time, i in TK[ly,lc,t]} := setof{ r in HC_TempIntervals[ly,lc,t] : sum{q in HC_TempIntervals[ly,lc,t] : q <= r} 1 = i } r; 

## create an ordered set 
set HC_TempIntervals_ord{ly in HeatCascades, lc in LocationsOfLayer[ly], t in Time} :=setof{ i in TK[ly,lc,t],p in trk_p[ly,lc,t,i]}p;

subject to HC_Qhtsmin_constraint_1{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], n in NodesOfLocation[lc], t in Time, k in HC_TempIntervals[ly,lc,t], kfirst in trk_p[ly,lc,t,1]:k=kfirst}:
Qhtsmin[ly,lc,np,n,t,k]<=1000000000000000000000000;

subject to HC_Qhtsmin_constraint_2{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], n in NodesOfLocation[lc], t in Time, k in HC_TempIntervals_ord[ly,lc,t],i in TK[ly,lc,t] diff{1},kcurent in trk_p[ly,lc,t,i],kpreve in trk_p[ly,lc,t,i-1] : k = kcurent }:
Qhtsmin[ly,lc,np,n,t,k]<=Qhtsmin[ly,lc,np,n,t,kpreve];

subject to HC_Qhtsplus_constraint_1{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], n in NodesOfLocation[lc], t in Time, k in HC_TempIntervals_ord[ly,lc,t],kfirst in trk_p[ly,lc,t,1]:k=kfirst}:
Qhtsplus[ly,lc,np,n,t,k]<=1000000000000000000000000;

subject to HC_Qhtsplus_constraint_2{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], n in NodesOfLocation[lc], t in Time, k in HC_TempIntervals_ord[ly,lc,t],i in TK[ly,lc,t] diff{1},kcurent in trk_p[ly,lc,t,i],kpreve in trk_p[ly,lc,t,i-1] : k = kcurent }:
Qhtsplus[ly,lc,np,n,t,k]<=Qhtsplus[ly,lc,np,n,t,kpreve];

param Min_T{ly in HeatCascades,lc in LocationsOfLayer[ly], t in Time} := min{s1 in HC_Cold_loc[ly,lc,t]} Streams_Tin[ly,s1,t]; 
param Max_T{ly in HeatCascades,lc in LocationsOfLayer[ly], t in Time} := max{s2 in HC_Hot_loc[ly,lc,t]} Streams_Tin[ly,s2,t]; 


subject to HC_HTS_lowerbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Min_T[ly,lc,t]}:
     HC_HTS_Rk[ly,lc,np,t,k] = 0;

subject to HC_HTS_upperbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Max_T[ly,lc,t]}:
    HC_HTS_Rk[ly,lc,np,t,k] = 0;
	 

subject to HC_Nodes_lowerbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Min_T[ly,lc,t]}:
     HC_Nodes_Rk[ly,lc,n,t,k] = 0;

subject to HC_Nodes_upperbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Max_T[ly,lc,t]}:
     HC_Nodes_Rk[ly,lc,n,t,k] = 0;

# No heat from hot streams below minimum input temperature
subject to HC_lowerbound_Balance{ly in HeatCascades, lc in LocationsOfLayer[ly], np in GParentNodesOfLocation[lc], t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Min_T[ly,lc,t]}:
	sum{st in HC_HTS_Hot[ly,lc,np,t]:Streams_Tout[ly,st,t]<=HC_TI_tl[ly,lc,t,k]-epsilon}
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(HC_TI_tl[ly,lc,t,k] - Streams_Tout[ly,st,t])) = 0;

# No heat from cold streams above maximum input temperature
subject to HC_upperbound_Balance{ly in HeatCascades, lc in LocationsOfLayer[ly], np in GParentNodesOfLocation[lc], t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Max_T[ly,lc,t]}:
	sum{st in HC_HTS_Cold[ly,lc,np,t]:Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t] - HC_TI_tl[ly,lc,t,k])) = 0;

	 
# Heat Balance for General heat transfer system Hot streams (it is necessary to calculate the exchanged heat for each temperature interval with tl and tu, not the "summed" definition)
subject to HeatBalance_HTS_Hot{ly in HeatCascades, lc in LocationsOfLayer[ly],np in ParentNodesOfLocation[lc], t in Time, k in HC_TempIntervals[ly,lc,t],i in TK[ly,lc,t] diff{1},kcurent in trk_p[ly,lc,t,i],kpreve in trk_p[ly,lc,t,i-1] : k = kcurent}:
sum{st in HC_HTS_Hot[ly,lc,np,t]:Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,kpreve]+epsilon} (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*
    (Streams_Tin[ly,st,t]-Streams_Tout[ly,st,t])) 
+sum{st in HC_HTS_Hot[ly,lc,np,t]:Streams_Tout[ly,st,t]<=HC_TI_tl[ly,lc,t,kpreve] and Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,kpreve]+epsilon}
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tin[ly,st,t]-HC_TI_tl[ly,lc,t,kpreve]))
-sum{st in HC_HTS_Hot[ly,lc,np,t]:Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon} (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*
     (Streams_Tin[ly,st,t]-Streams_Tout[ly,st,t])) 
-sum{st in HC_HTS_Hot[ly,lc,np,t]:Streams_Tout[ly,st,t]<=HC_TI_tl[ly,lc,t,k] and Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tin[ly,st,t]-HC_TI_tl[ly,lc,t,k]))	 	 
- sum{n in NodesOfParentNode[np]} Qhtsmin[ly,lc,np,n,t,kpreve] + sum{n in NodesOfParentNode[np]} Qhtsmin[ly,lc,np,n,t,k] 
+ sum{gn in ParentNodeOfNode[np]} Qhtsmin[ly,lc,gn,np,t,kpreve] - sum{gn in ParentNodeOfNode[np]} Qhtsmin[ly,lc,gn,np,t,k]
+ HC_HTS_Rk[ly,lc,np,t,k] - HC_HTS_Rk[ly,lc,np,t,kpreve] >= 0; 


# Heat Balance for General heat transfer system Cold streams 
subject to HeatBalance_HTS_Cold{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], t in Time, k in HC_TempIntervals[ly,lc,t],i in TK[ly,lc,t] diff{1},kcurent in trk_p[ly,lc,t,i],kpreve in trk_p[ly,lc,t,i-1] : k = kcurent}:
- sum{st in HC_HTS_Cold[ly,lc,np,t]:Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,kpreve]+epsilon} 
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-Streams_Tin[ly,st,t]))
- sum{st in HC_HTS_Cold[ly,lc,np,t]:Streams_Tin[ly,st,t]<=HC_TI_tl[ly,lc,t,kpreve] and Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,kpreve]+epsilon}
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-HC_TI_tl[ly,lc,t,kpreve]))	
+ sum{st in HC_HTS_Cold[ly,lc,np,t]:Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon} 
   (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-Streams_Tin[ly,st,t]))
+ sum{st in HC_HTS_Cold[ly,lc,np,t]:Streams_Tin[ly,st,t]<=HC_TI_tl[ly,lc,t,k] and Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-HC_TI_tl[ly,lc,t,k]))		
+ sum{n in NodesOfParentNode[np]} Qhtsplus[ly,lc,np,n,t,kpreve] - sum{n in NodesOfParentNode[np]} Qhtsplus[ly,lc,np,n,t,k]
- sum{gn in ParentNodeOfNode[np]} Qhtsplus[ly,lc,gn,np,t,kpreve] + sum{gn in ParentNodeOfNode[np]} Qhtsplus[ly,lc,gn,np,t,k] 
+ HC_HTS_Rk[ly,lc,np,t,k] - HC_HTS_Rk[ly,lc,np,t,kpreve] <= 0; 

subject to HC_Rk_sum{ly in HeatCascades, lc in LocationsOfLayer[ly], np in GParentNodesOfLocation[lc], t in Time , k in HC_TempIntervals[ly,lc,t]}:
HC_Rk[ly,lc,t,k] = sum{n in NodesOfParentNode[np]} HC_Nodes_Rk[ly,lc,n,t,k];