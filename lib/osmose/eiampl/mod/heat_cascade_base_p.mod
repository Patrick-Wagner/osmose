# Heat_cascade_base_period.mod 1947 2010-11-11 08:45:17Z Author: S.Fazlollahi $
# $Id: Heat_cascade_base_period.mod 1947 2010-11-11 08:45:17Z fazlollahi $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Heat Cascade Layer - general data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# General data
#-------------------------------------------------------------------------

# Filtering Layers and selecting only layers of type "HeatCascade"
set HeatCascades := if (exists{t in LayerTypes} t = 'HeatCascade') then ({ly in LayersOfType["HeatCascade"]}) else ({});

# This set is defined just to generate required out put data and not necessary for heat cascade calculation
#It is not possible to use ord in glpsol, HC_tempIntervals has to be orderd for calculations with nodes
set HC_TempIntervals{ ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time} ordered; #Set of temperature intervals of each heat cascade 

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

set HC_Hot_loc {ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time} within {st in Streams: st in StreamsOfTime[t]}  :=
{s in HC_Hot[ly,t] : s in StreamsOfTime[t] and s in StreamsOfLocation[lc]};

check {ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time}: card(HC_Hot_loc[ly,lc,t]) > 0;


# Cold streams
set HC_Cold {ly in HeatCascades,t in Time} within Streams :=
{s in StreamsOfLayer[ly]:s in StreamsOfTime[t] and Streams_Hout[ly,s,t]>Streams_Hin[ly,s,t]};

set HC_Cold_loc {ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time} within Streams :=
{s in HC_Cold[ly,t] : s in StreamsOfTime[t] and s in StreamsOfLocation[lc]};

check {ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time}: card(HC_Cold_loc[ly,lc,t]) > 0;	



# Unites 
set HC_Unites {ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time} :=
	{u in UnitsOfLayer[ly]: u in UnitsOfLocation[lc]and u in UnitsOfTime[t] };	


var HC_Streams_Mult{ly in HeatCascades,s in StreamsOfLayer[ly],t in Time}>=0 ;

# heat load of the streams. This variable is required for EI.Equations 
var Streams_Q{ly in HeatCascades, s in StreamsOfLayer[ly], t in Time: s in StreamsOfTime[t]} = Streams_Mcp[ly,s,t] * HC_Streams_Mult[ly,s,t] * abs(Streams_Tin[ly,s,t] - Streams_Tout[ly,s,t]);

#var Streams_Q{ly in HeatCascades, s in StreamsOfLayer[ly],t in Time} >=0;
#subject to Streams_Q_def{ly in HeatCascades, s in StreamsOfLayer[ly], t in Time} : 
#Streams_Q[ly,s,t] = Streams_Mcp[ly,s,t] * HC_Streams_Mult[ly,s,t] * abs(Streams_Tin[ly,s,t] - Streams_Tout[ly,s,t]);

param epsilon := 0.00001;

# QTs
#-------------------------------------------------------------------------

set HC_staticGroups := if (exists{t in StreamBehaviors} t = 'HC_static') then ({g in StreamGroupsOfType['HC_static']}) else ({});
set HC_staticStreams{ly in HeatCascades, t in Time} := setof {g in HC_staticGroups, s in StreamsOfStreamGroup[g] : s in StreamsOfLayer[ly] and s in StreamsOfTime[t]}  (s);

subject to HC_static_Mult_t{ly in HeatCascades, t in Time,s in HC_staticStreams[ly,t], u in UnitsOfStream[s]: s in StreamsOfTime[t] }:
 	Units_Mult_t[u,t] = HC_Streams_Mult[ly,s,t];

#subject to HC_static_Mult{ly in HeatCascades, t in Time,s in HC_staticStreams[ly,t], u in UnitsOfStream[s]: s in StreamsOfTime[t] }:
 #	Units_Mult[u] >= HC_Streams_Mult[ly,s,t];


# variable Streams
# this part is defined for AMPL
#-------------------------------------------------------------------------


set HC_varGroups := if (exists{t in StreamBehaviors} t = 'HC_var') then ({g in StreamGroupsOfType['HC_var']}) else ({});
set HC_varStreams{ly in HeatCascades, g in HC_varGroups, t in Time} := {s in StreamsOfStreamGroup[g] : s in StreamsOfLayer[ly] and s in StreamsOfTime[t]} ordered;

subject to HC_varStreams_Mult_first_t{ly in HeatCascades, g in  HC_varGroups, t in Time, s in  HC_varStreams[ly,g,t], u in UnitsOfStream[s]  : ord(s)=1 and  s in StreamsOfTime[t]}:
	 Units_Mult_t[u,t]= HC_Streams_Mult[ly,s,t];

subject to HC_varStreams_Mult_first{ly in HeatCascades, g in  HC_varGroups, t in Time, s in  HC_varStreams[ly,g,t], u in UnitsOfStream[s]  : ord(s)=1 and  s in StreamsOfTime[t]}:
	 Units_Mult[u]>= HC_Streams_Mult[ly,s,t];


subject to HC_varStreams_Mult_sequence{ly in HeatCascades, g in HC_varGroups, t in Time, s in  HC_varStreams[ly,g,t]  : ord(s)>1 and  s in StreamsOfTime[t]} :
 		HC_Streams_Mult[ly,prev(s)]>= HC_Streams_Mult[ly,s,t];



# Generated Streams
#-------------------------------------------------------------------------
set HC_generatedGroups := if (exists{t in StreamBehaviors} t = 'HC_generated') then ({g in StreamGroupsOfType['HC_generated']}) else ({});
set HC_generatedStreams{ly in HeatCascades, g in HC_generatedGroups,t in Time} := {s in StreamsOfStreamGroup[g] : s in StreamsOfLayer[ly] and s in StreamsOfTime[t]} ordered;

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
set HCR_Forbidden_Matches{ly in HeatCascades, lc in LocationsOfLayer[ly], t in Time} within HCR_Matches[ly,lc,t] default {};

# Unrestricted Matches
set HCR_Unrestricted_Matches{ly in HeatCascades, lc in LocationsOfLayer[ly], t in Time} := HCR_Matches[ly,lc,t] diff HCR_Forbidden_Matches[ly,lc,t];

# Heat load restrictions
param HCR_Qij_min{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, i in HC_Hot_loc[ly,lc,t], j in HC_Cold_loc[ly,lc,t]} default 0;
param HCR_Qij_max{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, i in HC_Hot_loc[ly,lc,t], j in HC_Cold_loc[ly,lc,t]} default min(sum {ui in UnitsOfStream[i]:ui in UnitsOfTime[t]} Streams_dH[ly,i,t]*Units_Fmax[ui,t], sum {uj in UnitsOfStream[j]:uj in UnitsOfTime[t]} Streams_dH[ly,j,t]*Units_Fmax[uj,t]);



