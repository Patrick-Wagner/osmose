# $Id: heat_cascade_no_restrictions.mod 1986 2010-03-08 16:58:36Z bolliger $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Heat Cascade Layer - cascade with restricted matches
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

### Variables 
## ---------------------------------------------------------------------------------------------------------------------------------------------------

var HC_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly],k in HC_TempIntervals[ly,lc]}>=0;

# Heat cascade
#-------------------------------------------------------------------------
#CONSTRAINS


subject to HC_heat_cascade{ly in HeatCascades, lc in LocationsOfLayer[ly], k in HC_TempIntervals[ly,lc]}:
sum{st in HC_Hot_loc[ly,lc]:Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon} 
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tin[ly,st]-Streams_Tout[ly,st])) -
sum{st in HC_Cold_loc[ly,lc]:Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon} 
    (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-Streams_Tin[ly,st])) +
sum{st in HC_Hot_loc[ly,lc]:Streams_Tout[ly,st]<=HC_TI_tl[ly,lc,k] and Streams_Tin[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon}
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tin[ly,st]-HC_TI_tl[ly,lc,k])) -
sum{st in HC_Cold_loc[ly,lc]:Streams_Tin[ly,st]<=HC_TI_tl[ly,lc,k] and Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon}
    (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st]-HC_TI_tl[ly,lc,k]))
-HC_Rk[ly,lc,k]=0;

param Min_T{ly in HeatCascades,lc in LocationsOfLayer[ly]} := min{s1 in HC_Cold_loc[ly,lc]} Streams_Tin[ly,s1]; 
param Max_T{ly in HeatCascades,lc in LocationsOfLayer[ly]} := max {s2 in HC_Hot_loc[ly,lc]} Streams_Tin[ly,s2]; 


subject to HC_lowerbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Min_T[ly,lc]}:
     HC_Rk[ly,lc,k] = 0;

subject to HC_upperbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Max_T[ly,lc]}:
     HC_Rk[ly,lc,k] = 0;

# No heat from hot streams below minimum input temperature
subject to HC_lowerbound_Balance{ly in HeatCascades, lc in LocationsOfLayer[ly], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Min_T[ly,lc]}:
	sum{st in HC_Hot_loc[ly,lc]:Streams_Tout[ly,st]<=HC_TI_tl[ly,lc,k]-epsilon}
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(HC_TI_tl[ly,lc,k] - Streams_Tout[ly,st])) = 0;

# No heat from cold streams above maximum input temperature
subject to HC_upperbound_Balance{ly in HeatCascades, lc in LocationsOfLayer[ly], k in HC_TempIntervals[ly,lc]: HC_TI_tl[ly,lc,k]=Max_T[ly,lc]}:
	sum{st in HC_Cold_loc[ly,lc]:Streams_Tout[ly,st]>=HC_TI_tl[ly,lc,k]+epsilon}
     (Streams_Mcp[ly,st]*HC_Streams_Mult[ly,st]*(Streams_Tout[ly,st] - HC_TI_tl[ly,lc,k])) = 0;




### Variables 
## ---------------------------------------------------------------------------------------------------------------------------------------------------

# Heat transferred from hot stream i to cold stream j
var HCR_Qij{ly in HeatCascades, lc in LocationsOfLayer[ly], i in HC_Hot_loc[ly,lc], j in HC_Cold_loc[ly,lc]};# >=0;


# Existence of match between hot stream i and cold stream j
var HCR_yij{ly in HeatCascades, lc in LocationsOfLayer[ly], i in HC_Hot_loc[ly,lc], j in HC_Cold_loc[ly,lc]} binary;


# Constraints
# ---------------------------------------------------------------------------------------------------------------------------------------------------
# Cascade balances
# ------------------------

# heat exchange for each hot stream
subject to HCR_Qij_foreach_Hot_1{ly in HeatCascades, lc in LocationsOfLayer[ly],i in HC_Hot_loc[ly,lc], j in HC_Cold_loc[ly,lc],un in UnitsOfStream[j]:Streams_Tout[ly,j]<=Streams_Tin[ly,i]} :
	HCR_Qij[ly,lc,i,j] <= (Streams_Mcp[ly,j]*Units_Mult[un]*(Streams_Tout[ly,j]-Streams_Tin[ly,j])) ;

subject to HCR_Qij_foreach_Hot_2{ly in HeatCascades, lc in LocationsOfLayer[ly],i in HC_Hot_loc[ly,lc], j in HC_Cold_loc[ly,lc]:Streams_Tin[ly,j]>=Streams_Tin[ly,i]} :
	HCR_Qij[ly,lc,i,j] =0 ;



subject to HCR_hot_sum_Qij{ly in HeatCascades, lc in LocationsOfLayer[ly],i in HC_Hot_loc[ly,lc],un in UnitsOfStream[i]} :
	Streams_Mcp[ly,i]*Units_Mult[un]*(Streams_Tin[ly,i]-Streams_Tout[ly,i]) =sum {j in HC_Cold_loc[ly,lc]} HCR_Qij[ly,lc,i,j];

subject to HCR_cold_sum_Qij{ly in HeatCascades, lc in LocationsOfLayer[ly],j in HC_Cold_loc[ly,lc],un in UnitsOfStream[j]} :
	Streams_Mcp[ly,j]*Units_Mult[un]*(Streams_Tout[ly,j]-Streams_Tin[ly,j]) =sum {i in HC_Hot_loc[ly,lc]} HCR_Qij[ly,lc,i,j];



### Stream matches 
# ------------------------

# Forbidden matches
subject to HCR_Forbidden_Matches_cstr{ly in HeatCascades, lc in LocationsOfLayer[ly], (i,j) in HCR_Forbidden_Matches[ly,lc]} : 
	HCR_yij[ly,lc,i,j] = 0;

# Unrestricted matches
subject to HCR_Unrestricted_Matches_cstr{ly in HeatCascades, lc in LocationsOfLayer[ly], (i,j) in HCR_Unrestricted_Matches[ly,lc]} : 
	HCR_yij[ly,lc,i,j] = 1;
	
# Matches minimum load
subject to HCR_Matches_min_load{ly in HeatCascades, lc in LocationsOfLayer[ly], (i,j) in HCR_Matches[ly,lc]} : 
	HCR_Qij[ly,lc,i,j] >= HCR_Qij_min[ly,lc,i,j]*HCR_yij[ly,lc,i,j];
	
# Matches maximum load
subject to HCR_Matches_max_load{ly in HeatCascades, lc in LocationsOfLayer[ly], (i,j) in HCR_Matches[ly,lc]} : 
	HCR_Qij[ly,lc,i,j] <= HCR_Qij_max[ly,lc,i,j]*HCR_yij[ly,lc,i,j];
