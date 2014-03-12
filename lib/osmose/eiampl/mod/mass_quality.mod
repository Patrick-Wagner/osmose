# $Id: mass_quality.mod 2221 2010-08-16 15:18:38Z bolliger $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Quality addins for Mass Balance with Quality Layer
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Definition of stream components, which may be composed by several substances or represent a particular stream quality
set MBQ_components {MassBalancesWithQuality};

# For each component, this says wether its input flowrate must satisfy at least a given quantity/quality. This is a binary variable which triggers MBQ_quality constraint below
param Units_quality_constr{ l in MassBalancesWithQuality, u in UnitsOfLayer[l], c in MBQ_components[l]} binary default 0;

# For each component an input and an output quality/concentration can be defined
param Units_quality_in{ l in MassBalancesWithQuality, u in UnitsOfLayer[l], c in MBQ_components[l]} default 0;
param Units_quality_out{ l in MassBalancesWithQuality, u in UnitsOfLayer[l], c in MBQ_components[l]} default 0;

# Mix quality at unit u for product l
var Unit_quality_mix_pf{ l in MassBalancesWithQuality, loc in LocationsOfLayer[l],  u in MB_Units[l,loc], c in MBQ_components[l] : Units_flowrate_in[l,u]>0} >=0;
subject to unit_quality_mix_pf_cstr{l in MassBalancesWithQuality, loc in LocationsOfLayer[l],  u in MB_Units[l,loc], c in MBQ_components[l] : Units_flowrate_in[l,u]>0}:  
	Unit_quality_mix_pf[l,loc,u,c]=sum {i in MB_Units[l,loc]: i!=u and Units_flowrate_out[l,i]>0} (MB_ship[l,loc,i,u]*Units_quality_out[l,i,c]);


# Quality constraint. We ensure that a certain quality is satisfied for each componend activated by Units_quality_constr
subject to MBQ_quality{ l in MassBalancesWithQuality, loc in LocationsOfLayer[l],  u in MB_Units[l,loc], c in MBQ_components[l] : Units_quality_constr[l,u,c]=1}:
	Unit_quality_mix_pf[l,loc,u,c] >= Units_demand[l,u]*Units_quality_in[l,u,c];


# Quality of the component c entering unit u
#var Unit_quality_mix_in{ l in MassBalancesWithQuality, loc in LocationsOfLayer[l],  u in MB_Units[l,loc], c in MBQ_components[l]} ;

#????????????????????????????????????????????????????????????????????????????
#var Unit_quality_mix_in{ l in MassBalancesWithQuality, loc in LocationsOfLayer[l],  u in MB_Units[l,loc], c in MBQ_components[l]:Units_flowrate_in[l,u]>0} = 
#	if (Units_demand[l,u] > 0)
#		then (Unit_quality_mix_pf[l,loc,u,c]/Units_demand[l,u])
#		else (Units_quality_out[l,u,c]);






