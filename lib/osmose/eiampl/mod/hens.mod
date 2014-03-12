# $Id: thermal.mod 1847 2009-11-05 08:45:17Z bolliger $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Heat Exchangers Network synthesis
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Author: RBolliger
#
# Adapted from FMarechal. Based on formulation by Floudas, Ciric & Grossmann

# this version is developed to calculate the heat exchangers based on the results of the heat load distribution
# the only optimisation that is done is the flows in the system to find the HEN configuration
# the objective function is the cost of the heat exchangers

# Locations
# ----------------------------------------------
set HS_Locations;

# Layers
# ----------------------------------------------
set HS_LayerTypes;
set HS_Layers;
set HS_LayersOfType{ly in HS_LayerTypes} within HS_Layers;

# Filtering Layers and selecting only layers of type "HeatCascade"
set HS_HeatCascades := if (exists{t in HS_LayerTypes} t = 'HeatCascade') then ({ly in HS_LayersOfType["HeatCascade"]}) else ({});

set HS_LocationsOfLayer{ly in HS_Layers} within HS_Locations;

set HS_thisPlace := {ly in HS_HeatCascades, lc in HS_LocationsOfLayer[ly]};

# Sub-networks
# ----------------------------------------------
set HS_SubNetworks{ (ly,lc) in HS_thisPlace} ordered;

set HS_thisZone := {(ly,lc) in HS_thisPlace, sn in HS_SubNetworks[ly,lc]};

# Lower and upper corrected temperatures of each SN
param HS_SN_Tu{(ly,lc,sn) in HS_thisZone};
param HS_SN_Tl{(ly,lc,sn) in HS_thisZone};


# Units
# ----------------------------------------------
set HS_Units;

# Units sizing contraints
param HS_U_Fmin{u in HS_Units}; 
param HS_U_Fmax{u in HS_Units}; 



# Streams
# ----------------------------------------------
# set of streams in the system defined by inlet and outlet temperature, cp  and nominal flow and heat film transfer coefficient

set HS_Streams;

set HS_UnitsOfStream{s in HS_Streams} within HS_Units;

set HS_StreamsOfLayer{ly in HS_Layers} within HS_Streams;
set HS_StreamsOfLocation{lc in HS_Locations} within HS_Streams;

param HS_S_Tin_corr{ly in HS_HeatCascades, s in HS_StreamsOfLayer[ly]}    > 0;
param HS_S_Tout_corr{ly in HS_HeatCascades, s in HS_StreamsOfLayer[ly]}   > 0;

param HS_S_mcp{ly in HS_HeatCascades, s in HS_StreamsOfLayer[ly]}    >=0;

param HS_S_h{ly in HS_HeatCascades, s in HS_StreamsOfLayer[ly]}      > 0;
param HS_S_DTmin2{ly in HS_HeatCascades, s in HS_StreamsOfLayer[ly]} > 0;


set HS_S_Hot{ly in HS_HeatCascades}  := { s in HS_StreamsOfLayer[ly] :HS_S_Tin_corr[ly,s] > HS_S_Tout_corr[ly,s]};
set HS_S_Cold{ly in HS_HeatCascades} := { s in HS_StreamsOfLayer[ly] :HS_S_Tin_corr[ly,s] < HS_S_Tout_corr[ly,s]};

# Corrected temperatures
param HS_S_Tin{ly in HS_HeatCascades, s in HS_StreamsOfLayer[ly]}   := 
	if (s in HS_S_Hot[ly]) then (
		HS_S_Tin_corr[ly,s] + HS_S_DTmin2[ly,s] 
		) else (
		HS_S_Tin_corr[ly,s] - HS_S_DTmin2[ly,s]
	);
param HS_S_Tout{ly in HS_HeatCascades, s in HS_StreamsOfLayer[ly]}   :=
	if (s in HS_S_Hot[ly]) then (
		HS_S_Tout_corr[ly,s] + HS_S_DTmin2[ly,s] 
		) else (
		HS_S_Tout_corr[ly,s] - HS_S_DTmin2[ly,s]
	);


set HS_StreamsOfSubNetwork{(ly,lc,sn) in HS_thisZone} := 
	{s in HS_Streams : 	((s in HS_S_Hot[ly] and HS_S_Tin_corr[ly,s]>HS_SN_Tl[ly,lc,sn] and HS_S_Tout_corr[ly,s]<HS_SN_Tu[ly,lc,sn]) or
					   	(s in HS_S_Cold[ly] and HS_S_Tin_corr[ly,s]<HS_SN_Tu[ly,lc,sn] and HS_S_Tout_corr[ly,s]>HS_SN_Tl[ly,lc,sn])) and
					   	s in HS_StreamsOfLocation[lc] and
					   	HS_S_mcp[ly,s] > 0};


# Hot and cold streams of each sub-network
set HS_Hz{(ly,lc,sn) in HS_thisZone} := { HS_StreamsOfSubNetwork[ly,lc,sn] intersect HS_S_Hot[ly] };
set HS_Cz{(ly,lc,sn) in HS_thisZone} := { HS_StreamsOfSubNetwork[ly,lc,sn] intersect HS_S_Cold[ly] };

# Input and output temperature of streams for each zone
param HS_S_Tin_z{(ly,lc,sn) in HS_thisZone, s in HS_StreamsOfSubNetwork[ly,lc,sn]}   := 
	if (s in HS_S_Hot[ly]) then (
		min(HS_S_Tin[ly,s],HS_SN_Tu[ly,lc,sn] + HS_S_DTmin2[ly,s])
		) else (
		max(HS_S_Tin[ly,s],HS_SN_Tl[ly,lc,sn] - HS_S_DTmin2[ly,s])
	);
param HS_S_Tout_z{(ly,lc,sn) in HS_thisZone, s in HS_StreamsOfSubNetwork[ly,lc,sn]}   :=
	if (s in HS_S_Hot[ly]) then (
		max(HS_S_Tout[ly,s],HS_SN_Tl[ly,lc,sn] + HS_S_DTmin2[ly,s])
		) else (
		min(HS_S_Tout[ly,s],HS_SN_Tu[ly,lc,sn] - HS_S_DTmin2[ly,s])
	);

# Mcp may vary in a limited range, for each sub-network
var HS_S_mcp_f{(ly,lc,sn) in HS_thisZone, s in HS_StreamsOfSubNetwork[ly,lc,sn]} >= sum{u in HS_UnitsOfStream[s]} HS_U_Fmin[u] , <= sum{u in HS_UnitsOfStream[s]} HS_U_Fmax[u] :=1;

# Minimal temperature difference between stream input and output temperature to allow exchangers in serie
param HS_S_serieTol:= 1;


# Heat exchangers
# ----------------------------------------------

set HS_HeatExchangers{(ly,lc,sn) in HS_thisZone}; # set of heat exchangers

set HS_thisHX = {(ly,lc,sn) in HS_thisZone, e in HS_HeatExchangers[ly,lc,sn]};

param HS_HX_HS		{(ly,lc,sn,e) in HS_thisHX}  symbolic within HS_Hz[ly,lc,sn];   # hot stream of the heat exchanger e
param HS_HX_CS		{(ly,lc,sn,e) in HS_thisHX}  symbolic within HS_Cz[ly,lc,sn];  # cold stream of the heat exchanger e

param HS_HX_Q		{(ly,lc,sn,e) in HS_thisHX}  >  0;

# Limiting Q within a range
param HS_HX_Qf_max ;
param HS_HX_Qf_min;
var   HS_HX_Qf		{(ly,lc,sn,e) in HS_thisHX}  >=  HS_HX_Qf_min, <=HS_HX_Qf_max, := 1;

param HS_HX_U		{(ly,lc,sn,e) in HS_thisHX}  =   1./HS_S_h[ly,HS_HX_HS[ly,lc,sn,e]] + 1./HS_S_h[ly,HS_HX_CS[ly,lc,sn,e]];
param HS_HX_DTmin	{(ly,lc,sn,e) in HS_thisHX}  =   HS_S_DTmin2[ly,HS_HX_HS[ly,lc,sn,e]] + HS_S_DTmin2[ly,HS_HX_CS[ly,lc,sn,e]];

var HS_HX_h_Tin		{(ly,lc,sn,e) in HS_thisHX}  <=  HS_S_Tin_z[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]], >= HS_S_Tout_z[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]], := HS_S_Tin_z[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]];
var HS_HX_c_Tin		{(ly,lc,sn,e) in HS_thisHX}  >=  HS_S_Tin_z[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]], <= HS_S_Tout_z[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]], := HS_S_Tin_z[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]];
var HS_HX_h_Tout	{(ly,lc,sn,e) in HS_thisHX}  <=  HS_S_Tin_z[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]], >= HS_S_Tout_z[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]], := HS_S_Tout_z[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]];
var HS_HX_c_Tout	{(ly,lc,sn,e) in HS_thisHX}  >=  HS_S_Tin_z[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]], <= HS_S_Tout_z[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]], := HS_S_Tout_z[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]];

var HS_HX_h_DT		{(ly,lc,sn,e) in HS_thisHX}  = HS_HX_h_Tin[ly,lc,sn,e] - HS_HX_h_Tout[ly,lc,sn,e]; 
var HS_HX_c_DT		{(ly,lc,sn,e) in HS_thisHX}  = HS_HX_c_Tout[ly,lc,sn,e] - HS_HX_c_Tin[ly,lc,sn,e];

# temperature difference on the hot and cold side of the exchanger
var HS_HX_h_DTmin	{(ly,lc,sn,e) in HS_thisHX}  >=  HS_HX_DTmin[ly,lc,sn,e], :=HS_HX_DTmin[ly,lc,sn,e]; 
var HS_HX_c_DTmin	{(ly,lc,sn,e) in HS_thisHX}  >=  HS_HX_DTmin[ly,lc,sn,e], := HS_HX_DTmin[ly,lc,sn,e]; 

# ratio of the flow in the hot and cold side of the heat exchanger
var HS_HX_h_mcpr		{(ly,lc,sn,e) in HS_thisHX}  >=  0, <=1 := HS_HX_Q[ly,lc,sn,e]/(HS_S_Tin_z[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]]-HS_S_Tout_z[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]])/HS_S_mcp[ly,HS_HX_HS[ly,lc,sn,e]]; 
var HS_HX_c_mcpr		{(ly,lc,sn,e) in HS_thisHX}  >=  0, <=1 := HS_HX_Q[ly,lc,sn,e]/(HS_S_Tout_z[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]]-HS_S_Tin_z[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]])/HS_S_mcp[ly,HS_HX_CS[ly,lc,sn,e]]; 

# Paterson (1984) approximation of LMTD
var HS_HX_lmtd		{(ly,lc,sn,e) in HS_thisHX}  = (HS_HX_h_DTmin[ly,lc,sn,e]+HS_HX_c_DTmin[ly,lc,sn,e])/6 + 2/3*sqrt(HS_HX_h_DTmin[ly,lc,sn,e]*HS_HX_c_DTmin[ly,lc,sn,e]); 
  
# Exchanger area
var HS_HX_A		{(ly,lc,sn,e) in HS_thisHX}  = HS_HX_Q[ly,lc,sn,e]*HS_HX_Qf[ly,lc,sn,e]*HS_HX_U[ly,lc,sn,e]/HS_HX_lmtd[ly,lc,sn,e]; # area of the heat exchange 



# Connections between heat exchangers
# ----------------------------------------------


# Links between streams and heat exchangers
set HS_Connections{(ly,lc,sn) in HS_thisZone, s in HS_StreamsOfSubNetwork[ly,lc,sn]} := {e in HS_HeatExchangers[ly,lc,sn]: HS_HX_HS[ly,lc,sn,e] == s or HS_HX_CS[ly,lc,sn,e]== s} ;

# Direct connection from inlet of stream i to exchanger e
var HS_CN_se_mcpr{(ly,lc,sn) in HS_thisZone, s in HS_StreamsOfSubNetwork[ly,lc,sn], cn in HS_Connections[ly,lc,sn,s]} >= 0, <=1, := 1/card(HS_Connections[ly,lc,sn,s]) ; # flow of stream i to exchanger e

# Direct connection from exchangers to stream output
var HS_CN_es_mcpr {(ly,lc,sn) in HS_thisZone, s in HS_StreamsOfSubNetwork[ly,lc,sn], cn in HS_Connections[ly,lc,sn,s]} >= 0, <=1, := 1/card(HS_Connections[ly,lc,sn,s]) ; # flow of stream i from exchanger e after split

# Connections between exchangers (hot and cold part)
var HS_CN_hee_mcpr{(ly,lc,sn,e) in HS_thisHX, ec in HS_Connections[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]] : ec <> e } >= 0, <=1, :=0; # flow from exchanger ec to exchanger e
var HS_CN_cee_mcpr{(ly,lc,sn,e) in HS_thisHX, ec in HS_Connections[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]] : ec <> e } >= 0, <=1, :=0;

#var HS_CN_hee_y{(ly,lc,sn,e) in HS_thisHX, ec in HS_Connections[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]] : ec <> e } binary, :=1; # flow from exchanger ec to exchanger e exists?
#var HS_CN_cee_y{(ly,lc,sn,e) in HS_thisHX, ec in HS_Connections[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]] : ec <> e } binary, :=1;

# Costing
# ----------------------------------------------

# Heat exchangers cost 
# c = C_hxref (A/Aref)^gamma
param HS_HX_C_Cref  > 0;
param HS_HX_C_Aref  > 0;
param HS_HX_C_gamma > 0;

var HS_HX_Cost{(ly,lc,sn,e) in HS_thisHX}    =  HS_HX_C_Cref *(HS_HX_A[ly,lc,sn,e]/HS_HX_C_Aref)**HS_HX_C_gamma; # area of the heat exchange

var HS_HX_Cost_loc{(ly,lc) in HS_thisPlace} = sum{sn in HS_SubNetworks[ly,lc], e in HS_HeatExchangers[ly,lc,sn]} HS_HX_Cost[ly,lc,sn,e];

# average cost of the heat exchangers in this location
var HS_HX_Cost_mean{(ly,lc) in HS_thisPlace} = (HS_HX_Cost_loc[ly,lc])/ card( setof{sn in HS_SubNetworks[ly,lc], ecsn in HS_HeatExchangers[ly,lc,sn]} ecsn);

var HS_HX_Cost_ly{ly in HS_HeatCascades} = sum{lc in HS_LocationsOfLayer[ly] } HS_HX_Cost_loc[ly,lc];


# Pipes cost

#param HS_P_Cratio; # reference cost with respect to HS_HX_C_Cref
#param HS_P_Mcpref; # reference Mpc


# Cost of pipes is max 1/HS_P_Cratio times the cost of the HX. We use min(A[e],A[ec]) because we don't want to feed large exchagners from small ones.
#var HS_P_Cost_hee{(ly,lc,sn,e) in HS_thisHX, ec in HS_Connections[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]] : ec <> e} = 
#	if (HS_CN_hee_mcpr[ly,lc,sn,e,ec] = 0) then
#		(0) else
#	(HS_P_Cratio * HS_HX_Cost_mean[ly,lc] * (HS_CN_hee_mcpr[ly,lc,sn,e,ec]/HS_P_Mcpref)**(-HS_HX_C_gamma));
	
#var HS_P_Cost_cee{(ly,lc,sn,e) in HS_thisHX, ec in HS_Connections[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]] : ec <> e} = 
#	if (HS_CN_cee_mcpr[ly,lc,sn,e,ec] = 0) then
#		(0) else
#	(HS_P_Cratio * HS_HX_Cost_mean[ly,lc] * (HS_CN_cee_mcpr[ly,lc,sn,e,ec]/HS_P_Mcpref)**(-HS_HX_C_gamma));
	
#var HS_P_Cost_se{(ly,lc,sn) in HS_thisZone, s in HS_StreamsOfSubNetwork[ly,lc,sn], cn in HS_Connections[ly,lc,sn,s]} = 
#	if (HS_CN_se_mcpr[ly,lc,sn,s,cn] = 0) then
#		(0) else
#	(HS_P_Cratio * HS_HX_Cost_mean[ly,lc] * (HS_CN_se_mcpr[ly,lc,sn,s,cn]/HS_P_Mcpref)**(-HS_HX_C_gamma));
	
#var HS_P_Cost_es{(ly,lc,sn) in HS_thisZone, s in HS_StreamsOfSubNetwork[ly,lc,sn], cn in HS_Connections[ly,lc,sn,s]} = 
#	if (HS_CN_es_mcpr[ly,lc,sn,s,cn] = 0) then
#		(0) else
#	(HS_P_Cratio * HS_HX_Cost_mean[ly,lc] * (HS_CN_es_mcpr[ly,lc,sn,s,cn]/HS_P_Mcpref)**(-HS_HX_C_gamma));

#var HS_P_Cost_ly{ly in HS_HeatCascades} = 
#	sum {lc in HS_LocationsOfLayer[ly], sn in HS_SubNetworks[ly,lc], e in HS_HeatExchangers[ly,lc,sn],ec in HS_Connections[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]] : ec <> e} HS_P_Cost_hee[ly,lc,sn,e,ec]
#  + sum {lc in HS_LocationsOfLayer[ly], sn in HS_SubNetworks[ly,lc], e in HS_HeatExchangers[ly,lc,sn],ec in HS_Connections[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]] : ec <> e} HS_P_Cost_cee[ly,lc,sn,e,ec]
#  + sum {lc in HS_LocationsOfLayer[ly], sn in HS_SubNetworks[ly,lc], s in HS_StreamsOfSubNetwork[ly,lc,sn], cn in HS_Connections[ly,lc,sn,s]} HS_P_Cost_se[ly,lc,sn,s,cn]
#  + sum {lc in HS_LocationsOfLayer[ly], sn in HS_SubNetworks[ly,lc], s in HS_StreamsOfSubNetwork[ly,lc,sn], cn in HS_Connections[ly,lc,sn,s]} HS_P_Cost_es[ly,lc,sn,s,cn]
#  ;
  
  

# Problem constraints
# ----------------------------------------------

# mass balance for splitter at stream inlet
subject to HS_S_InletSplit_MassBalance {(ly,lc,sn) in HS_thisZone, s in HS_StreamsOfSubNetwork[ly,lc,sn]}:
	sum{c in HS_Connections[ly,lc,sn,s]} HS_CN_se_mcpr[ly,lc,sn,s,c] = 1;
	
# mass balance for mixer at stream outlet, hot part
subject to HS_S_OutletMix_MassBalance {(ly,lc,sn) in HS_thisZone, s in HS_StreamsOfSubNetwork[ly,lc,sn]}:
	sum {e in HS_Connections[ly,lc,sn,s]} HS_CN_es_mcpr[ly,lc,sn,s,e] = 1;

# Heat balance at the mixer at the outlet of each stream, hot part
subject to HS_S_OutletMixHot_HeatBalance {(ly,lc,sn) in HS_thisZone, s in HS_Hz[ly,lc,sn]}:
	HS_S_Tout_z[ly,lc,sn,s] = sum {e in HS_Connections[ly,lc,sn,s]} (HS_CN_es_mcpr[ly,lc,sn,s,e]*HS_HX_h_Tout[ly,lc,sn,e]);

# Heat balance at the mixer at the outlet of each stream, cold part
subject to HS_S_OutletMixCold_HeatBalance {(ly,lc,sn) in HS_thisZone, s in HS_Cz[ly,lc,sn]}:
	HS_S_Tout_z[ly,lc,sn,s] = sum {e in HS_Connections[ly,lc,sn,s]} (HS_CN_es_mcpr[ly,lc,sn,s,e]*HS_HX_c_Tout[ly,lc,sn,e]);
	


# Mass balance at the mixer at the inlet of each heat exchanger, hot part
subject to HS_HX_InMixHot_MassBalance{(ly,lc,sn,e) in HS_thisHX}:
	HS_HX_h_mcpr[ly,lc,sn,e] = (sum {ec in HS_Connections[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]] : ec <> e} HS_CN_hee_mcpr[ly,lc,sn,ec,e]) + HS_CN_se_mcpr[ly,lc,sn,HS_HX_HS[ly,lc,sn,e],e];

# Mass balance at the mixer at the inlet of each heat exchanger, cold part
subject to HS_HX_InMixCold_MassBalance {(ly,lc,sn,e) in HS_thisHX}:
	HS_HX_c_mcpr[ly,lc,sn,e] = (sum {ec in HS_Connections[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]] : ec <> e} HS_CN_cee_mcpr[ly,lc,sn,ec,e]) + HS_CN_se_mcpr[ly,lc,sn,HS_HX_CS[ly,lc,sn,e],e];
	


# Heat balance at the mixer at the inlet of each heat exchanger, hot part
subject to HS_HX_InMixHot_HeatBalance {(ly,lc,sn,e) in HS_thisHX}:
	HS_HX_h_Tin[ly,lc,sn,e]*HS_HX_h_mcpr[ly,lc,sn,e] =
		 (sum {ec in HS_Connections[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]]: ec <> e} (HS_CN_hee_mcpr[ly,lc,sn,ec,e]*HS_HX_h_Tout[ly,lc,sn,ec])) 
		+ HS_CN_se_mcpr[ly,lc,sn,HS_HX_HS[ly,lc,sn,e],e]*HS_S_Tin_z[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]];
	
# Heat balance at the mixer at the inlet of each heat exchanger, cold part
subject to HS_HX_InMixCold_HeatBalance {(ly,lc,sn,e) in HS_thisHX}:
	HS_HX_c_Tin[ly,lc,sn,e]*HS_HX_c_mcpr[ly,lc,sn,e] = 
		 (sum {ec in HS_Connections[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]]:ec <> e} (HS_CN_cee_mcpr[ly,lc,sn,ec,e]*HS_HX_c_Tout[ly,lc,sn,ec]))
		+HS_CN_se_mcpr[ly,lc,sn,HS_HX_CS[ly,lc,sn,e],e]*HS_S_Tin_z[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]];


	
# Mass balance at the outlet splitter of each heat exchanger, hot part
subject to HS_HX_OutSplitHot_MassBalance{(ly,lc,sn,e) in HS_thisHX}:
	HS_HX_h_mcpr[ly,lc,sn,e] = 
		(sum {ec in HS_Connections[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]] : ec <> e} HS_CN_hee_mcpr[ly,lc,sn,e,ec])
		+ HS_CN_es_mcpr[ly,lc,sn,HS_HX_HS[ly,lc,sn,e],e];

# Mass balance at the outlet splitter of each heat exchanger, cold part
subject to HS_HX_OutSplitCold_MassBalance {(ly,lc,sn,e) in HS_thisHX}:
	HS_HX_c_mcpr[ly,lc,sn,e] = 
		(sum {ec in HS_Connections[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]] : ec <> e} HS_CN_cee_mcpr[ly,lc,sn,e,ec])
		+ HS_CN_es_mcpr[ly,lc,sn,HS_HX_CS[ly,lc,sn,e],e];



# Heat balance of each heat exchanger, hot part
subject to HS_HX_h_HeatBalance {(ly,lc,sn,e) in HS_thisHX} :
	HS_S_mcp_f[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]] * HS_S_mcp[ly,HS_HX_HS[ly,lc,sn,e]] * HS_HX_h_mcpr[ly,lc,sn,e] * HS_HX_h_DT[ly,lc,sn,e] = HS_HX_Q[ly,lc,sn,e] * HS_HX_Qf[ly,lc,sn,e];

# Heat balance of each heat exchanger, cold part
subject to HS_HX_c_HeatBalance {(ly,lc,sn,e) in HS_thisHX} :
	HS_S_mcp_f[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]] * HS_S_mcp[ly,HS_HX_CS[ly,lc,sn,e]] * HS_HX_c_mcpr[ly,lc,sn,e] * HS_HX_c_DT[ly,lc,sn,e] = HS_HX_Q[ly,lc,sn,e] * HS_HX_Qf[ly,lc,sn,e];



# DTmin of each heat exchanger
subject to HS_HX_h_eqdtmin {(ly,lc,sn,e) in HS_thisHX} :
	HS_HX_h_DTmin[ly,lc,sn,e] = HS_HX_h_Tin[ly,lc,sn,e] - HS_HX_c_Tout[ly,lc,sn,e] ;

subject to HS_HX_c_eqdtmin {(ly,lc,sn,e) in HS_thisHX} :
	HS_HX_c_DTmin[ly,lc,sn,e] = HS_HX_h_Tout[ly,lc,sn,e] - HS_HX_c_Tin[ly,lc,sn,e] ;


# DT positive
subject to HS_HX_h_eqdt {(ly,lc,sn,e) in HS_thisHX} :
	HS_HX_h_DT[ly,lc,sn,e] >= 0; 

subject to HS_HX_c_eqdt {(ly,lc,sn,e) in HS_thisHX} :
	HS_HX_c_DT[ly,lc,sn,e] >= 0; 
	

# Heat transfer between exchangers, hot parts, temperature considerations
#subject to HS_hee_Tcomp{(ly,lc,sn,e) in HS_thisHX, ec in HS_Connections[ly,lc,sn,HS_HX_HS[ly,lc,sn,e]] : ec <> e  } : 
#	if (HS_HX_h_Tout[ly,lc,sn,e] < HS_HX_h_Tin[ly,lc,sn,ec]) then
#		 (HS_CN_hee_mcpr[ly,lc,sn,e,ec] )
#		 else
#		 (0)
#		 = 0;

# Heat transfer between exchangers, cold parts, temperature considerations
#subject to HS_cee_Tcomp{(ly,lc,sn,e) in HS_thisHX, ec in HS_Connections[ly,lc,sn,HS_HX_CS[ly,lc,sn,e]] : ec <> e} : 
#	if (  HS_HX_c_Tout[ly,lc,sn,e] > HS_HX_c_Tin[ly,lc,sn,ec]) then 
#	(HS_CN_cee_mcpr[ly,lc,sn,e,ec] )
#	else
#	(0)
#	= 0;

# If the temperature difference of the stream is less than a given value, we only allow parallel exchage
subject to HS_S_h_parallel{(ly,lc,sn) in HS_thisZone, s in HS_Hz[ly,lc,sn], e1 in HS_Connections[ly,lc,sn,s], e2 in HS_Connections[ly,lc,sn,s] : e1 <> e2 and HS_S_Tin_z[ly,lc,sn,s] - HS_S_Tout_z[ly,lc,sn,s] < HS_S_serieTol} :
	HS_CN_hee_mcpr[ly,lc,sn,e1,e2] = 0;

subject to HS_S_c_parallel{(ly,lc,sn) in HS_thisZone, s in HS_Cz[ly,lc,sn], e1 in HS_Connections[ly,lc,sn,s], e2 in HS_Connections[ly,lc,sn,s] : e1 <> e2 and HS_S_Tout_z[ly,lc,sn,s] - HS_S_Tin_z[ly,lc,sn,s] < HS_S_serieTol} :
	HS_CN_cee_mcpr[ly,lc,sn,e1,e2] = 0;



# Objective function
# ----------------------------------------------
#minimize HS_ObjectiveFunction : 
#	   sum {ly in HS_HeatCascades} HS_HX_Cost_ly[ly]
#	+  sum {ly in HS_HeatCascades} HS_P_Cost_ly[ly];
	
minimize HS_ObjectiveFunction : 
	   sum {ly in HS_HeatCascades} HS_HX_Cost_ly[ly];
