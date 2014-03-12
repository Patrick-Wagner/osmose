# $Id: mass_p.mod 2277 2010-10-06 07:10:10Z sfazlolla $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Mass Balance Layer
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



# Filtering Layers and selecting only layers of type "MassBalance"
set MassBalancesSimple := if (exists{t in LayerTypes} t = 'MassBalance') then ({l in LayersOfType["MassBalance"]}) else ({});
set MassBalancesWithQuality := if (exists{t in LayerTypes} t = 'MassBalanceWithQuality') then ({l in LayersOfType["MassBalanceWithQuality"]}) else ({});
set MassBalances := { MassBalancesSimple union MassBalancesWithQuality};

# Definition of units per layer and location (inter is the intersaction , in both A and B)
# MB_Units carcterise a simple operation (expansion or compression) 
set MB_Units{ l in MassBalances, loc in LocationsOfLayer[l]} := UnitsOfLayer[l] inter UnitsOfLocation[loc];


# Defining liks between units
set MB_links:= { l in MassBalances, loc in LocationsOfLayer[l], i in MB_Units[l,loc], j in MB_Units[l,loc],t in Time: i in UnitsOfTime[t] and j in UnitsOfTime[t] };

# Each unit can have an input and an output flowrate
param Units_flowrate_in{ l in MassBalances, u in UnitsOfLayer[l], t in Time} >=0 default 0;
param Units_flowrate_out{ l in MassBalances, u in UnitsOfLayer[l], t in Time} >=0 default 0;

# Real flowrate is given by Unit multiplication factor
# Real flowrate suplied to collector by the unit 
var Units_supply{ l in MassBalances, u in UnitsOfLayer[l],t in Time}; 
subject to units_supplyc{l in MassBalances, u in UnitsOfLayer[l],t in Time: u in UnitsOfTime[t]}:
	Units_supply[l,u,t] = Units_flowrate_out[l,u,t]*Units_Mult_t[u,t]; 

# Real flowrate demanded from collector by the unit 
var Units_demand {l in MassBalances, u in UnitsOfLayer[l],t in Time}; 
subject to units_demandc {l in MassBalances, u in UnitsOfLayer[l],t in Time}:
	Units_demand [l,u,t] = Units_flowrate_in[l,u,t]*Units_Mult_t[u,t]; 

# Ensures that all products produced are really consumed
subject to MB_no_losses{l in MassBalances, loc in LocationsOfLayer[l],t in Time}:
	sum {i in MB_Units[l,loc]:i in UnitsOfTime[t]} Units_supply[l,i,t] = sum {j in MB_Units[l,loc]: j in UnitsOfTime[t]} Units_demand[l,j,t];

# Units material ship
var MB_ship {(l,loc,i,j,t) in MB_links: i<>j} >= 0;



# Unit balance
#or subject to MB_balance{l in MassBalances,loc in LocationsOfLayer[l],u in MB_Units[l,loc]}: #
subject to MB_balance_mass {l in MassBalances, u in UnitsOfLayer[l],loc in LocationsOfLayer[l],t in Time:u in UnitsOfLocation[loc]and u in UnitsOfTime[t] }:
	Units_supply[l,u,t]+sum{(l,loc,i,u,p)in MB_links: i <> u and p=t} MB_ship[l,loc,i,u,t]=Units_demand[l,u,t]+sum{(l,loc,u,j,p)in MB_links: u<>j and p=t} MB_ship[l,loc,u,j,t];


# If a unit (node) doesn't produce, it won't ship anything. So, a node cannot become a transfert node
subject to MB_no_transfer_node{ l in MassBalances, loc in LocationsOfLayer[l], u in MB_Units[l,loc], t in Time: u in UnitsOfTime[t]}:
   sum {i in MB_Units[l,loc]:i in UnitsOfTime[t] and i <> u} MB_ship[l,loc,u,i,t] <= Units_supply[l,u,t];



