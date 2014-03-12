# storage_postsolve.mod 2026 2010-11-10 14:56:33Z Author:S.Fazlollahi 
# $Id: storage_postsolve.mod 2026 2010-11-10 14:56:33Z Fazlollahi $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# General data - post-solve calculations
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


#Param Qcurrent{ly in HeatCascades,lc in LocationsOfLayer[ly],i in sto_loc[ly,lc],t in Time:sh in sto_hot_loc_ord[ly,lc] and sc in sto_cold_loc_ord[ly,lc] and sh in sto_hot_loc[ly,lc,i] and sc in sto_cold_loc[ly,lc,i] }:=Qzero[ly,lc,i] + op_time[t]*(sum{p in 1..t}( Streams_Q[ly,sc,p]-Streams_Q[ly,sh,p]));
display Units_supply_s;
display Units_demand_s;
display M0;
display M_t;



