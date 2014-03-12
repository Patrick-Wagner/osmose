# $Id: costing.mod 2304 2010-11-04 09:41:31Z hbecker $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Costing Layer
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Filtering Layers and selecting only layers of type "Costing"
set Costs :=  {l in LayersOfType["Costing"]} within Layers; 

# Linear cost factors
param Streams_Cost1{l in Costs, s in StreamsOfLayer[l]};
param Streams_Cost2{l in Costs, s in StreamsOfLayer[l]};

# Computing cost for each stream
var Streams_Cost{l in Costs, s in StreamsOfLayer[l], u in UnitsOfStream[s]} ; 
subject to streams_cost{l in Costs, s in StreamsOfLayer[l], u in UnitsOfStream[s]}:
	Streams_Cost[l,s,u] =  Units_Use[u]*Streams_Cost1[l,s]+Units_Mult[u]*Streams_Cost2[l,s] ; 

# Computing cost for each unit, summing by stream
var Units_Cost{l in Costs, u in UnitsOfLayer[l]};
subject to unit_cost{l in Costs, u in UnitsOfLayer[l]} :
	Units_Cost[l,u] = sum {s in StreamsOfUnit[u]: s in StreamsOfLayer[l]} Streams_Cost[l,s,u];

# Computing cost for each location
var Locations_Cost{l in Costs, loc in LocationsOfLayer[l]};
subject to locations_cost{l in Costs, loc in LocationsOfLayer[l]}:
	Locations_Cost[l,loc] =  sum { u in UnitsOfLocation[loc], s in StreamsOfUnit[u]: s in StreamsOfLayer[l]} Streams_Cost[l,s,u];


# Computing overall cost of layer
var Costs_Cost{l in Costs} ;
subject to costs_cost{l in Costs}:
	Costs_Cost[l] = sum {u in UnitsOfLayer[l]} Units_Cost[l,u];
	
# Computing Operating cost including electricity costs 	
# when defining obj YearlyOperatingCost (including electricity cost): power is linked to electricty cost (imported or exported) 
param cost_elec_in; 
param cost_elec_out; 
param op_time;
var Elec_buy >= 0; 
var Elec_sell >= 0;  
var YearlyOperatingCost ; # Euro/years 
subject to const_elec1:
	Costs_Cost["osmose_default_model_DefaultMechPower"] - Elec_buy + Elec_sell = 0 ;
subject to const_elec2:
	Costs_Cost["osmose_default_model_DefaultMechPower"] - Elec_buy  <= 0;
subject to new_opcost:
	YearlyOperatingCost = (cost_elec_in * Elec_buy * op_time * 3600 / 1000000)  - ( cost_elec_out * Elec_sell * op_time * 3600 / 1000000) + 
	( op_time * 3600 * Costs_Cost["osmose_default_model_DefaultOpCost"]) ;

# Generated Streams
#-------------------------------------------------------------------------
set Cost_generatedGroups := if (exists{t in UnitBehaviors} t = 'Cost_generated') then ({g in UnitGroupsOfType['Cost_generated']}) else ({});
set Cost_generatedUnits{ly in Costs, g in Cost_generatedGroups} := {s in UnitsOfUnitGroup[g]};

#?????var Cost_generatedGroups_power{ly in Costs, g in Cost_generatedGroups, gm in UnitGroupsMasters[g]} = sum{u in Cost_generatedUnits[ly,g] : u in UnitsOfLayer[ly]} Units_Cost[ly,u], :=0;

var Cost_generatedGroups_power{ly in Costs, g in Cost_generatedGroups, gm in UnitGroupsMasters[g]};
subject to cost_generatedGroups_power{ly in Costs, g in Cost_generatedGroups, gm in UnitGroupsMasters[g]}:
	Cost_generatedGroups_power[ly,g,gm] = sum{u in Cost_generatedUnits[ly,g] : u in UnitsOfLayer[ly]} Units_Cost[ly,u] ;

