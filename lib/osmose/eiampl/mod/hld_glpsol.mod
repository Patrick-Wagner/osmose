# $Id: thermal.mod 1847 2009-11-05 08:45:17Z bolliger $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Heat Load Distribution
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




## Sets
# ---------------------------------------------------------------------------------------------------------------------------------------------------

set HLD_Locations;
set HLD_Units;
set HLD_Streams; # defines all stream including segements for exemple steam types like HT, streams, steams  
set HLD_StreamsGroups; # defines thermal streams (regrouping segments to one stream)
set HLD_LayerTypes;
set HLD_Layers;
set HLD_LayersOfType{ly in HLD_LayerTypes} within HLD_Layers;

# Filtering Layers and selecting only layers of type "HeatCascade"
set HLD_HeatCascades := if (exists{t in HLD_LayerTypes} t = 'HeatCascade') then ({ly in HLD_LayersOfType["HeatCascade"]}) else ({});


set HLD_LocationsOfLayer{ly in HLD_Layers} within HLD_Locations;
set HLD_StreamsOfLayer{ly in HLD_Layers} within HLD_Streams;
set HLD_StreamsOfLocation{lc in HLD_Locations} within HLD_Streams;

set HLD_StreamsOfStreamsGroups{sg in HLD_StreamsGroups} within HLD_Streams; # link between stream segements and real stream
set HLD_StreamsGroupsOfStream{s in HLD_Streams}; 

set HLD_UnitsOfStream{s in HLD_Streams} within HLD_Units;

#Set of temperature intervals of each heat cascade
set HLD_TempIntervals{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly]} ; #Set of temperature intervals of each heat cascade
## Ordered definition
## create an index set 
set TK{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly]}:= {1..card(HLD_TempIntervals[ly,lc])}; 
## create a set of sets 
set trk_p{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly],i in TK[ly,lc]} := setof{ r in HLD_TempIntervals[ly,lc] : sum{q in HLD_TempIntervals[ly,lc] : q <= r} 1 = i } r; 
## create an ordered set 
set HLD_TempIntervals_ord{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly]} :=setof{ i in TK[ly,lc],t in trk_p[ly,lc,i]}t; 
#display HLD_TempIntervals_ord;


param HLD_Streams_Tin{ly in HLD_HeatCascades, s in HLD_StreamsOfLayer[ly]};
param HLD_Streams_Tout{ly in HLD_HeatCascades, s in HLD_StreamsOfLayer[ly]};
param HLD_Streams_Hin{ly in HLD_HeatCascades, s in HLD_StreamsOfLayer[ly]};
param HLD_Streams_Hout{ly in HLD_HeatCascades, s in HLD_StreamsOfLayer[ly]};
param HLD_Streams_dH{ly in HLD_HeatCascades, s in HLD_StreamsOfLayer[ly]};

param HLD_StreamsGroups_Tin{ly in HLD_HeatCascades, sg in HLD_StreamsGroups};
param HLD_StreamsGroups_Tout{ly in HLD_HeatCascades, sg in HLD_StreamsGroups};
param HLD_StreamsGroups_Hin{ly in HLD_HeatCascades, sg in HLD_StreamsGroups};
param HLD_StreamsGroups_Hout{ly in HLD_HeatCascades, sg in HLD_StreamsGroups};


# Temperature intervals
param HLD_TI_tl{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], k in HLD_TempIntervals_ord[ly,lc]};
param HLD_TI_tu{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], k in HLD_TempIntervals_ord[ly,lc]};



set HLD_zones{ ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly]};
## Ordered definition
## create an index set 
#set TZ{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly]}:= {1..card(HLD_zones[ly,lc])}; 
## create a set of sets 
#set trz_p{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly],i in TZ[ly,lc]} := setof{ r in HLD_zones[ly,lc] : sum{q in HLD_zones[ly,lc] : q <= r} 1 = i } r; 
## create an ordered set 
#set HLD_zones_ord{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly]} :=setof{ i in TZ[ly,lc],t in trz_p[ly,lc,i]}t; 
#display HLD_zones;

# lists temperature intervals belonging to each subnetwork
set HLD_SubNetworks{ ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]};
## Ordered definition
## create an index set 
#set TS{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]}:= {1..card(HLD_SubNetworks[ly,lc,z])}; 
## create a set of sets 
#set trs_p{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc],i in TS[ly,lc,z]} := setof{ r in HLD_SubNetworks[ly,lc,z] : sum{q in HLD_SubNetworks[ly,lc,z] : q <= r} 1 = i } r; 
## create an ordered set 
#set HLD_SubNetworks_ord{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]} :=setof{ i in TS[ly,lc,z],t in trs_p[ly,lc,z,i]}t; 
#display HLD_SubNetworks;

# Units sizing contraints
param HLD_Units_Fmin{u in HLD_Units}; 
param HLD_Units_Fmax{u in HLD_Units}; 

param HLD_Units_Fmin_z{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], u in HLD_Units} := HLD_Units_Fmin[u]; 
param HLD_Units_Fmax_z{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], u in HLD_Units} := HLD_Units_Fmax[u]; 


# Hot and cold HLD_Streams
set HLD_Hot {ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly]} := {s in HLD_StreamsOfLayer[ly] : HLD_Streams_Hout[ly,s]<HLD_Streams_Hin[ly,s] and s in HLD_StreamsOfLocation[lc]};
set HLD_Cold {ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly]} := {s in HLD_StreamsOfLayer[ly] : HLD_Streams_Hout[ly,s]>HLD_Streams_Hin[ly,s] and s in HLD_StreamsOfLocation[lc]};

	
# hot and cold HLD_Streams in each zone
set HLD_Hk{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], k in HLD_TempIntervals_ord[ly,lc]} := {s in HLD_Hot[ly,lc] : HLD_Streams_Tin[ly,s]>= HLD_TI_tu[ly,lc,k] and HLD_Streams_Tout[ly,s]< HLD_TI_tu[ly,lc,k]};
set HLD_Ck{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], k in HLD_TempIntervals_ord[ly,lc]} := {s in HLD_Cold[ly,lc] : HLD_Streams_Tin[ly,s]<= HLD_TI_tl[ly,lc,k] and HLD_Streams_Tout[ly,s]> HLD_TI_tl[ly,lc,k]};

#	Define hot streams segments i in and above interval k 
set HLD_Above_Hzk{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], k in HLD_SubNetworks[ly,lc,z]} := setof{ki in HLD_SubNetworks[ly,lc,z], s in HLD_Hk[ly,lc,ki]: HLD_TI_tl[ly,lc,ki] >= HLD_TI_tl[ly,lc,k]} (s) ;
#	Define cold streams segments j in and below interval k 
set HLD_Below_Czk{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], k in HLD_SubNetworks[ly,lc,z]} := setof{ki in HLD_SubNetworks[ly,lc,z], s in HLD_Ck[ly,lc,ki]: HLD_TI_tu[ly,lc,ki] <= HLD_TI_tu[ly,lc,k]} (s) ;


set HLD_Hz{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]} := setof {k in HLD_SubNetworks[ly,lc,z], s in HLD_Hk[ly,lc,k]} (s) ;
set HLD_Cz{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]} := setof{k in HLD_SubNetworks[ly,lc,z], s in HLD_Ck[ly,lc,k]} (s);

# Define temperature intervals above cold stream in zone z
set HLD_Above_ColdStream{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], s in HLD_Cz[ly,lc,z]} := setof{ki in HLD_SubNetworks[ly,lc,z] : HLD_TI_tl[ly,lc,ki] >= HLD_Streams_Tin[ly,s]} (ki) ;


# Hot and cold HLD_StreamsGroups

set HLD_Hot_StGroup {ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly]} := {sg in HLD_StreamsGroups : HLD_StreamsGroups_Hout[ly,sg]<HLD_StreamsGroups_Hin[ly,sg]};
set HLD_Cold_StGroup {ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly]} := {sg in HLD_StreamsGroups : HLD_StreamsGroups_Hout[ly,sg]>HLD_StreamsGroups_Hin[ly,sg]};

# hot and cold HLD_StreamsGroups in each zone

set HLD_Hk_StGroup{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], k in HLD_TempIntervals[ly,lc]} := {sg in HLD_Hot_StGroup[ly,lc] : HLD_StreamsGroups_Tin[ly,sg]>= HLD_TI_tu[ly,lc,k] and HLD_StreamsGroups_Tout[ly,sg]< HLD_TI_tu[ly,lc,k]};
set HLD_Ck_StGroup{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], k in HLD_TempIntervals[ly,lc]} := {sg in HLD_Cold_StGroup[ly,lc] : HLD_StreamsGroups_Tin[ly,sg]<= HLD_TI_tl[ly,lc,k] and HLD_StreamsGroups_Tout[ly,sg]> HLD_TI_tl[ly,lc,k]};

set HLD_Above_Hzk_StGroup{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], k in HLD_SubNetworks[ly,lc,z]} := setof{ki in HLD_SubNetworks[ly,lc,z], s in HLD_Hk_StGroup[ly,lc,ki]: HLD_TI_tl[ly,lc,ki] >= HLD_TI_tl[ly,lc,k]} (s) ;

set HLD_Hz_StGroup{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]} := setof {k in HLD_SubNetworks[ly,lc,z], s in HLD_Hk_StGroup[ly,lc,k]} (s) ;
set HLD_Cz_StGroup{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]} := setof{k in HLD_SubNetworks[ly,lc,z], s in HLD_Ck_StGroup[ly,lc,k]} (s) ;


## Stream matches ok !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# ------------------------

# Matches
set HLD_Matches{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly]} := {HLD_Hot[ly,lc] cross HLD_Cold[ly,lc]};

# Forbidden matches
set HLD_Forbidden_Matches{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly]} within HLD_Matches[ly,lc] :={} cross {};

# Matches
set HLD_MatchesGroups{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]} := {HLD_Hz_StGroup[ly,lc,z] cross HLD_Cz_StGroup[ly,lc,z]};

# Forbidden matches
set HLD_Forbidden_MatchesGroups{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]} within HLD_MatchesGroups[ly,lc,z] default {} cross {};
#set HLD_Forbidden_MatchesGroups{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]}  default {};


# Unrestricted Matches
set HLD_Unrestricted_Matches{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly]} := HLD_Matches[ly,lc] diff HLD_Forbidden_Matches[ly,lc];


## Parameters ok !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# ---------------------------------------------------------------------------------------------------------------------------------------------------

# weight given to each connection between hot stream i and cold stream j, for each subnetwork
param HLD_e_ijz{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], i in HLD_Hz[ly,lc,z], j in HLD_Cz[ly,lc,z]};

# heat provided or received by hot (cold) stream i (j) in interval k
# heat provided or received by hot (cold) stream i (j) in interval k
param HLD_Qcjk{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], k in HLD_TempIntervals_ord[ly,lc], j in HLD_Cold[ly,lc]} :=
	if (HLD_Streams_Tin[ly,j] < HLD_TI_tu[ly,lc,k] and HLD_Streams_Tout[ly,j] > HLD_TI_tl[ly,lc,k]) then (
		HLD_Streams_dH[ly,j] * (min(HLD_TI_tu[ly,lc,k],HLD_Streams_Tout[ly,j]) - HLD_TI_tl[ly,lc,k])/ (HLD_Streams_Tout[ly,j] - HLD_Streams_Tin[ly,j])
	) else (
		0
	);

param HLD_Qhik{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], k in HLD_TempIntervals_ord[ly,lc], i in HLD_Hot[ly,lc]} :=
	if (HLD_Streams_Tin[ly,i] > HLD_TI_tl[ly,lc,k] and HLD_Streams_Tout[ly,i] < HLD_TI_tu[ly,lc,k]) then (
		HLD_Streams_dH[ly,i] * (HLD_TI_tu[ly,lc,k] - max(HLD_TI_tl[ly,lc,k],HLD_Streams_Tout[ly,i]))/ (HLD_Streams_Tin[ly,i] - HLD_Streams_Tout[ly,i])
	) else (
		0
	);

# Maximal heat exchange between hot and cold stream in zone z  
param HLD_Uijz{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], i in HLD_Hz[ly,lc,z], j in HLD_Cz[ly,lc,z]}  := 
	min(sum{k in HLD_SubNetworks[ly,lc,z] }(HLD_Qcjk[ly,lc,k,j]*sum {u in HLD_UnitsOfStream[j]} HLD_Units_Fmax_z[ly,lc,z,u]), sum{k in HLD_SubNetworks[ly,lc,z] } (HLD_Qhik[ly,lc,k,i]*sum {u in HLD_UnitsOfStream[i]} HLD_Units_Fmax_z[ly,lc,z,u]));


# Heat load restrictions
param HLD_Qij_min{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], i in HLD_Hot[ly,lc], j in HLD_Cold[ly,lc]} default 0;
param HLD_Qij_max{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], i in HLD_Hot[ly,lc], j in HLD_Cold[ly,lc]} default 
	min(sum{k in HLD_TempIntervals_ord[ly,lc] } (HLD_Qcjk[ly,lc,k,j]*sum {u in HLD_UnitsOfStream[j]} HLD_Units_Fmax[u]), sum{k in HLD_TempIntervals_ord[ly,lc] } (HLD_Qhik[ly,lc,k,i]*sum {u in HLD_UnitsOfStream[i]} HLD_Units_Fmax[u]));



## Variables
# ---------------------------------------------------------------------------------------------------------------------------------------------------

# Integer variable defining if connection between hot stream i and cold stream j, for each subnetwork takes palce
var HLD_y_ijz{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], ig in HLD_Hz_StGroup[ly,lc,z], jg in HLD_Cz_StGroup[ly,lc,z]} binary;

# stream matches for each zone
# number of connections 
var HLD_y_lc{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly]};
subject to HLD_y_lc_constrain{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly]}: 
	HLD_y_lc[ly,lc]=sum{z in HLD_zones[ly,lc], ig in HLD_Hz_StGroup[ly,lc,z], jg in HLD_Cz_StGroup[ly,lc,z]} HLD_y_ijz[ly,lc,z,ig,jg];

# Heat load exchange between hot stream segment i and cold stream segment j
var HLD_Qij{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], i in HLD_Hot[ly,lc], j in HLD_Cold[ly,lc]} >=0;

# Heat load supplied in interval k by hot stream i to cold stream j to the intervals below k
var HLD_Qijk{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], k in HLD_SubNetworks[ly,lc,z], i in HLD_Hk[ly,lc,k], j in HLD_Below_Czk[ly,lc,z,k]} >= 0;


# Heat load exchanged between hot stream i and cold j in zone z
var HLD_Qijz{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], i in HLD_Hz[ly,lc,z], j in HLD_Cz[ly,lc,z]};
subject to HLD_Qijz_constrain{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], i in HLD_Hz[ly,lc,z], j in HLD_Cz[ly,lc,z]}:
	HLD_Qijz[ly,lc,z,i,j]=sum {k in HLD_SubNetworks[ly,lc,z] : i in HLD_Hk[ly,lc,k] and j in HLD_Below_Czk[ly,lc,z,k]} HLD_Qijk[ly,lc,z,k,i,j];

var HLD_Units_Mult{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], u in HLD_Units} >=0;


## Constraints
# ---------------------------------------------------------------------------------------------------------------------------------------------------
## Cascade balances
# ------------------------
# Heat balance in interval k for hot processes HLD_Streams
subject to HLD_HeatBalance_Hot{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], k in HLD_SubNetworks[ly,lc,z], i in HLD_Hk[ly,lc,k]}:
	sum { j in HLD_Below_Czk[ly,lc,z,k] } HLD_Qijk[ly,lc,z,k,i,j] = HLD_Qhik[ly,lc,k,i]* sum {u in HLD_UnitsOfStream[i]} HLD_Units_Mult[ly,lc,u];

#	Heat balance for cold streams 
subject to HLD_HeatBalance_Cold{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], j in HLD_Cz[ly,lc,z]}:
	sum {ki in HLD_Above_ColdStream[ly,lc,z,j], i in HLD_Hk[ly,lc,ki]} HLD_Qijk[ly,lc,z,ki,i,j] - sum{ ki in HLD_SubNetworks[ly,lc,z]} (sum{u in HLD_UnitsOfStream[j]} HLD_Units_Mult[ly,lc,u] * HLD_Qcjk[ly,lc,ki,j]) >=0;

# Maximum heat exchange allowed : defining integer variable
subject to HLD_maxExchange{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], i in HLD_Hz[ly,lc,z], j in HLD_Cz[ly,lc,z],ig in HLD_StreamsGroupsOfStream[i],jg in HLD_StreamsGroupsOfStream[j]} :
sum { k in HLD_SubNetworks[ly,lc,z] : j in HLD_Below_Czk[ly,lc,z,k] and i in HLD_Hk[ly,lc,k]} HLD_Qijk[ly,lc,z,k,i,j] - HLD_Uijz[ly,lc,z,i,j] * HLD_y_ijz[ly,lc,z,ig,jg] <= 0;


subject to HLD_sum_Qij{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], i in HLD_Hot[ly,lc], j in HLD_Cold[ly,lc]} :
	HLD_Qij[ly,lc,i,j] = sum {z in HLD_zones[ly,lc], k in HLD_SubNetworks[ly,lc,z]  : i in HLD_Hk[ly,lc,k] and j in HLD_Below_Czk[ly,lc,z,k]} HLD_Qijk[ly,lc,z,k,i,j];


	
## Unit sizing constraints OK!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# ------------------------------
subject to HLD_cstr_Units_Fmax{u in HLD_Units, ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]} :
	HLD_Units_Mult[ly,lc,u] <= HLD_Units_Fmax[u];

subject to HLD_cstr_Units_Fmin{u in HLD_Units, ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]} :
	HLD_Units_Mult[ly,lc,u] >= HLD_Units_Fmin[u];
	
	
# Introducing penalty when HLD_Units_Mult differs from the multiplication factor calculated by the energy integration, this penalty is introduced in 
# the objective function,in order to get better results and to make the hld calculation more robust 

#var penalty{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], u in HLD_Units};
#subject to cstr_penalty{u in HLD_Units, ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]}:
#penalty[ly,lc,z,u] =  (1 - HLD_Units_Mult[ly,lc,u]);

var penalty_min{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc],u in HLD_Units} <=0 ;
subject to cstr_penalty_min{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc],u in HLD_Units}:
penalty_min[ly,lc,z,u] <= (1 - HLD_Units_Mult[ly,lc,u]);

var penalty_max{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc],u in HLD_Units} >=0 ;
subject to cstr_penalty_max{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc],u in HLD_Units}:
penalty_max[ly,lc,z,u] >= (1 - HLD_Units_Mult[ly,lc,u]);

var penalty_m{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc],u in HLD_Units};
subject to cstr_penalty_m1{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc],u in HLD_Units}:
penalty_m[ly,lc,z,u] <= penalty_max[ly,lc,z,u];
subject to cstr_penalty_m2{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc],u in HLD_Units}:
penalty_m[ly,lc,z,u] >= penalty_min[ly,lc,z,u];


var sum_penalty{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]};
subject to cstr_sum_penalty{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]}:
sum_penalty[ly,lc,z] = (sum{u in HLD_Units} penalty_max[ly,lc,z,u] - sum{u in HLD_Units} penalty_min[ly,lc,z,u]) * 10000;	

## Stream matches ok!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# ------------------------

# Forbidden matches
subject to HLD_Forbidden_Matches_cstr{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc],(i,j) in HLD_Forbidden_MatchesGroups[ly,lc,z]} : 
	HLD_y_ijz[ly,lc,z,i,j] = 0;


# Matches minimum load
subject to HLD_Matches_min_load{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], (i,j) in HLD_Matches[ly,lc]} : 
	HLD_Qij[ly,lc,i,j] >= HLD_Qij_min[ly,lc,i,j];
	
# Matches maximum load
subject to HLD_Matches_max_load{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], (i,j) in HLD_Matches[ly,lc]} : 
	HLD_Qij[ly,lc,i,j] <= HLD_Qij_max[ly,lc,i,j];


# These variables should be computed after solve
var HLD_Streams_Q{ly in HLD_HeatCascades, s in HLD_StreamsOfLayer[ly]};
subject to HLD_Streams_Q_hot{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], s in HLD_StreamsOfLayer[ly] : s in HLD_StreamsOfLocation[lc] and s in HLD_Hot[ly,lc]}: 
		HLD_Streams_Q[ly,s]=sum {j in HLD_Cold[ly,lc]} HLD_Qij[ly,lc,s,j];
subject to HLD_Streams_Q_cold{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], s in HLD_StreamsOfLayer[ly] : s in HLD_StreamsOfLocation[lc] and s in HLD_Cold[ly,lc]}: 
	HLD_Streams_Q[ly,s]=sum {i in HLD_Hot[ly,lc]} HLD_Qij[ly,lc,i,s];


var HLD_Streams_Mcp{ly in HLD_HeatCascades, s in HLD_StreamsOfLayer[ly]};
subject to HLD_Streams_Mcp_def{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], s in HLD_StreamsOfLayer[ly] : s in HLD_StreamsOfLocation[lc]}: 
		HLD_Streams_Mcp[ly,s]=HLD_Streams_Q[ly,s] / abs(HLD_Streams_Tin[ly,s] - HLD_Streams_Tout[ly,s]);


# Objective function
# ----------------------------------------------
minimize HLD_ObjectiveFunction : sum{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc], ig in HLD_Hz_StGroup[ly,lc,z], jg in HLD_Cz_StGroup[ly,lc,z]} HLD_y_ijz[ly,lc,z,ig,jg] + sum{ly in HLD_HeatCascades, lc in HLD_LocationsOfLayer[ly], z in HLD_zones[ly,lc]} sum_penalty[ly,lc,z];
# HLD_e_ijz[ly,lc,z,i,j] 





