--[[------------------------------------------------------

  # Osmose

  The osmose directory contains the main classes of the application.

  ## Configuration

  A `config.lua` file must be created at the root of your projects and
  must contain the path to the third parties executable.

	Exemple of config.lua file:

	OSMOSE_ENV["GLPSOL_EXE"] 	= 'glpsol'
	OSMOSE_ENV["VALI_EXE"] 		= '"C:\\path\\to\\vali.exe "'
	OSMOSE_ENV["GNUPLOT_EXE"] = '/usr/local/bin/gnuplot'

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
