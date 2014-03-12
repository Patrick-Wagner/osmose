# $Id: thermal.mod 1847 2009-11-05 08:45:17Z bolliger $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Heat Cascade with Nodes 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Hot streams of Heat transfer system 
set HC_HTS_Hot {ly in HeatCascades, lc in LocationsOfLayer[ly], pn in ParentNodesOfLocation[lc]}  within Streams :=
	{s in StreamsOfLayer[ly] : Streams_Hout[ly,s]<Streams_Hin[ly,s] and s in HTSStreamsOfParentNode[pn]};

#	check {ly in HeatCascades, lc in LocationsOfLayer[ly]}: card(HC_HTS_Hot[ly,lc]) > 0;
	
# Cold streams of Heat transfer system 
set HC_HTS_Cold {ly in HeatCascades, lc in LocationsOfLayer[ly], pn in ParentNodesOfLocation[lc]}  within Streams :=
	{s in StreamsOfLayer[ly] : Streams_Hout[ly,s]>Streams_Hin[ly,s] and s in HTSStreamsOfParentNode[pn]};

#  check {ly in HeatCascades, lc in LocationsOfLayer[ly]}: card(HC_HTS_Cold[ly,lc]) > 0;	

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

# Rk for the heat transfer system 
var HC_HTS_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc],k in HC_TempIntervals[ly,lc]}>=0;
var HC_Nodes_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], k in HC_TempIntervals[ly,lc]}>=0;

# Sum of HC_HTS_Rk and HC_Nodes_Rk (used to identify pinch points)
var HC_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly],k in HC_TempIntervals[ly,lc]}>=0;


# Heat supplied to nodes from heat transfer system of parentnode
var Qhtsmin{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], n in NodesOfLocation[lc], k in HC_TempIntervals[ly,lc]} >=0;

# Heat removed from nodes by the heat transfer system 
var Qhtsplus{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], n in NodesOfLocation[lc], k in HC_TempIntervals[ly,lc]} >=0;


# Imaginary hot streams for envelope for heat transfer streams defined for each node
var ENV_Q_HTS_Hot{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], k in HC_TempIntervals[ly,lc]} >=0;

# Imaginary cold streams for envelope for heat transfer streams defined for each node
var ENV_Q_HTS_Cold{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], k in HC_TempIntervals[ly,lc]} >=0;


# Heat cascade
#-------------------------------------------------------------------------
#CONSTRAINS


# Heat balance for heat transfers system for HTS of ParentNodes

subject to HC_HTS_heat_cascade{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], k in HC_TempIntervals[ly,lc]}:
sum{st in HC_HTS_Hot[ly,lc,np]:Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon} 
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tin[ly,st]-Streams_Tout[ly,st])) -
sum{st in HC_HTS_Cold[ly,lc,np]:Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon} 
    (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-Streams_Tin[ly,st])) +
sum{st in HC_HTS_Hot[ly,lc,np]:Streams_Tout[ly,st]<=HC_TI_tl[ly,lc,k] and Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon}
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tin[ly,st]-HC_TI_tl[ly,lc,k])) -
sum{st in HC_HTS_Cold[ly,lc,np]:Streams_Tin[ly,st]<=HC_TI_tl[ly,lc,k] and Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon}
    (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-HC_TI_tl[ly,lc,k]))
- sum{n in NodesOfParentNode[np]} Qhtsmin[ly,lc,np,n,k] + sum{n in NodesOfParentNode[np]} Qhtsplus[ly,lc,np,n,k] 
+ sum{gn in ParentNodeOfNode[np]} Qhtsmin[ly,lc,gn,np,k] - sum{gn in ParentNodeOfNode[np]} Qhtsplus[ly,lc,gn,np,k]
+ ENV_Q_HTS_Hot[ly,lc,np,k] - ENV_Q_HTS_Cold[ly,lc,np,k]
- HC_HTS_Rk[ly,lc,np,k]=0;


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
+ sum{np in ParentNodeOfNode[n]} Qhtsmin[ly,lc,np,n,k] - sum{np in ParentNodeOfNode[n]} Qhtsplus[ly,lc,np,n,k] - HC_Nodes_Rk[ly,lc,n,k]=0;



## Ordered definition
## create an index set 
set TK{ly in HeatCascades,lc in LocationsOfLayer[ly]}:= {1..card(HC_TempIntervals[ly,lc])}; 

## create a set of sets 
set trk_p{ly in HeatCascades,lc in LocationsOfLayer[ly],i in TK[ly,lc]} := setof{ r in HC_TempIntervals[ly,lc] : sum{q in HC_TempIntervals[ly,lc] : q <= r} 1 = i } r; 

## create an ordered set 
set HC_TempIntervals_ord{ly in HeatCascades, lc in LocationsOfLayer[ly]} :=setof{ i in TK[ly,lc],t in trk_p[ly,lc,i]}t;

subject to HC_Qhtsmin_constraint_1{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], n in NodesOfLocation[lc], k in HC_TempIntervals[ly,lc], kfirst in trk_p[ly,lc,1]:k=kfirst}:
Qhtsmin[ly,lc,np,n,k]<=1000000000000000000000000;

subject to HC_Qhtsmin_constraint_2{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], n in NodesOfLocation[lc], k in HC_TempIntervals_ord[ly,lc],i in TK[ly,lc] diff{1},kcurent in trk_p[ly,lc,i],kpreve in trk_p[ly,lc,i-1] : k = kcurent }:
Qhtsmin[ly,lc,np,n,k]<=Qhtsmin[ly,lc,np,n,kpreve];

subject to HC_Qhtsplus_constraint_1{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], n in NodesOfLocation[lc], k in HC_TempIntervals_ord[ly,lc],kfirst in trk_p[ly,lc,1]:k=kfirst}:
Qhtsplus[ly,lc,np,n,k]<=1000000000000000000000000;

subject to HC_Qhtsplus_constraint_2{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], n in NodesOfLocation[lc], k in HC_TempIntervals_ord[ly,lc],i in TK[ly,lc] diff{1},kcurent in trk_p[ly,lc,i],kpreve in trk_p[ly,lc,i-1] : k = kcurent }:
Qhtsplus[ly,lc,np,n,k]<=Qhtsplus[ly,lc,np,n,kpreve];

param Min_T{ly in HeatCascades,lc in LocationsOfLayer[ly]} := min{s1 in HC_Cold_loc[ly,lc]} Streams_Tin[ly,s1]; 
param Max_T{ly in HeatCascades,lc in LocationsOfLayer[ly]} := max{s2 in HC_Hot_loc[ly,lc]} Streams_Tin[ly,s2]; 


subject to HC_HTS_lowerbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Min_T[ly,lc]}:
     HC_HTS_Rk[ly,lc,np,k] = 0;

subject to HC_HTS_upperbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Max_T[ly,lc]}:
    HC_HTS_Rk[ly,lc,np,k] = 0;
	 

subject to HC_Nodes_lowerbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Min_T[ly,lc]}:
     HC_Nodes_Rk[ly,lc,n,k] = 0;

subject to HC_Nodes_upperbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], n in NodesOfLocation[lc], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Max_T[ly,lc]}:
     HC_Nodes_Rk[ly,lc,n,k] = 0;


	 
# No heat from hot streams below minimum input temperature
subject to HC_lowerbound_Balance{ly in HeatCascades, lc in LocationsOfLayer[ly], np in GParentNodesOfLocation[lc], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Min_T[ly,lc]}:
	sum{st in HC_HTS_Hot[ly,lc,np]:Streams_Tout[ly,st]<=HC_TI_tl[ly,lc,k]-epsilon}
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(HC_TI_tl[ly,lc,k] - Streams_Tout[ly,st])) = 0;

# No heat from cold streams above maximum input temperature
subject to HC_upperbound_Balance{ly in HeatCascades, lc in LocationsOfLayer[ly], np in GParentNodesOfLocation[lc], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Max_T[ly,lc]}:
	sum{st in HC_HTS_Cold[ly,lc,np]:Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon}
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st] - HC_TI_tl[ly,lc,k])) = 0;


	 
# Heat Balance for General heat transfer system Hot streams (it is necessary to calculate the exchanged heat for each temperature interval with tl and tu, not the "summed" definition)
subject to HeatBalance_HTS_Hot{ly in HeatCascades, lc in LocationsOfLayer[ly],np in ParentNodesOfLocation[lc], k in HC_TempIntervals[ly,lc],i in TK[ly,lc] diff{1},kcurent in trk_p[ly,lc,i],kpreve in trk_p[ly,lc,i-1] : k = kcurent}:
sum{st in HC_HTS_Hot[ly,lc,np]:Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,kpreve]+epsilon} (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*
    (Streams_Tin[ly,st]-Streams_Tout[ly,st])) 
+sum{st in HC_HTS_Hot[ly,lc,np]:Streams_Tout[ly,st]<=HC_TI_tl[ly,lc,kpreve] and Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,kpreve]+epsilon}
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tin[ly,st]-HC_TI_tl[ly,lc,kpreve]))
-sum{st in HC_HTS_Hot[ly,lc,np]:Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon} (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*
     (Streams_Tin[ly,st]-Streams_Tout[ly,st])) 
-sum{st in HC_HTS_Hot[ly,lc,np]:Streams_Tout[ly,st]<=HC_TI_tl[ly,lc,k] and Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon}
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tin[ly,st]-HC_TI_tl[ly,lc,k]))	 	 
- sum{n in NodesOfParentNode[np]} Qhtsmin[ly,lc,np,n,kpreve] + sum{n in NodesOfParentNode[np]} Qhtsmin[ly,lc,np,n,k] 
#+ sum{gn in ParentNodeOfNode[np]} Qhtsplus[ly,lc,gn,np,kpreve] - sum{gn in ParentNodeOfNode[np]} Qhtsplus[ly,lc,gn,np,k] 
+ sum{gn in ParentNodeOfNode[np]} Qhtsmin[ly,lc,gn,np,kpreve] - sum{gn in ParentNodeOfNode[np]} Qhtsmin[ly,lc,gn,np,k]
+ ENV_Q_HTS_Hot[ly,lc,np,kpreve] - ENV_Q_HTS_Hot[ly,lc,np,k] 
+ HC_HTS_Rk[ly,lc,np,k] - HC_HTS_Rk[ly,lc,np,kpreve] >= 0; 


# Heat Balance for General heat transfer system Cold streams 
subject to HeatBalance_HTS_Cold{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], k in HC_TempIntervals[ly,lc],i in TK[ly,lc] diff{1},kcurent in trk_p[ly,lc,i],kpreve in trk_p[ly,lc,i-1] : k = kcurent}:
- sum{st in HC_HTS_Cold[ly,lc,np]:Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,kpreve]+epsilon} 
    (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-Streams_Tin[ly,st]))
- sum{st in HC_HTS_Cold[ly,lc,np]:Streams_Tin[ly,st]<=HC_TI_tl[ly,lc,kpreve] and Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,kpreve]+epsilon}
    (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-HC_TI_tl[ly,lc,kpreve]))	
+ sum{st in HC_HTS_Cold[ly,lc,np]:Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon} 
   (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-Streams_Tin[ly,st]))
+ sum{st in HC_HTS_Cold[ly,lc,np]:Streams_Tin[ly,st]<=HC_TI_tl[ly,lc,k] and Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon}
    (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-HC_TI_tl[ly,lc,k]))		
+ sum{n in NodesOfParentNode[np]} Qhtsplus[ly,lc,np,n,kpreve] - sum{n in NodesOfParentNode[np]} Qhtsplus[ly,lc,np,n,k]
- sum{gn in ParentNodeOfNode[np]} Qhtsplus[ly,lc,gn,np,kpreve] + sum{gn in ParentNodeOfNode[np]} Qhtsplus[ly,lc,gn,np,k] 
#- sum{gn in ParentNodeOfNode[np]} Qhtsmin[ly,lc,gn,np,kpreve] + sum{gn in ParentNodeOfNode[np]} Qhtsmin[ly,lc,gn,np,k]
- ENV_Q_HTS_Cold[ly,lc,np,kpreve] + ENV_Q_HTS_Cold[ly,lc,np,k]
+ HC_HTS_Rk[ly,lc,np,k] - HC_HTS_Rk[ly,lc,np,kpreve] <= 0; 




# Heat balance for imaginary hot and cold streams in the envelope (to assure that the hot and cold streams are situated correctly and heat balance is closed(constraint2)) 
subject to HC_ENV_heat_cascade1{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], k in HC_TempIntervals[ly,lc]}:
  + ENV_Q_HTS_Hot[ly,lc,np,k] - ENV_Q_HTS_Cold[ly,lc,np,k] <= 0; 

 subject to HC_ENV_heat_cascade2{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], k in HC_TempIntervals[ly,lc]}:
  - ENV_Q_HTS_Hot[ly,lc,np,1] + ENV_Q_HTS_Cold[ly,lc,np,1] = 0;

subject to HC_Rk_sum{ly in HeatCascades, lc in LocationsOfLayer[ly], np in GParentNodesOfLocation[lc] , k in HC_TempIntervals[ly,lc]}:
HC_Rk[ly,lc,k] = sum{n in NodesOfParentNode[np]} HC_Nodes_Rk[ly,lc,n,k];



# Constraints for the summe definition (ENV_Q_HTS_Cold(prev k) > ENV_Q_HTS_Cold(k))
subject to ENV_Q_HTS_Cold_constraint_1{ly in HeatCascades, lc in LocationsOfLayer[ly], np in ParentNodesOfLocation[lc], k in HC_TempIntervals[ly,lc], kfirst in trk_p[ly,lc,1]:k=kfirst}:
ENV_Q_HTS_Cold[ly,lc,np,k]<=1000000000000000000000000;

subject to ENV_Q_HTS_Cold_constraint_2{ly in HeatCascades, lc in LocationsOfLayer[ly],  np in ParentNodesOfLocation[lc], k in HC_TempIntervals_ord[ly,lc],i in TK[ly,lc] diff{1},kcurent in trk_p[ly,lc,i],kpreve in trk_p[ly,lc,i-1] : k = kcurent }:
ENV_Q_HTS_Cold[ly,lc,np,k]<=ENV_Q_HTS_Cold[ly,lc,np,kpreve];

subject to ENV_Q_HTS_Hot_constraint_1{ly in HeatCascades, lc in LocationsOfLayer[ly],  np in ParentNodesOfLocation[lc], k in HC_TempIntervals_ord[ly,lc],kfirst in trk_p[ly,lc,1]:k=kfirst}:
ENV_Q_HTS_Hot[ly,lc,np,k]<=1000000000000000000000000;

subject to ENV_Q_HTS_Hot_constraint_2{ly in HeatCascades, lc in LocationsOfLayer[ly],  np in ParentNodesOfLocation[lc], k in HC_TempIntervals_ord[ly,lc],i in TK[ly,lc] diff{1},kcurent in trk_p[ly,lc,i],kpreve in trk_p[ly,lc,i-1] : k = kcurent }:
ENV_Q_HTS_Hot[ly,lc,np,k]<=ENV_Q_HTS_Hot[ly,lc,np,kpreve];



# penalty 
var penalty_envelope >= 0;

subject to Penalty_constraint:  
penalty_envelope = sum{ly in HeatCascades, lc in LocationsOfLayer[ly],np in ParentNodesOfLocation[lc], k in HC_TempIntervals[ly,lc]} 
  ( HC_Rk[ly,lc,k] + ENV_Q_HTS_Hot[ly,lc,np,1] );
