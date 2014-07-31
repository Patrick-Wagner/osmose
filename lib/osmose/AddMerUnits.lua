-- This function add 2 Units to solve the MER Objective : Default HeatCascade Unit Hot (DHCU_h) and
-- Default HeatCascade Unit Cold (DHCU_c). Each of them has 1 stream, hot and cold.

-- @author: Samira Fazlollahi (samira.fazlollahi@a3.epfl.ch)

-- @copyright IPESE

-- @param: Project.units, Project.project_name

-- @release 0.1

-- @return: the MER units

-- @status _proposed



local lub 	= require 'lub'
local lib 	= lub.class 'osmose.AddMerUnits'


function lib.new(units, project_name)
		table.insert(units,{ name="DHCU_h", force_use=0, 
    fFmin = function() return 0 end,
    fFmax = function() return 100000 end,
		--Cost1=1000,
		--Cost2=1000,
    massStreams={},
    resourceStreams = {},
		layers={DefaultImpact={name = "DefaultImpact", type = "Costing"},
      DefaultOpCost={name = "DefaultOpCost", type = "Costing"},
      DefaultInvCost={name = "DefaultInvCost", type = "Costing"},
      DefaultMechPower={name = "DefaultMechPower", type = "Costing"}},

		streams={{name="DHCS_h", unitName="DHCU_h",
					Tin				=function() return 99999 end, 
					Tout			=function() return 99998 end, 
					Tin_corr	=function() return 99999 end, 
					Tout_corr	=function() return 99998 end, 
					Hin 			=function() return 1000 end, 
					Hout 			=function() return 0 end, 
					isHot			=function() return true end,
					load 			={},
					draw			=false }},
     costStreams={
       {layerName = "DefaultOpCost", name = "DHCS_h_Cost", unitName="DHCU_h",
         coefficient1 = function() return 100 end, 
         coefficient2 = function() return 100 end},
       {layerName = "DefaultInvCost", name = "DHCS_h_Cinv", unitName="DHCU_h",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultMechPower", name = "DHCS_h_Power", unitName="DHCU_h",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultImpact", name = "DHCS_h_Impact", unitName="DHCU_h",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end}}

		})


	table.insert(units,{name="DHCU_c", force_use=0, 
    fFmin = function() return 0 end,
    fFmax = function() return 100000 end,
		--Cost1 = 1000,
		--Cost2 = 1000,
    massStreams ={},
    resourceStreams = {},
		layers={DefaultImpact={name = "DefaultImpact", type = "Costing"},
      DefaultOpCost={name = "DefaultOpCost", type = "Costing"},
      DefaultInvCost={name = "DefaultInvCost", type = "Costing"},
      DefaultMechPower={name = "DefaultMechPower", type = "Costing"}},

		streams={{name="DHCS_c", unitName="DHCU_c",  
					Tin 			=function() return 100 end, 
					Tout 			=function() return 105 end, 
					Tin_corr 	=function() return 100 end, 
					Tout_corr =function() return 105 end, 
					Hin 			=function() return 0 end, 
					Hout 			=function() return 1000 end, 
					isHot			=function() return false end,
					load 			={},
					draw			=false }},
    
    costStreams={
       {layerName = "DefaultOpCost", name = "DHCS_c_Cost", unitName="DHCU_c",
         coefficient1 = function() return 100 end, 
         coefficient2 = function() return 100 end},
       {layerName = "DefaultInvCost", name = "DHCS_c_Cinv", unitName="DHCU_c",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultMechPower", name = "DHCS_c_Power", unitName="DHCU_c",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultImpact", name = "DHCS_c_Impact", unitName="DHCU_c",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end}}
      
     
		})

	return units
end


return lib