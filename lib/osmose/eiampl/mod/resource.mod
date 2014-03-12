# $Id: Resource.mod 2277 2010-10-06 07:10:10Z sfazlolla $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Resource Balance Layer
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

####??? questions: is there any link between one location and another one?
####??

# Filtering Layers and selecting only layers of type "ResourceBalance"
set ResourceBalancesSimple := if (exists{t in LayerTypes} t = 'ResourceBalance') then ({l in LayersOfType["ResourceBalance"]}) else ({});
set ResourceBalancesWithQuality := if (exists{t in LayerTypes} t = 'ResourceBalanceWithQuality') then ({l in LayersOfType["ResourceBalanceWithQuality"]}) else ({});
set ResourceBalances := { ResourceBalancesSimple union ResourceBalancesWithQuality};

# Definition of units per layer and location (inter is the intersaction , in both A and B)
# RB_Units carcterise a simple operation (expansion or compression) 
set RB_Units{ l in ResourceBalances} := UnitsOfLayer[l];

# Defining liks between units
set RB_links:= { l in ResourceBalances, i in RB_Units[l], j in RB_Units[l]};


# Each unit can have an input and an output flowrate
param Units_flowrate_in_r{ l in ResourceBalances, u in UnitsOfLayer[l]} >=0 default 0;
param Units_flowrate_out_r{ l in ResourceBalances, u in UnitsOfLayer[l]} >=0 default 0;


# Real flowrate is given by Unit multiplication factor
# Real flowrate suplied to collector by the unit 
var Units_supply_r{ l in ResourceBalances, u in UnitsOfLayer[l]}; 
subject to units_supply_rc{l in ResourceBalances, u in UnitsOfLayer[l]}:
	Units_supply_r[l,u] = Units_flowrate_out_r[l,u]*Units_Mult[u]; 

# Real flowrate demanded from collector by the unit 
var Units_demand_r {l in ResourceBalances, u in UnitsOfLayer[l]}; 
subject to units_demand_rc {l in ResourceBalances, u in UnitsOfLayer[l]}:
	Units_demand_r [l,u] = Units_flowrate_in_r[l,u]*Units_Mult[u]; 

# Ensures that all products produced are really consumed
subject to RB_no_losses_r{l in ResourceBalances}:
	sum {i in RB_Units[l]} Units_supply_r[l,i] = sum {j in RB_Units[l] } Units_demand_r[l,j];

# Units material ship
var RB_ship {(l,i,j) in RB_links: i<>j} >= 0;

# Unit balance
#or subject to RB_balance{l in ResourceBalances,u in RB_Units[l]}: #
subject to RB_balance_Resource {l in ResourceBalances, u in UnitsOfLayer[l]}:
	Units_supply_r[l,u]+sum{(l,i,u)in RB_links: i <> u} RB_ship[l,i,u]=Units_demand_r[l,u]+sum{(l,u,j)in RB_links: u<>j} RB_ship[l,u,j];



# If a unit (node) doesn't produce, it won't ship anything. So, a node cannot become a transfert node
subject to RB_no_transfer_node{ l in ResourceBalances, u in RB_Units[l]}:
   sum {i in RB_Units[l]:i <> u} RB_ship[l,u,i] <= Units_supply_r[l,u];



