# $Id: heat_cascade_no_restrictions.mod 2228 2010-08-18 15:28:19Z bolliger $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Heat Cascade Layer - cascade without restrictions
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

#param Min_T{ly in HeatCascades,lc in LocationsOfLayer[ly]} := min{s1 in HC_Cold_loc[ly,lc]} Streams_Tin[ly,s1]; 
#param Max_T{ly in HeatCascades,lc in LocationsOfLayer[ly]} := max {s2 in HC_Hot_loc[ly,lc]} Streams_Tin[ly,s2]; 

param Min_T{ly in HeatCascades,lc in LocationsOfLayer[ly]} := min{k in HC_TempIntervals[ly,lc]} HC_TI_tl[ly,lc,k]; 
param Max_T{ly in HeatCascades,lc in LocationsOfLayer[ly]} := max {k in HC_TempIntervals[ly,lc]} HC_TI_tl[ly,lc,k]; 


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


