# heat_cascade_no_restrictions_p.mod 2328 2010-11-11 15:28:19Z Author: S.Fazlollahi
# $Id: heat_cascade_no_restrictions_p.mod 2328 2010-11-11 15:28:19Z fazlollahi $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Heat Cascade Layer - cascade without restrictions
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

### Variables 
## ---------------------------------------------------------------------------------------------------------------------------------------------------

var HC_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time,k in HC_TempIntervals[ly,lc,t]}>=0;

# Heat cascade
#-------------------------------------------------------------------------
#CONSTRAINS


subject to HC_heat_cascade{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, k in HC_TempIntervals[ly,lc,t]}:
sum{st in HC_Hot_loc[ly,lc,t]:Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon} 
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tin[ly,st,t]-Streams_Tout[ly,st,t])) -
sum{st in HC_Cold_loc[ly,lc,t]:Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon} 
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-Streams_Tin[ly,st,t])) +
sum{st in HC_Hot_loc[ly,lc,t]:Streams_Tout[ly,st,t]<=HC_TI_tl[ly,lc,t,k] and Streams_Tin[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tin[ly,st,t]-HC_TI_tl[ly,lc,t,k])) -
sum{st in HC_Cold_loc[ly,lc,t]:Streams_Tin[ly,st,t]<=HC_TI_tl[ly,lc,t,k] and Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
    (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t]-HC_TI_tl[ly,lc,t,k]))
-HC_Rk[ly,lc,t,k]=0;


param Min_T{ly in HeatCascades,lc in LocationsOfLayer[ly],t in Time} := min{k in HC_TempIntervals[ly,lc,t]} HC_TI_tl[ly,lc,t,k]; 
param Max_T{ly in HeatCascades,lc in LocationsOfLayer[ly],t in Time} := max {k in HC_TempIntervals[ly,lc,t]} HC_TI_tl[ly,lc,t,k]; 


subject to HC_lowerbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Min_T[ly,lc,t]}:
     HC_Rk[ly,lc,t,k] = 0;

subject to HC_upperbound_Rk{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Max_T[ly,lc,t]}:
     HC_Rk[ly,lc,t,k] = 0;

# No heat from hot streams below minimum input temperature
subject to HC_lowerbound_Balance{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Min_T[ly,lc,t]}:
	sum{st in HC_Hot_loc[ly,lc,t]:Streams_Tout[ly,st,t]<=HC_TI_tl[ly,lc,t,k]-epsilon}
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(HC_TI_tl[ly,lc,t,k] - Streams_Tout[ly,st,t])) = 0;

# No heat from cold streams above maximum input temperature
subject to HC_upperbound_Balance{ly in HeatCascades, lc in LocationsOfLayer[ly],t in Time, k in HC_TempIntervals[ly,lc,t]: HC_TI_tl[ly,lc,t,k]=Max_T[ly,lc,t]}:
	sum{st in HC_Cold_loc[ly,lc,t]:Streams_Tout[ly,st,t]>=HC_TI_tl[ly,lc,t,k]+epsilon}
     (Streams_Mcp[ly,st,t]*HC_Streams_Mult[ly,st,t]*(Streams_Tout[ly,st,t] - HC_TI_tl[ly,lc,t,k])) = 0;

#### storage conection


