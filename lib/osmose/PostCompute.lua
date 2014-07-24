--[[---------------------------------------
  
  # PenHEX
  
  Allows to list penalising heat exchangers for each period. 
--]]---------------------------------------

local lub   = require 'lub'
local lib   = lub.class 'osmose.PostCompute'



--[[
  Draws Composite Curves (CC) and Grand Composites Curves (GCC). You can
  specify an format output.

  Exemples:

    osmose.Graph(project) 
    osmose.Graph(project, 'svg') 
  -- careful for utilties and periods. Must multiply loads for utls. 
--]]
function lib.new(project)
  local model = project.models[1]
  local streams
  local units
  local texter
  local Q
  
  for periode in ipairs(project.periodes) do
    print("--------------------------")
    print("Period:  " .. tostring(periode).. ".")
    for time=1, project.periodes[periode].times do
        model.time = time
        print(" -------------------------")
        print(" Time:  " .. tostring(time).. ".")
        print(" -------------------------")
        for uniter=1,table.getn(project.units[1]) do 
          units = project.units[1][uniter]
          if units.shortName == nil then
            texter4 = units.name
          else
            texter4 = units.shortName
          end
   
            texter = tostring(units.mult_t[time])
            texter2 = tostring(units.use_t[time])
              print(" Unit: "..texter4..". Use: "..texter2 .. ". Mult: " .. texter)
      end
    end
    print(" ------------------------------------------------------------")
    print(" Optimisation results")
    print(" Operational costs: "..tostring(project.results.opcost[periode]))
    print(" Investment costs: "..tostring(project.results.invcost[periode]))
    print(" Impact: "..tostring(project.results.impact[periode]))
    print(" Mechanical power: "..tostring(project.results.mechpower[periode]))
    print("------------------------------------------------------------")
  end
end
return lib