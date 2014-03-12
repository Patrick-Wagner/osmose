#Heat_cascade_base_glpk_period.mod 1947 2010-11-11 08:45:17Z Author: S.Fazlollahi $
#$Id: Heat_cascade_base_glpk_period.mod 1947 2010-11-11 08:45:17Z S.Fazlollahi $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Heat Cascade Layer - general data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# General data
#-------------------------------------------------------------------------

# Filtering Layers and selecting only layers of type "HeatCascade"
set HeatCascades := if (exists{t in LayerTypes} t = 'HeatCascade') then ({ly in LayersOfType["HeatCascade"]}) else ({});

# This set is defined just to generate required out put data and not necessary for heat cascade calculation
#It is not possible to use ord in glpsol, HC_tempIntervals has to be orderd for calculations with nodes
set HC_TempIntervals{ ly in HeatCascades, lc in LocationsOfLayer[ly], t in Time}; #Set of temperature intervals of each heat cascade 

# Thermal streams specification
param Streams_Tin{ly in HeatCascades, s in StreamsOfLayer[ly],t in Time}; 
param Streams_Tout{ly in HeatCascades, s in StreamsOfLayer[ly],t in Time}; 
param Streams_Hin{ly in HeatCascades, s in StreamsOfLayer[ly],t in Time}; 
param Streams_Hout{ly in HeatCascades, s in StreamsOfLayer[ly],t in Time}; 
param Streams_Mcp{ly in HeatCascades, s in StreamsOfLayer[ly],t in Time: s in StreamsOfTime[t]}:= (Streams_Hin[ly,s,t]-Streams_Hout[ly,s,t])/(Streams_Tin[ly,s,t]-Streams_Tout[ly,s,t]);



# It is defined just to generate required out put data and stream_Q ,not necessary for heat cascade calculation
param Streams_dH{ly in HeatCascades, s in StreamsOfLayer[ly],t in Time :s in StreamsOfTime[t]} := if (Streams_Hout[ly,s,t] > Streams_Hin[ly,s,t])
then (Streams_Hout[ly,s,t] - Streams_Hin[ly,s,t])
else (Streams_Hin[ly,s,t] - Streams_Hout[ly,s,t]) >=0;

# Temperature intervals
param HC_TI_tl{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, k in HC_TempIntervals[ly,lc,t]};


# Hot streams 
set HC_Hot {ly in HeatCascades,t in Time} within {st in Streams: st in StreamsOfTime[t]} :=
{s in StreamsOfLayer[ly]: s in StreamsOfTime[t] and Streams_Hout[ly,s,t]<Streams_Hin[ly,s,t]};

set HC_Hot_loc {ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time} within {st in Streams: st in StreamsOfTime[t]}:=
{s in HC_Hot[ly,t] : s in StreamsOfTime[t] and s in StreamsOfLocation[lc]};

check {ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time}: card(HC_Hot_loc[ly,lc,t]) > 0;


# Cold streams
set HC_Cold {ly in HeatCascades,t in Time} within {st in Streams: st in StreamsOfTime[t]}:=
{s in StreamsOfLayer[ly]:s in StreamsOfTime[t] and Streams_Hout[ly,s,t]>Streams_Hin[ly,s,t]};

set HC_Cold_loc {ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time} within {st in Streams: st in StreamsOfTime[t]}  :=
{s in HC_Cold[ly,t] : s in StreamsOfTime[t] and s in StreamsOfLocation[lc]};

check {ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time}: card(HC_Cold_loc[ly,lc,t]) > 0;	



# Unites 
set HC_Unites {ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time} :=
	{u in UnitsOfLayer[ly]: u in UnitsOfLocation[lc]and u in UnitsOfTime[t] };	


var HC_Streams_Mult{ly in HeatCascades,s in StreamsOfLayer[ly],t in Time}>=0 ;

# heat load of the streams. This variable is required for EI.Equations 
#var Streams_Q{ly in HeatCascades, s in StreamsOfLayer[ly], t in Time} = Streams_Mcp[ly,s,t] * HC_Streams_Mult[ly,s,t] * abs(Streams_Tin[ly,s,t] - Streams_Tout[ly,s,t]);

var Streams_Q{ly in HeatCascades, s in StreamsOfLayer[ly],t in Time} >=0;
subject to Streams_Q_def{ly in HeatCascades, s in StreamsOfLayer[ly], t in Time: s in StreamsOfTime[t]} : 
Streams_Q[ly,s,t] = Streams_Mcp[ly,s,t] * HC_Streams_Mult[ly,s,t] * abs(Streams_Tin[ly,s,t] - Streams_Tout[ly,s,t]);

param epsilon := 0.00001;

# QTs
#-------------------------------------------------------------------------

set HC_staticGroups := if (exists{t in StreamBehaviors} t = 'HC_static') then ({g in StreamGroupsOfType['HC_static']}) else ({});
set HC_staticStreams{ly in HeatCascades, t in Time} := setof {g in HC_staticGroups, s in StreamsOfStreamGroup[g] : s in StreamsOfLayer[ly] and s in StreamsOfTime[t]}  (s);

subject to HC_static_Mult_t{ly in HeatCascades, t in Time,s in HC_staticStreams[ly,t], u in UnitsOfStream[s]: s in StreamsOfTime[t] }:
 	Units_Mult_t[u,t] = HC_Streams_Mult[ly,s,t];

#subject to HC_static_Mult{ly in HeatCascades, t in Time,s in HC_staticStreams[ly,t], u in UnitsOfStream[s]: s in StreamsOfTime[t] }:
# 	Units_Mult[u] >= HC_Streams_Mult[ly,s,t];


# variable Streams
# this part is defined for GLPK ( works also for ampl) 
#-------------------------------------------------------------------------


set HC_varGroups := if (exists{t in StreamBehaviors} t = 'HC_var') then ({g in StreamGroupsOfType['HC_var']}) else ({});
set HC_varStreams{ly in HeatCascades, g in HC_varGroups, t in Time} := {s in StreamsOfStreamGroup[g] : s in StreamsOfLayer[ly] and s in StreamsOfTime[t]};

 
## Ordered definition
# create an index set 
set T{ly in HeatCascades, g in HC_varGroups,t in Time}:= {1..card(HC_varStreams[ly,g,t])}; 
# create a set of sets 
set tr_p_1{ly in HeatCascades, g in HC_varGroups,t in Time, i in T[ly,g,t]} := setof{ r in HC_varStreams[ly,g,t] : sum{q in HC_varStreams[ly,g,t] : Streams_Tin[ly,q,t]<= Streams_Tout[ly,q,t] and Streams_Tin[ly,q,t] <= Streams_Tin[ly,r,t]} 1 = i } r; 
set tr_p_2{ly in HeatCascades, g in HC_varGroups,t in Time,i in T[ly,g,t]} := setof{ r in HC_varStreams[ly,g,t] : sum{q in HC_varStreams[ly,g,t] : Streams_Tin[ly,q,t]> Streams_Tout[ly,q,t] and Streams_Tin[ly,q,t] >= Streams_Tin[ly,r,t]} 1 = i } r; 
set tr_p{ly in HeatCascades, g in HC_varGroups,t in Time,i in T[ly,g,t]} := tr_p_1[ly,g,t,i]union tr_p_2[ly,g,t,i] ;

# create an ordered set 
set HC_varStreams_ord{ly in HeatCascades, g in HC_varGroups,t in Time} := setof{ i in T[ly,g,t],p in tr_p[ly,g,t,i]}p; 


subject to HC_varStreams_Mult_first_t{ly in HeatCascades, g in  HC_varGroups,t in Time, s in  HC_varStreams_ord[ly,g,t],sfirst in tr_p[ly,g,t,1]:s=sfirst and s in StreamsOfTime[t]}:
sum {u in UnitsOfStream[s]} Units_Mult_t[u,t]= HC_Streams_Mult[ly,s,t];

subject to HC_varStreams_Mult_first{ly in HeatCascades, g in  HC_varGroups,t in Time, s in  HC_varStreams_ord[ly,g,t],sfirst in tr_p[ly,g,t,1]:s=sfirst and s in StreamsOfTime[t]}:
sum {u in UnitsOfStream[s]} Units_Mult[u]>= HC_Streams_Mult[ly,s,t];

subject to HC_varStreams_Mult_sequence{ly in HeatCascades, g in HC_varGroups, t in Time,s in  HC_varStreams_ord[ly,g,t],i in T[ly,g,t] diff{1},scurent in tr_p[ly,g,t,i],spreve in tr_p[ly,g,t,i-1] : s = scurent and s in StreamsOfTime[t] } :
HC_Streams_Mult[ly,spreve,t]>= HC_Streams_Mult[ly,s,t];

# Generated Streams
#-------------------------------------------------------------------------
set HC_generatedGroups := if (exists{t in StreamBehaviors} t = 'HC_generated') then ({g in StreamGroupsOfType['HC_generated']}) else ({});
set HC_generatedStreams{ly in HeatCascades, g in HC_generatedGroups,t in Time} := {s in StreamsOfStreamGroup[g] : s in StreamsOfLayer[ly] and s in StreamsOfTime[t]} ;

# Has HC_generatedStreams to be an ordered set ? 
### Ordered definition
## create an index set 
#set T{ly in HeatCascades, g in HC_varGroups}:= {1..card(HC_varStreams[ly,g])}; 
## create a set of sets 
#set tr_p_1{ly in HeatCascades, g in HC_varGroups,i in T[ly,g]} := setof{ r in HC_varStreams[ly,g] : sum{q in HC_varStreams[ly,g] : Streams_Tin[ly,q]<= Streams_Tout[ly,q] and Streams_Tin[ly,q] <= Streams_Tin[ly,r]} 1 = i } r; 
#set tr_p_2{ly in HeatCascades, g in HC_varGroups,i in T[ly,g]} := setof{ r in HC_varStreams[ly,g] : sum{q in HC_varStreams[ly,g] : Streams_Tin[ly,q]> Streams_Tout[ly,q] and Streams_Tin[ly,q] >= Streams_Tin[ly,r]} 1 = i } r; 
#set tr_p{ly in HeatCascades, g in HC_varGroups,i in T[ly,g]} := tr_p_1[ly,g,i]union tr_p_2[ly,g,i] ;

#var HC_generatedGroups_load{ly in HeatCascades, g in HC_generatedGroups, gm in StreamGroupsMasters[g], t in Time} = sum{s in HC_generatedStreams[ly,g,t]} Streams_Mcp[ly,s,t]*HC_Streams_Mult[ly,s,t]*abs(Streams_Tin[ly,s,t]-Streams_Tout[ly,s,t]);

var HC_generatedGroups_load{ly in HeatCascades, g in HC_generatedGroups, gm in StreamGroupsMasters[g],t in Time}; 
subject to HC_generatedGroups_load_var{ly in HeatCascades, g in HC_generatedGroups, gm in StreamGroupsMasters[g], t in Time}:
HC_generatedGroups_load[ly,g,gm,t]= sum{s in HC_generatedStreams[ly,g,t]} Streams_Q[ly,s,t];




## Stream matches
# ------------------------

# Matches
set HCR_Matches{ly in HeatCascades, lc in LocationsOfLayer[ly], t in Time} := {HC_Hot_loc[ly,lc,t] cross HC_Cold_loc[ly,lc,t]};

# Forbidden matches
#set HCR_Forbidden_Matches{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time} within HCR_Matches[ly,lc,t] default {};
set HCR_Forbidden_Matches{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time} within HCR_Matches[ly,lc,t] default {} cross {};

# Unrestricted Matches
set HCR_Unrestricted_Matches{ly in HeatCascades, lc in LocationsOfLayer[ly], t in Time} := HCR_Matches[ly,lc,t] diff HCR_Forbidden_Matches[ly,lc,t];

# Heat load restrictions
param HCR_Qij_min{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, i in HC_Hot_loc[ly,lc,t], j in HC_Cold_loc[ly,lc,t]} default 0;
param HCR_Qij_max{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, i in HC_Hot_loc[ly,lc,t], j in HC_Cold_loc[ly,lc,t]} default min(sum {ui in UnitsOfStream[i]:ui in UnitsOfTime[t]} Streams_dH[ly,i,t]*Units_Fmax[ui], sum {uj in UnitsOfStream[j]:uj in UnitsOfTime[t]} Streams_dH[ly,j,t]*Units_Fmax[uj]);


