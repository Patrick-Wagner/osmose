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


function lib.new(project,units)
 
 local layersAll = {}
  -- Recover all layers
  local heatCascadeLayer = {}
	local massBalanceLayer = {}
  local resourceBalanceLayer = {}


  

	for m, model in ipairs(project.models) do
		for layerName, layer in pairs(model.layers) do
      ---add costing Layers (samira.fazlollahi@a3.epfl.ch) 
      local fullName
      if layer ~= nil then
			  fullName = layerName
      end
      --[[
      if layer ~= nil and layer.type == 'HeatCascade' then
			  fullName = layerName
      else
        fullName =  'layers_'..layerName
      end
      --]]
			local layerFound = 0
			for i,l in ipairs(layersAll) do
				if l==fullName then
					layerFound = 1
				end
			end
			if layerFound == 0 then
				table.insert(layersAll, fullName)

				if layer.type == 'MassBalance' then
					table.insert(massBalanceLayer, fullName)
          ---add ResourceBalance Layers (samira.fazlollahi@a3.epfl.ch) 
        elseif layer.type == 'ResourceBalance' then
					table.insert(resourceBalanceLayer, fullName)
          ---add costing Layers (samira.fazlollahi@a3.epfl.ch) 
        elseif layer.type == 'HeatCascade' then
          table.insert(heatCascadeLayer, fullName) 

				end
			end
		end
	end
	

  -- add hot and cold utility
  for eachlayerName, layer in pairs(heatCascadeLayer) do 
    
    -- add hot utility   
		table.insert(units,{name=layer.."_DHCU_h", force_use=0, 
    fFmin = function() return 0 end,
    fFmax = function() return 100000 end,
		--Cost1=1000,
		--Cost2=1000,
    massStreams={},
    resourceStreams = {},
    
		layers={DefaultImpact={name = "DefaultImpact", type = "Costing"},
      DefaultOpCost={name = "DefaultOpCost", type = "Costing"},
      DefaultInvCost={name = "DefaultInvCost", type = "Costing"},
      DefaultMechPower={name = "DefaultMechPower", type = "Costing"},
      [layer] = {name = layer, type = "HeatCascade"}},      
    
		streams={{name=layer.."_DHCS_h", unitName=layer.."_DHCU_h",
					Tin				=function() return 99999 end, 
					Tout			=function() return 99998 end, 
					Tin_corr	=function() return 99999 end, 
					Tout_corr	=function() return 99998 end, 
					Hin 			=function() return 1000 end, 
					Hout 			=function() return 0 end, 
          layerName = layer,
					isHot			=function() return true end,
					load 			={},
					draw			=false }},
     costStreams={
       {layerName = "DefaultOpCost", name = layer.."_DHCS_h_Cost", unitName=layer.."_DHCU_h",
         coefficient1 = function() return 100 end, 
         coefficient2 = function() return 100 end},
       {layerName = "DefaultInvCost", name = layer.."_DHCS_h_Cinv", unitName=layer.."_DHCU_h",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultMechPower", name = layer.."_DHCS_h_Power", unitName=layer.."_DHCU_h",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultImpact", name = layer.."_DHCS_h_Impact", unitName=layer.."_DHCU_h",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end}}

  })


    -- add cold utility
    table.insert(units,{name=layer.."_DHCU_c", force_use=0, 
    fFmin = function() return 0 end,
    fFmax = function() return 100000 end,
		--Cost1 = 1000,
		--Cost2 = 1000,
    massStreams ={},
    resourceStreams = {},
		  
      layers={DefaultImpact={name = "DefaultImpact", type = "Costing"},
      DefaultOpCost={name = "DefaultOpCost", type = "Costing"},
      DefaultInvCost={name = "DefaultInvCost", type = "Costing"},
      DefaultMechPower={name = "DefaultMechPower", type = "Costing"},
      [layer] = {name = layer, type = "HeatCascade"}},
      
		streams={{name=layer.."_DHCS_c", unitName=layer.."_DHCU_c",  
					Tin 			=function() return 100 end, 
					Tout 			=function() return 105 end, 
					Tin_corr 	=function() return 100 end, 
					Tout_corr =function() return 105 end, 
					Hin 			=function() return 0 end, 
					Hout 			=function() return 1000 end, 
          layerName = layer,
					isHot			=function() return false end,
					load 			={},
					draw			=false }},
    
    costStreams={
       {layerName = "DefaultOpCost", name = layer.."_DHCS_c_Cost", unitName=layer.."_DHCU_c",
         coefficient1 = function() return 100 end, 
         coefficient2 = function() return 100 end},
       {layerName = "DefaultInvCost", name = layer.."_DHCS_c_Cinv", unitName=layer.."_DHCU_c",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultMechPower", name = layer.."_DHCS_c_Power", unitName=layer.."_DHCU_c",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultImpact", name = layer.."_DHCS_c_Impact", unitName=layer.."_DHCU_c",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end}}

		})
  
  
  end





  for eachlayerName, layer in pairs(massBalanceLayer) do 
    
    -- add in mass utility   
		table.insert(units,{name=layer.."_DHCU_mi", force_use=0, 
    fFmin = function() return 0 end,
    fFmax = function() return 100000 end,
		--Cost1=1000,
		--Cost2=1000,
    streams={},
    resourceStreams = {},
    
		layers={DefaultImpact={name = "DefaultImpact", type = "Costing"},
      DefaultOpCost={name = "DefaultOpCost", type = "Costing"},
      DefaultInvCost={name = "DefaultInvCost", type = "Costing"},
      DefaultMechPower={name = "DefaultMechPower", type = "Costing"},
      [layer] = {name = layer, type = "MassBalance"}},      
    
		massStreams={{name=layer.."_DHCS_mi", unitName=layer.."_DHCU_mi",
					inOut ="in", 
					Flow = function() return 10 end,
				  layerName = layer,
          AddToProblem = 1,
					load 			={}
          }},
     costStreams={
       {layerName = "DefaultOpCost", name = layer.."_DHCS_mi_Cost", unitName=layer.."_DHCU_mi",
         coefficient1 = function() return 100 end, 
         coefficient2 = function() return 100 end},
       {layerName = "DefaultInvCost", name = layer.."_DHCS_mi_Cinv", unitName=layer.."_DHCU_mi",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultMechPower", name = layer.."_DHCS_mi_Power", unitName=layer.."_DHCU_mi",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultImpact", name = layer.."_DHCS_mi_Impact", unitName=layer.."_DHCU_mi",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end}}

    })


    -- add out mass utility
    table.insert(units,{name=layer.."_DHCU_mo", force_use=0, 
      fFmin = function() return 0 end,
      fFmax = function() return 100000 end,
      --Cost1 = 1000,
      --Cost2 = 1000,
      streams={},
      resourceStreams = {},
		  
      layers={DefaultImpact={name = "DefaultImpact", type = "Costing"},
      DefaultOpCost={name = "DefaultOpCost", type = "Costing"},
      DefaultInvCost={name = "DefaultInvCost", type = "Costing"},
      DefaultMechPower={name = "DefaultMechPower", type = "Costing"},
      [layer] = {name = layer, type = "MassBalance"}},
      
      massStreams={{name=layer.."_DHCS_mo", unitName=layer.."_DHCU_mo",  
					inOut ="out", 
					Flow = function() return 10 end ,
				  layerName = layer,
          AddToProblem = 1,
					load 			={}
          }},
    
      costStreams={
       {layerName = "DefaultOpCost", name = layer.."_DHCS_mo_Cost", unitName=layer.."_DHCU_mo",
         coefficient1 = function() return 100 end, 
         coefficient2 = function() return 100 end},
       {layerName = "DefaultInvCost", name = layer.."_DHCS_mo_Cinv", unitName=layer.."_DHCU_mo",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultMechPower", name = layer.."_DHCS_mo_Power", unitName=layer.."_DHCU_mo",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultImpact", name = layer.."_DHCS_mo_Impact", unitName=layer.."_DHCU_mo",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end}}

     })
  
   for eachlayerName, layer in pairs(resourceBalanceLayer) do 
    
    -- add in mass utility   
		table.insert(units,{name=layer.."_DHCU_ri", force_use=0, 
    fFmin = function() return 0 end,
    fFmax = function() return 100000 end,
		--Cost1=1000,
		--Cost2=1000,
    streams={},
    resourceStreams = {},
    
		layers={DefaultImpact={name = "DefaultImpact", type = "Costing"},
      DefaultOpCost={name = "DefaultOpCost", type = "Costing"},
      DefaultInvCost={name = "DefaultInvCost", type = "Costing"},
      DefaultMechPower={name = "DefaultMechPower", type = "Costing"},
      [layer] = {name = layer, type = "ResourceBalance"}},      
    
		massStreams={{name=layer.."_DHCS_ri", unitName=layer.."_DHCU_ri",
					inOut ="in", 
					Flow_r = function() return 10 end,
				  layerName = layer,
          AddToProblem = 1,
					load 			={}
          }},
     costStreams={
       {layerName = "DefaultOpCost", name = layer.."_DHCS_ri_Cost", unitName=layer.."_DHCU_ri",
         coefficient1 = function() return 100 end, 
         coefficient2 = function() return 100 end},
       {layerName = "DefaultInvCost", name = layer.."_DHCS_ri_Cinv", unitName=layer.."_DHCU_ri",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultMechPower", name = layer.."_DHCS_ri_Power", unitName=layer.."_DHCU_ri",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultImpact", name = layer.."_DHCS_ri_Impact", unitName=layer.."_DHCU_ri",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end}}

    })


    -- add out mass utility
    table.insert(units,{name=layer.."_DHCU_ro", force_use=0, 
      fFmin = function() return 0 end,
      fFmax = function() return 100000 end,
      --Cost1 = 1000,
      --Cost2 = 1000,
      streams={},
      resourceStreams = {},
		  
      layers={DefaultImpact={name = "DefaultImpact", type = "Costing"},
      DefaultOpCost={name = "DefaultOpCost", type = "Costing"},
      DefaultInvCost={name = "DefaultInvCost", type = "Costing"},
      DefaultMechPower={name = "DefaultMechPower", type = "Costing"},
      [layer] = {name = layer, type = "ResourceBalance"}},
      
      massStreams={{name=layer.."_DHCS_ro", unitName=layer.."_DHCU_ro",  
					inOut ="out", 
					Flow_r = function() return 10 end ,
				  layerName = layer,
          AddToProblem = 1,
					load 			={}
          }},
    
      costStreams={
       {layerName = "DefaultOpCost", name = layer.."_DHCS_ro_Cost", unitName=layer.."_DHCU_ro",
         coefficient1 = function() return 100 end, 
         coefficient2 = function() return 100 end},
       {layerName = "DefaultInvCost", name = layer.."_DHCS_ro_Cinv", unitName=layer.."_DHCU_ro",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultMechPower", name = layer.."_DHCS_ro_Power", unitName=layer.."_DHCU_ro",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end},
       {layerName = "DefaultImpact", name = layer.."_DHCS_ro_Impact", unitName=layer.."_DHCU_ro",
         coefficient1 = function() return 0 end, 
         coefficient2 = function() return 0 end}}

     })
  
  end
  
	return units
end


return lib