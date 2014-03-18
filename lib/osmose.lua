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

		local oneRun = osmose.Eiampl(project)

		osmose.Glpk(oneRun)

		osmose.Graph(oneRun)

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


return lib
