# $Id: thermal.mod 1847 2009-11-05 08:45:17Z bolliger $
# $Id: heat_cascade_glpsol.mod 2126 2010-03-23 14:56:33Z S.Fazlollahi $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Heat Cascade Layer - general data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# General data
#-------------------------------------------------------------------------

# Filtering Layers and selecting only layers of type "HeatCascade"
set HeatCascades := if (exists{t in LayerTypes} t = 'HeatCascade') then ({ly in LayersOfType["HeatCascade"]}) else ({});

# This set is defined just to generate required out put data and not necessary for heat cascade calculation
#It is not possible to use ord in glpsol, HC_tempIntervals has to be orderd for calculations with nodes
set HC_TempIntervals{ ly in HeatCascades, lc in LocationsOfLayer[ly]}; #Set of temperature intervals of each heat cascade 

# Thermal streams specification
param Streams_Tin{ly in HeatCascades, s in StreamsOfLayer[ly]}; 
param Streams_Tout{ly in HeatCascades, s in StreamsOfLayer[ly]}; 
param Streams_Hin{ly in HeatCascades, s in StreamsOfLayer[ly]}; 
param Streams_Hout{ly in HeatCascades, s in StreamsOfLayer[ly]}; 
param Streams_Mcp{ly in HeatCascades, s in StreamsOfLayer[ly]}:= (Streams_Hin[ly,s]-Streams_Hout[ly,s])/(Streams_Tin[ly,s]-Streams_Tout[ly,s]);


# It is defined just to generate required out put data and stream_Q ,not necessary for heat cascade calculation
param Streams_dH{ly in HeatCascades, s in StreamsOfLayer[ly]} := if (Streams_Hout[ly,s] > Streams_Hin[ly,s])
then (Streams_Hout[ly,s] - Streams_Hin[ly,s])
else (Streams_Hin[ly,s] - Streams_Hout[ly,s]) >=0;


# Temperature intervals
param HC_TI_tl{ly in HeatCascades, lc in LocationsOfLayer[ly], k in HC_TempIntervals[ly,lc]};


# Hot streams 
set HC_Hot {ly in HeatCascades} within Streams :=
{s in StreamsOfLayer[ly]:Streams_Hout[ly,s]<Streams_Hin[ly,s]};

set HC_Hot_loc {ly in HeatCascades, lc in LocationsOfLayer[ly]} within Streams :=
{s in HC_Hot[ly] : s in StreamsOfLocation[lc]};

check {ly in HeatCascades, lc in LocationsOfLayer[ly]: card(StreamsOfLayer[ly]) > 0}: card(HC_Hot_loc[ly,lc]) > 0;


# Cold streams
set HC_Cold {ly in HeatCascades} within Streams :=
{s in StreamsOfLayer[ly]:Streams_Hout[ly,s]>Streams_Hin[ly,s]};

set HC_Cold_loc {ly in HeatCascades, lc in LocationsOfLayer[ly]} within Streams :=
{s in HC_Cold[ly] : s in StreamsOfLocation[lc]};

check {ly in HeatCascades, lc in LocationsOfLayer[ly]: card(StreamsOfLayer[ly]) > 0}: card(HC_Cold_loc[ly,lc]) > 0;	



# Unites 
set HC_Unites {ly in HeatCascades, lc in LocationsOfLayer[ly]} :=
	{u in UnitsOfLayer[ly]: u in UnitsOfLocation[lc] };	


var HC_Streams_Mult{ly in HeatCascades,s in StreamsOfLayer[ly]}>=0 ;

# heat load of the streams. This variable is required for EI.Equations 
var Streams_Q{ly in HeatCascades, s in StreamsOfLayer[ly]} >=0;
subject to Streams_Q_def{ly in HeatCascades, s in StreamsOfLayer[ly]} : 
Streams_Q[ly,s] = Streams_Mcp[ly,s] * HC_Streams_Mult[ly,s] * abs(Streams_Tin[ly,s] - Streams_Tout[ly,s]);

param epsilon := 0.00001;

# QTs
#-------------------------------------------------------------------------

set HC_staticGroups := if (exists{t in StreamBehaviors} t = 'HC_static') then ({g in StreamGroupsOfType['HC_static']}) else ({});
set HC_staticStreams{ly in HeatCascades} := setof {g in HC_staticGroups, s in StreamsOfStreamGroup[g] : s in StreamsOfLayer[ly]}  (s);


subject to HC_static_Mult{ly in HeatCascades, s in HC_staticStreams[ly], u in UnitsOfStream[s]}:
 	Units_Mult[u] = HC_Streams_Mult[ly,s];


# variable Streams
# this part is defined for GLPK ( works also for ampl) 
#-------------------------------------------------------------------------


set HC_varGroups := if (exists{t in StreamBehaviors} t = 'HC_var') then ({g in StreamGroupsOfType['HC_var']}) else ({});
set HC_varStreams{ly in HeatCascades, g in HC_varGroups} := {s in StreamsOfStreamGroup[g] : s in StreamsOfLayer[ly]} ;

 
## Ordered definition
# create an index set 
set T{ly in HeatCascades, g in HC_varGroups}:= {1..card(HC_varStreams[ly,g])}; 
# create a set of sets 
set tr_p_1{ly in HeatCascades, g in HC_varGroups,i in T[ly,g]} := setof{ r in HC_varStreams[ly,g] : sum{q in HC_varStreams[ly,g] : Streams_Tin[ly,q]<= Streams_Tout[ly,q] and Streams_Tin[ly,q] <= Streams_Tin[ly,r]} 1 = i } r; 
set tr_p_2{ly in HeatCascades, g in HC_varGroups,i in T[ly,g]} := setof{ r in HC_varStreams[ly,g] : sum{q in HC_varStreams[ly,g] : Streams_Tin[ly,q]> Streams_Tout[ly,q] and Streams_Tin[ly,q] >= Streams_Tin[ly,r]} 1 = i } r; 
set tr_p{ly in HeatCascades, g in HC_varGroups,i in T[ly,g]} := tr_p_1[ly,g,i]union tr_p_2[ly,g,i] ;

# create an ordered set 
set HC_varStreams_ord{ly in HeatCascades, g in HC_varGroups} := setof{ i in T[ly,g],t in tr_p[ly,g,i]}t; 

subject to HC_varStreams_Mult_first{ly in HeatCascades, g in  HC_varGroups, s in  HC_varStreams_ord[ly,g],sfirst in tr_p[ly,g,1]:s=sfirst}:
sum {u in UnitsOfStream[s]} Units_Mult[u]= HC_Streams_Mult[ly,s];

subject to HC_varStreams_Mult_sequence{ly in HeatCascades, g in HC_varGroups, s in  HC_varStreams_ord[ly,g],i in T[ly,g] diff{1},scurent in tr_p[ly,g,i],spreve in tr_p[ly,g,i-1] : s = scurent } :
HC_Streams_Mult[ly,spreve]>= HC_Streams_Mult[ly,s];

# Generated Streams
#-------------------------------------------------------------------------
set HC_generatedGroups := if (exists{t in StreamBehaviors} t = 'HC_generated') then ({g in StreamGroupsOfType['HC_generated']}) else ({});
set HC_generatedStreams{ly in HeatCascades, g in HC_generatedGroups} := {s in StreamsOfStreamGroup[g] : s in StreamsOfLayer[ly]};

# Has HC_generatedStreams to be an ordered set ? 
### Ordered definition
## create an index set 
#set T{ly in HeatCascades, g in HC_varGroups}:= {1..card(HC_varStreams[ly,g])}; 
## create a set of sets 
#set tr_p_1{ly in HeatCascades, g in HC_varGroups,i in T[ly,g]} := setof{ r in HC_varStreams[ly,g] : sum{q in HC_varStreams[ly,g] : Streams_Tin[ly,q]<= Streams_Tout[ly,q] and Streams_Tin[ly,q] <= Streams_Tin[ly,r]} 1 = i } r; 
#set tr_p_2{ly in HeatCascades, g in HC_varGroups,i in T[ly,g]} := setof{ r in HC_varStreams[ly,g] : sum{q in HC_varStreams[ly,g] : Streams_Tin[ly,q]> Streams_Tout[ly,q] and Streams_Tin[ly,q] >= Streams_Tin[ly,r]} 1 = i } r; 
#set tr_p{ly in HeatCascades, g in HC_varGroups,i in T[ly,g]} := tr_p_1[ly,g,i]union tr_p_2[ly,g,i] ;


var HC_generatedGroups_load{ly in HeatCascades, g in HC_generatedGroups, gm in StreamGroupsMasters[g]}; 
subject to HC_generatedGroups_load_var{ly in HeatCascades, g in HC_generatedGroups, gm in StreamGroupsMasters[g]}:
HC_generatedGroups_load[ly,g,gm]= sum{s in HC_generatedStreams[ly,g]} Streams_Q[ly,s];


## Stream matches
# ------------------------

# Matches
set HCR_Matches{ly in HeatCascades, lc in LocationsOfLayer[ly]} := {HC_Hot_loc[ly,lc] cross HC_Cold_loc[ly,lc]};

# Forbidden matches
#set HCR_Forbidden_Matches{ly in HeatCascades, lc in LocationsOfLayer[ly]} within HCR_Matches[ly,lc] default {};
set HCR_Forbidden_Matches{ly in HeatCascades, lc in LocationsOfLayer[ly]} within HCR_Matches[ly,lc] default {} cross {};

# Unrestricted Matches
set HCR_Unrestricted_Matches{ly in HeatCascades, lc in LocationsOfLayer[ly]} := HCR_Matches[ly,lc] diff HCR_Forbidden_Matches[ly,lc];

# Heat load restrictions
param HCR_Qij_min{ly in HeatCascades, lc in LocationsOfLayer[ly], i in HC_Hot_loc[ly,lc], j in HC_Cold_loc[ly,lc]} default 0;
param HCR_Qij_max{ly in HeatCascades, lc in LocationsOfLayer[ly], i in HC_Hot_loc[ly,lc], j in HC_Cold_loc[ly,lc]} default min(sum {ui in UnitsOfStream[i]} Streams_dH[ly,i]*Units_Fmax[ui], sum {uj in UnitsOfStream[j]} Streams_dH[ly,j]*Units_Fmax[uj]);
