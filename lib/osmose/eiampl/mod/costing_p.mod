# costing_period.mod 2255 2010-10-010 12:34:01Z Author:Fazlollahi $
# $Id: costing_period.mod 2255 2010-10-010 12:34:01Z Fazlollahi $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Costing Layer
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Be careful, Streams_Cost, Units_Cost and Locations_Cost are calculated by summing the Streams_Cost_t, Units_Cost_t and 
# Locations_Cost_t ; this makes only sense when the heat loads are in energy and not in power ! 
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# Filtering Layers and selecting only layers of type "Costing"
set Costs :=  {l in LayersOfType["Costing"]} within Layers; 

# Linear cost factors
param Streams_Cost1{l in Costs, s in StreamsOfLayer[l],t in Time};
param Streams_Cost2{l in Costs, s in StreamsOfLayer[l],t in Time};

param Streams_Cost1_inv{l in Costs, s in StreamsOfLayer[l]:l='DefaultInvCost'}:= max{t in Time:s in StreamsOfTime[t]}Streams_Cost1[l,s,t];
param Streams_Cost2_inv{l in Costs, s in StreamsOfLayer[l]:l='DefaultInvCost'}:= max{t in Time:s in StreamsOfTime[t]}Streams_Cost2[l,s,t];


# Computing cost for each stream in each time: investment cost is for whole period and does not have any meaning for each time
var Streams_Cost_t{l in Costs, s in StreamsOfLayer[l], u in UnitsOfStream[s],t in Time} ; 
subject to streams_cost_t{l in Costs, s in StreamsOfLayer[l], u in UnitsOfStream[s],t in Time:s in StreamsOfTime[t] and l <>'DefaultInvCost'}:
	Streams_Cost_t[l,s,u,t] = Units_Use_t[u,t]*Streams_Cost1[l,s,t]+Units_Mult_t[u,t]*Streams_Cost2[l,s,t] ; 

# Computing cost for each stream during whole period
var Streams_Cost{l in Costs, s in StreamsOfLayer[l], u in UnitsOfStream[s]} ; 
subject to streams_cost{l in Costs, s in StreamsOfLayer[l], u in UnitsOfStream[s]:l <>'DefaultInvCost'}:
	Streams_Cost[l,s,u] = sum {t in Time:s in StreamsOfTime[t]} Streams_Cost_t[l,s,u,t] ; 


# Computing cost for each unit, summing by stream in each time
var Units_Cost_t{l in Costs, u in UnitsOfLayer[l],t in Time};
subject to unit_cost_t{l in Costs, u in UnitsOfLayer[l],t in Time:u in UnitsOfTime[t] and l <>'DefaultInvCost'} :
	Units_Cost_t[l,u,t] = sum {s in StreamsOfUnit[u]: s in StreamsOfLayer[l]} Streams_Cost_t[l,s,u,t];

# Computing cost for each unit, summing by stream during whole period
var Units_Cost{l in Costs, u in UnitsOfLayer[l]};
subject to unit_cost{l in Costs, u in UnitsOfLayer[l]:l <>'DefaultInvCost'} :
	Units_Cost[l,u] = sum {t in Time:u in UnitsOfTime[t]} Units_Cost_t[l,u,t] ;


# Computing cost for each location in each time
var Locations_Cost_t{l in Costs, loc in LocationsOfLayer[l],t in Time};
subject to locations_cost_t{l in Costs, loc in LocationsOfLayer[l],t in Time:l <>'DefaultInvCost'}:
	Locations_Cost_t[l,loc,t] =  sum { u in UnitsOfLocation[loc], s in StreamsOfUnit[u]: s in StreamsOfLayer[l] and s in StreamsOfTime[t]} Streams_Cost_t[l,s,u,t];

# Computing overall cost of layer
var Costs_Cost_t{l in Costs,t in Time} ;
subject to costs_cost_t{l in Costs,t in Time:l <>'DefaultInvCost'}:
	Costs_Cost_t[l,t] = sum {u in UnitsOfLayer[l]:u in UnitsOfTime[t]} Units_Cost_t[l,u,t];

#Investment cost:-----------------------------------------------------------------------

# Computing cost for each Inv stream
subject to streams_cost_inv{l in Costs, s in StreamsOfLayer[l], u in UnitsOfStream[s]:l='DefaultInvCost'}:
	Streams_Cost[l,s,u] =  Units_Use[u]*Streams_Cost1_inv[l,s]+Units_Mult[u]*Streams_Cost2_inv[l,s] ; 

# Computing cost for each unit, summing by stream
subject to unit_cost_inv{l in Costs, u in UnitsOfLayer[l]:l='DefaultInvCost'} :
	Units_Cost[l,u] = sum {s in StreamsOfUnit[u]: s in StreamsOfLayer[l]} Streams_Cost[l,s,u];
#-----------------------------------------------------------------------

# Computing cost for each location during whole period
var Locations_Cost{l in Costs, loc in LocationsOfLayer[l]};
subject to locations_cost{l in Costs, loc in LocationsOfLayer[l]}:
	Locations_Cost[l,loc] =  sum { u in UnitsOfLocation[loc], s in StreamsOfUnit[u]: s in StreamsOfLayer[l]} Streams_Cost[l,s,u];


# Computing overall cost of layer
var Costs_Cost{l in Costs} ;
subject to costs_cost{l in Costs}:
	Costs_Cost[l] = sum {u in UnitsOfLayer[l]} Units_Cost[l,u];


#-------------------------------------------------------------------------
# Computing Operating cost including electricity costs 	
# when defining obj YearlyOperatingCost (including electricity cost): power is linked to electricty cost (imported or exported) 
param cost_elec_in {t in Time}; 
param cost_elec_out {t in Time}; 
param op_time {t in Time};
param cycles default 1;

var Elec_buy_t {t in Time} >= 0; 
var Elec_sell_t {t in Time} >= 0;  
var YearlyOperatingCost_t {t in Time};  # Euro/years 

var Elec_buy  >= 0; 
var Elec_sell >= 0;  
var YearlyOperatingCost;  # Euro/years 


subject to const_elec1_t{l in Costs, t in Time:l='DefaultMechPower'}:
	Costs_Cost_t[l,t] - Elec_buy_t[t]+ Elec_sell_t[t] = 0 ;

subject to const_elec2_t{l in Costs, t in Time:l='DefaultMechPower'}:
	Costs_Cost_t[l,t] - Elec_buy_t[t]  <= 0;

subject to new_opcost_t{l in Costs, t in Time:l='DefaultOpCost'}:
	YearlyOperatingCost_t[t] = cycles*((cost_elec_in[t] * Elec_buy_t[t] * op_time[t] * 3600 / 1000000)  - ( cost_elec_out[t] * Elec_sell_t[t] * op_time[t] * 3600 / 1000000) + 
	( op_time[t] * 3600 * Costs_Cost_t[l,t])) ;


subject to const_elec1:
	Elec_buy =sum{t in Time} Elec_buy_t[t] ;
subject to const_elec2:
	Elec_sell =sum{t in Time} Elec_sell_t[t] ;

subject to new_opcost:
	YearlyOperatingCost =sum{t in Time}YearlyOperatingCost_t[t] ;

# Generated Streams (No modification for time)
#-------------------------------------------------------------------------
set Cost_generatedGroups := if (exists{t in UnitBehaviors} t = 'Cost_generated') then ({g in UnitGroupsOfType['Cost_generated']}) else ({});
set Cost_generatedUnits{ly in Costs, g in Cost_generatedGroups} := {s in UnitsOfUnitGroup[g]};

#?????var Cost_generatedGroups_power{ly in Costs, g in Cost_generatedGroups, gm in UnitGroupsMasters[g]} = sum{u in Cost_generatedUnits[ly,g] : u in UnitsOfLayer[ly]} Units_Cost[ly,u], :=0;

var Cost_generatedGroups_power{ly in Costs, g in Cost_generatedGroups, gm in UnitGroupsMasters[g]};
subject to cost_generatedGroups_power{ly in Costs, g in Cost_generatedGroups, gm in UnitGroupsMasters[g]}:
	Cost_generatedGroups_power[ly,g,gm] = sum{u in Cost_generatedUnits[ly,g] : u in UnitsOfLayer[ly]} Units_Cost[ly,u] ;

