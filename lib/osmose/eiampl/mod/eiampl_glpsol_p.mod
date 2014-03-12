#$Id: eiampl_glpsol_period.mod 2026 2010-11-10 14:56:33Z Fazlollahi $
/*******************************************************/
#Sets
/*******************************************************/
set LayerTypes; #Type of layer (HeatCascade, MassBalance, ...)
set Layers; #Set of layers
set Units; #Set of units
set Streams; #Set of streams
set Locations; #Set of locations
set Nodes default {}; #Set of Nodes
set Time default {}; # Set of Times
set ParentNodes default {}; #Set of Parent Nodes (a parent node contains at least two nodes)


#Subsets
set LayersOfType{LayerTypes} within Layers;

set StreamsOfUnit{Units} within Streams;
set StreamsOfLayer{Layers} within Streams;
set StreamsOfLocation{Locations} within Streams;
set HTSStreamsOfLocation{Locations} within Streams default {};
set StreamsOfTime{Time} within Streams default {};# It is defined for multi Time!!

set NodesOfLocation{Locations} default {};
set StreamsOfNode{Nodes} default {};

set ParentNodesOfLocation{Locations} default {};
set GParentNodesOfLocation{Locations} default {};
set ParentNodeOfNode{Nodes} default {};
set NodesOfParentNode{ParentNodes} default {};
set HTSStreamsOfParentNode{ParentNodes} default {};

set UnitsOfStream{Streams} within Units;
set UnitsOfLayer{Layers} within Units;
set UnitsOfLocation{Locations} within Units;
set UnitsOfTime{Time} within Units default {}; # It is defined for multi Time!! 

set LocationsOfLayer{Layers} within Locations;
set StorageStreams default {};

param Distance{Units,Units} default 0;
/*******************************************************/
#Units
/*******************************************************/
var Units_Mult{u in Units} >= 0;
var Units_Mult_t{u in Units,t in Time} >= 0;

#var Units_Use{u in Units,t in Time} binary := 1;
var Units_Use_t{u in Units,t in Time} binary ;
var Units_Use{u in Units} binary ;

param Units_ForceUse{u in Units,t in Time} binary;   # when 1, a unit must be used (eg: SYNPRO)

param Units_Fmin{u in Units}; 
param Units_Fmax{u in Units}; 


# Unit sizing constraints
subject to cstr_Units_Fmax{u in Units,t in Time:u in UnitsOfTime[t]} :
Units_Mult_t[u,t] <= Units_Use_t[u,t]*Units_Fmax[u];

subject to cstr_Units_Fmin{u in Units,t in Time:u in UnitsOfTime[t]} :
Units_Mult_t[u,t] >= Units_Use_t[u,t]*Units_Fmin[u];

# Unit usage constraint
subject to cstr_Units_Use{u in Units,t in Time:u in UnitsOfTime[t]}:
Units_Use_t[u,t] >= Units_ForceUse[u,t];


# Unit sizing constraints for whole period
subject to cstr_Units_Mult_h{u in Units,t in Time:u in UnitsOfTime[t]} :
Units_Mult[u]>=Units_Mult_t[u,t];

subject to cstr_Units_use_h{u in Units,t in Time:u in UnitsOfTime[t]} :
Units_Use[u] >= Units_Use_t[u,t];

# Units_Use[u] is a binary could replace with this new constraints.
#subject to cstr_Units_use_h2{u in Units,t in Time:u in UnitsOfTime[t]} :
#Units_Use[u] <= 1;


/*******************************************************/
#Streams Groups
/*******************************************************/

set StreamBehaviors default {};  # types of streams
set StreamGroups default {}; # set of groups of streams

set StreamGroupsOfType{StreamBehaviors} within StreamGroups;

set StreamGroupsMasters{StreamGroups} within Streams; # Defines the name of the Stream group master (generator)

#It is not posible to use ord in glpsol
set StreamsOfStreamGroup{StreamGroups} within Streams;  # set of streams within a group of streams

/*******************************************************/
#Unit Groups
/*******************************************************/

set UnitBehaviors default {};  # types of Units
set UnitGroups default {}; # set of groups of Units

set UnitGroupsOfType{UnitBehaviors} within UnitGroups;

set UnitGroupsMasters{UnitGroups} ; # Defines the name of the Unit group master (generator). Removed "within Units" since masters may not be defined within units (ex. synhea units)

#It is not posible to use ord in glpsol
set UnitsOfUnitGroup{UnitGroups} within Units;  # set of Units within a group of Units

