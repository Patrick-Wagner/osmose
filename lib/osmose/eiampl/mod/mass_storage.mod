# $Id: mass_p.mod 2277 2010-10-06 07:10:10Z sfazlolla $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Mass Balance Layer
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


 # Filtering Layers and selecting only layers of type "MassBalanceWithStorage"
set MassBalancesStorageSimple := if (exists{t in LayerTypes} t = 'MassBalanceWithStorage') then ({l in LayersOfType["MassBalanceWithStorage"]}) else ({});
set MassBalancesWithSQuality := if (exists{t in LayerTypes} t = 'MassBalanceWithQuality') then ({l in LayersOfType["MassBalanceWithQuality"]}) else ({});
set MassBalancesStorage := { MassBalancesStorageSimple union MassBalancesWithSQuality};
	
# Definition of units per layer and location (inter is the intersaction , in both A and B)
# SB_Units carcterise a simple operation (expansion or compression) for storage this corresponds to the heat exchanger between tanks
set SB_Units{ l in MassBalancesStorage, loc in LocationsOfLayer[l]} := UnitsOfLayer[l] inter UnitsOfLocation[loc];

# Set for units belonging to StorageUnits that consider heat losses
set StorageUnits_HeatLosses;
set LocationOfStorageUnits_HeatLosses{StorageUnits_HeatLosses} within Locations;

set Units_HeatLosses default{};

set StorageUnitsOfUnits_HeatLosses{u in Units_HeatLosses} default{};

set Units_HeatLossesOfLayer{l in MassBalancesStorage} default{};

# Each unit can have an input and an output flowrate
 param Units_flowrate_in_s{ l in MassBalancesStorage, u in UnitsOfLayer[l], t in Time} >=0 default 0;
 param Units_flowrate_out_s{ l in MassBalancesStorage, u in UnitsOfLayer[l], t in Time} >=0 default 0;

	
# Real flowrate is given by Unit multiplication factor
# Real flowrate suplied to collector by the unit 
var Units_supply_s{ l in MassBalancesStorage, u in UnitsOfLayer[l],t in Time}; 

# operating time in hours , unit_flowrate in kg/s
subject to Units_supply_sc{l in MassBalancesStorage, u in UnitsOfLayer[l],t in Time: u in UnitsOfTime[t]}:
	Units_supply_s[l,u,t] = 3600 * op_time[t] * Units_flowrate_out_s[l,u,t]*Units_Mult_t[u,t]; 

# Real flowrate demanded from collector by the unit 
var Units_demand_s {l in MassBalancesStorage, u in UnitsOfLayer[l],t in Time}; 
subject to Units_demand_sc {l in MassBalancesStorage, u in UnitsOfLayer[l],t in Time}:
	Units_demand_s [l,u,t] = 3600 * op_time[t] * Units_flowrate_in_s[l,u,t]*Units_Mult_t[u,t]; 

	
# Ensures that all products produced are really consumed - CYCLIC CONSTRAINT
subject to SB_no_losses{l in MassBalancesStorage, loc in LocationsOfLayer[l]}:
	 sum{t in Time} ( sum {i in SB_Units[l,loc]:i in UnitsOfTime[t]} Units_supply_s[l,i,t]) = sum{t in Time} ( sum {j in SB_Units[l,loc]: j in UnitsOfTime[t]} Units_demand_s[l,j,t]);
	
var M0{l in MassBalancesStorage, loc in LocationsOfLayer[l],sto in StorageUnits_HeatLosses} >= 0;
var M_t{l in MassBalancesStorage, loc in LocationsOfLayer[l], sto in StorageUnits_HeatLosses, t in Time} >= 0;

param Mmax{sto in StorageUnits_HeatLosses};
param sto_rho{sto in StorageUnits_HeatLosses};

subject to SB_current{l in MassBalancesStorage, loc in LocationsOfLayer[l], sto in StorageUnits_HeatLosses, t in Time:loc in LocationOfStorageUnits_HeatLosses[sto]}:
M_t[l,loc,sto,t] = M0[l,loc,sto] + sum{p in 1..t} (sum {i in SB_Units[l,loc]:i in UnitsOfTime[p]} Units_supply_s[l,i,p]) -
   sum{p in 1..t} (sum {j in SB_Units[l,loc]: j in UnitsOfTime[p]} Units_demand_s[l,j,p]);

# tank can not become a transfer unit without storage   
subject to SB_current2{l in MassBalancesStorage, loc in LocationsOfLayer[l], sto in StorageUnits_HeatLosses, t in Time diff{1}:loc in LocationOfStorageUnits_HeatLosses[sto]}:
M0[l,loc,sto] + sum{p in 1..t} (sum {i in SB_Units[l,loc]:i in UnitsOfTime[p]} Units_supply_s[l,i,p]) -
sum{p in 1..t-1} (sum {j in SB_Units[l,loc]: j in UnitsOfTime[p]} Units_demand_s[l,j,p]) -
   M_t[l,loc,sto,t] >=0;   
   
subject to SB_current3{l in MassBalancesStorage, loc in LocationsOfLayer[l], sto in StorageUnits_HeatLosses:loc in LocationOfStorageUnits_HeatLosses[sto]}:
M0[l,loc,sto] + sum {i in SB_Units[l,loc]:i in UnitsOfTime[1]} Units_supply_s[l,i,1] -  M_t[l,loc,sto,1] >=0;   
   
subject to M0_max{sto in StorageUnits_HeatLosses}:
  sum{l in MassBalancesStorage, loc in LocationsOfLayer[l]:loc in LocationOfStorageUnits_HeatLosses[sto]} M0[l,loc,sto] <= Mmax[sto]; 
    
# fix multiplications factor for maintaining temperature in tanks (thermal losses) 
subject to Units_Mult_fix{l in MassBalancesStorage, loc in LocationsOfLayer[l],u in Units_HeatLossesOfLayer[l],sto in StorageUnitsOfUnits_HeatLosses[u],t in Time:loc in LocationOfStorageUnits_HeatLosses[sto]}:   
Units_Mult_t[u,t] = ((1.1*4*M_t[l,loc,sto,t]/(3*sto_rho[sto])))/1000;

