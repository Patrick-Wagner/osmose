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
  local costingLayer={}

  

	for m, model in ipairs(project.models) do
		for layerName, layer in pairs(model.layers) do
      ---add costing Layers (samira.fazlollahi@a3.epfl.ch) 
      local fullName
      if layer ~= nil and layer.type == 'Costing' then
			  fullName = layerName
	  elseif layer ~= nil and layer.type == 'HeatCascade' then
			  fullName = layerName
      else
        fullName =  'layers_'..layerName
      end
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
        elseif layer.type == 'Costing' then
          table.insert(costingLayer, fullName)
          ---add HeatCascade Layers (samira.fazlollahi@a3.epfl.ch) 
         elseif layer.type == 'HeatCascade' then
          table.insert(heatCascadeLayer, fullName) 
           
				else
					print(string.format("Layer of type '%s' is not recognized.", layer.type))
					print("Valid layer types are : Costing, HeatCascade, MassBalance, ResourceBalance")
					os.exit()
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
  
	return units
end


return lib