# $Id: Resource_p.mod 2277 2010-10-06 07:10:10Z sfazlolla $
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
set RB_links:= { l in ResourceBalances, i in RB_Units[l], j in RB_Units[l],t in Time: i in UnitsOfTime[t] and j in UnitsOfTime[t] };

# Each unit can have an input and an output flowrate
param Units_flowrate_in_r{ l in ResourceBalances, u in UnitsOfLayer[l], t in Time} >=0 default 0;
param Units_flowrate_out_r{ l in ResourceBalances, u in UnitsOfLayer[l], t in Time} >=0 default 0;

# Real flowrate is given by Unit multiplication factor
# Real flowrate suplied to collector by the unit 
var Units_supply_r{ l in ResourceBalances, u in UnitsOfLayer[l],t in Time}; 
subject to Units_supply_rc{l in ResourceBalances, u in UnitsOfLayer[l],t in Time: u in UnitsOfTime[t]}:
	Units_supply_r[l,u,t] = Units_flowrate_out_r[l,u,t]*Units_Mult_t[u,t]; 

# Real flowrate demanded from collector by the unit 
var Units_demand_r {l in ResourceBalances, u in UnitsOfLayer[l],t in Time}; 
subject to Units_demand_rc {l in ResourceBalances, u in UnitsOfLayer[l],t in Time}:
	Units_demand_r [l,u,t] = Units_flowrate_in_r[l,u,t]*Units_Mult_t[u,t]; 

# Ensures that all products produced are really consumed
subject to RB_no_losses{l in ResourceBalances, loc in LocationsOfLayer[l],t in Time}:
	sum {i in RB_Units[l]:i in UnitsOfTime[t]} Units_supply_r[l,i,t] = sum {j in RB_Units[l]: j in UnitsOfTime[t]} Units_demand_r[l,j,t];


# Units material ship---------------------------------
var RB_ship {(l,i,j,t) in RB_links: i<>j} >= 0;




# Unit balance
#or subject to RB_balance{l in ResourceBalances,loc in LocationsOfLayer[l],u in RB_Units[l]}: #
subject to RB_balance_Resource {l in ResourceBalances, u in UnitsOfLayer[l],t in Time: u in UnitsOfTime[t] }:
	Units_supply_r[l,u,t]+sum{(l,i,u,p)in RB_links: i <> u and p=t} RB_ship[l,i,u,t]=Units_demand_r[l,u,t]+sum{(l,u,j,p)in RB_links: u<>j and p=t} RB_ship[l,u,j,t];


# If a unit (node) doesn't produce, it won't ship anything. So, a node cannot become a transfer node
subject to RB_no_transfer_node{ l in ResourceBalances, u in RB_Units[l], t in Time: u in UnitsOfTime[t]}:
   sum {i in RB_Units[l]:i in UnitsOfTime[t] and i <> u} RB_ship[l,u,i,t] <= Units_supply_r[l,u,t];


## connection and transfering cost-------
#
#var RB_shipUse_t{(i,j,t) in RB_links: i<>j} binary ;
#var RB_shipUse{(i,j) in RB_links: i<>j} binary ;
#
## Unit sizing constraints
#subject to RB_use_t_cst_Fmax{l in ResourceBalances, u in RB_Units[l],i in RB_Units[l],t in Time: u in UnitsOfTime[t] and i in UnitsOfTime[t] and i <> u}:
#    RB_ship[l,u,i,t] <= Units_flowrate_out_r[l,u,t]*RB_shipUse_t[u,i,t]*Units_Fmax[u,t];
#
#
#subject to RB_use_t_cst_Fmin{l in ResourceBalances, u in RB_Units[l],i in RB_Units[l],t in Time: u in UnitsOfTime[t] and i in UnitsOfTime[t] and i <> u}:
#   RB_ship[l,u,i,t] >= Units_flowrate_out_r[l,u,t]*RB_shipUse_t[u,i,t]*Units_Fmin[u,t];
#
#
#subject to RB_use_cst{l in ResourceBalances, u in RB_Units[l],i in RB_Units[l],t in Time: u in UnitsOfTime[t] and i in UnitsOfTime[t] and i <> u}:
#RB_shipUse[u,i] >= RB_shipUse_t[u,i,t];




