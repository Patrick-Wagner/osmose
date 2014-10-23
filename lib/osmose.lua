--[[------------------------------------------------------

# Osmose

The osmose directory contains the main classes of the application.

## Configuration

A `config.lua` file must be created at the root of your working directory
and must contain the path to the third parties executable.

Exemple of config.lua file:

	OSMOSE_ENV["GLPSOL_EXE"] 	= 'glpsol'<br/>
	OSMOSE_ENV["VALI_EXE"] 		= '"C:\\path\\to\\vali.exe "'<br/>
	OSMOSE_ENV["GNUPLOT_EXE"] = '/usr/local/bin/gnuplot'

Your working directory must contain the following directory :

/ET 					_folder to store ET models_
/projects     _folder to store frontends file_
/results      _folder where osmose results will be generated_

## Frontend

A typical frontend will stored in file such as `jam.lua` 
in the `projects` directory and will have the following elements :

	local osmose = require 'osmose'

	local project = osmose.Project('LuaJam', 'MER')

	project:load(
		{cip = "ET.Cip"},
	  {utilities = "ET.generic_utilities"},
		{cm1 = "ET.CookingMixing"},
		{cm2 = "ET.CookingMixing", with = 'CM2_inputs.csv'}
	)

	project:solve()

	project:compute('jam_postcompute')

## Optimisation

Osmose works seamlessly with [Dakota](http://dakota.sandia.gov/software.html).

	local osmose = require 'lib.osmose'

	local project = osmose.Project('S_Problem_MOO', 'OpCostWithImpact')
	project.operationalCosts = {cost_elec_in = 17.19, cost_elec_out = 16.9, op_time= 2000.0}
	project:load({P_MOO = "ET.S_Problem_MOO"})

	project:optimize {
		software='dakota',
		precomputes={'S_problem_MOO_precompute'},
		objectives={'S_problem_MOO_postcompute1'},
		objectives_size=2,
		variables={x1={lower_bound='0', upper_bound='1.0', initial='0.5'},
							 x2={lower_bound='0', upper_bound='1.0', initial='0.5'}},
		method={name = 'moga', max_iterations=100},
		}

## ET Models

You can create you're own ET models and store then in 
a local directory such as 'ET'. Please see the Model
documentation page.

--]]------------------------------------------------------

OSMOSE_ENV={}

package.path = ';./lib/?/?.lua;./lib/?.lua;'..package.path
package.path = ';./ET/?/?.lua;./ET/?.lua;'..package.path


local lfs = require "lfs"
if lfs.attributes("./config.lua") then
	loadfile("./config.lua")()
else
	print("No osmose_ini.lua file")
end

local lub = require 'lub'
local lib = lub.Autoload 'osmose'

-- global shortcut
qt = lib.QTStream
ht = lib.HTStream
ms = lib.MassStream
rs = lib.ResourceStream


return lib
