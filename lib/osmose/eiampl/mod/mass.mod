# $Id: mass.mod 2599 2011-09-28 14:55:43Z hbecker $
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
set MB_links:= { l in MassBalances, loc in LocationsOfLayer[l], i in MB_Units[l,loc], j in MB_Units[l,loc]};


# Each unit can have an input and an output flowrate
param Units_flowrate_in{ l in MassBalances, u in UnitsOfLayer[l]} >=0 default 0;
param Units_flowrate_out{ l in MassBalances, u in UnitsOfLayer[l]} >=0 default 0;

# Real flowrate is given by Unit multiplication factor
# Real flowrate suplied to collector by the unit 
var Units_supply{ l in MassBalances, u in UnitsOfLayer[l]}; 
subject to units_supplyc{l in MassBalances, u in UnitsOfLayer[l]}:
	Units_supply[l,u] = Units_flowrate_out[l,u]*Units_Mult[u]; 

# Real flowrate demanded from collector by the unit 
var Units_demand {l in MassBalances, u in UnitsOfLayer[l]}; 
subject to units_demandc {l in MassBalances, u in UnitsOfLayer[l]}:
	Units_demand [l,u] = Units_flowrate_in[l,u]*Units_Mult[u]; 

# Ensures that all products produced are really consumed
subject to MB_no_losses{l in MassBalances, loc in LocationsOfLayer[l]}:
	sum {i in MB_Units[l,loc]} Units_supply[l,i] = sum {j in MB_Units[l,loc] } Units_demand[l,j];

# Units material ship
var MB_ship {(l,loc,i,j) in MB_links: i<>j} >= 0;

# Unit balance
#or subject to MB_balance{l in MassBalances,loc in LocationsOfLayer[l],u in MB_Units[l,loc]}: #
subject to MB_balance_mass {l in MassBalances, u in UnitsOfLayer[l],loc in LocationsOfLayer[l]:u in UnitsOfLocation[loc]}:
	Units_supply[l,u]+sum{(l,loc,i,u)in MB_links: i <> u} MB_ship[l,loc,i,u]=Units_demand[l,u]+sum{(l,loc,u,j)in MB_links: u<>j} MB_ship[l,loc,u,j];



# If a unit (node) doesn't produce, it won't ship anything. So, a node cannot become a transfert node
subject to MB_no_transfer_node{ l in MassBalances, loc in LocationsOfLayer[l], u in MB_Units[l,loc]}:
   sum {i in MB_Units[l,loc]:i <> u} MB_ship[l,loc,u,i] <= Units_supply[l,u];



