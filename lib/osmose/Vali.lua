-- ## Vali(model, dirTmp, blsFile)

-- This class is responsible for handling the Vali executable program.
-- It generate the text files, execute the command and parse the results.

-- It needs an instance of model (model), a temporary directory to store all the files (dirTmp)
-- and the name of the bls file associated with the model (blsFile). This bls file
-- is usually stored with the model definition on the ET library.

-- Vali Usage Example :

-- `local model = require "ET.Evap" ('test')`
-- `local vali = Vali(model, 'test/tmp/', 'evap.bls')`


local lustache = require "lib.osmose.eiampl.vendor.lustache"
local lub 	= require 'lub'
local lib 	= lub.class 'osmose.Vali'


function lib.new(model, dirTmp, blsFile)
	local self= lub.class('Vali')
	setmetatable(self, lib)
	self.model = model
	self.dirTmp = dirTmp
	self.blsFile = blsFile
	return self
end


-- ## vali:copyBlsFile()
-- Copy the bls file on the temporary dir for Vali execution.

function lib:copyBlsFile()
	local f = assert(io.open('ET/bls/'..self.blsFile,"r"))
	local content = f:read("*all")
	f:close()

	local f = assert(io.open(self.dirTmp..self.blsFile,"w"))
	f:write(content)
	f:close()
end


-- ## vali:copyBlsFile()
-- Generate the mea file from the mustache template.
-- It needs to define the CST tags for vali, which are the model inputs tags recovered by the 
-- vali:generateTags() function.

function lib:generateMeaFile()
	local f = assert(io.open('lib/osmose/templates/mea.mustache') )
	local template = f:read('*a')
	f:close()

	local content = lustache:render(template, {
		tags = self:generateTags()
	})

	local meaFile = assert(io.open(self.dirTmp..'temp_mea.mea',"w") )
	meaFile:write(content)
	meaFile:close()
end


-- ##vali:generateVifFile()
-- It generate the vif file from the mustache template. It needs the
-- bls file name given the class declaration.

function lib:generateVifFile()
	local f = assert(io.open('lib/osmose/templates/vif.mustache') )
	local template = f:read('*a')
	f:close()

	local content = lustache:render(template, {
		blsFile = self.blsFile
		})

	local vifFile = assert(io.open(self.dirTmp..'pc.vif',"w") )
	vifFile:write(content)
	vifFile:close()
end


-- ##vali:execute()

-- It execute the vali command which must be given in the "VALI_EXE" environment variable, for exemple :

-- OSMOSE_ENV["VALI_EXE"] = 'vali.exe < pc.vif > vali.log'

-- It return the execution status of the command.

function lib:execute()	
	local lfs = require "lfs"
	local currentDir = lfs.currentdir()
	lfs.chdir(self.dirTmp)
	local cmd = OSMOSE_ENV["VALI_EXE"]
	local status, reason, infonum = os.execute(cmd)
	lfs.chdir(currentDir)
	return status, reason, infonum
end


-- ##vali:parseResult()
-- It parses the Vali output text file which is 'vali_output_tags.txt'. It stores all the
-- tags result as numeric value in the model.

function lib:parseResult()
	local outputFile
	if OSMOSE_ENV["VALI_MOCK_FILE"] then
		outputFile = OSMOSE_ENV["VALI_MOCK_FILE"] 
	else
		outputFile = self.dirTmp..'vali_output_tags.txt'
	end
	print(outputFile , OSMOSE_ENV["VALI_MOCK_FILE"])
	local f = assert(io.open(outputFile,'r'))
	for line in f:lines() do
		if line:match("!") then
		else
			local tag, value, deviation, reconciledValue, accurancy, unit = 
						line:match("([%w_]+) %s+([%-%d%.]+) %s+([%-%d%.E%+]+) %s+([%-%d%.]+)")
			self.model[tag] = tonumber(reconciledValue)
			--print('VALI:', tag, value, deviation, reconciledValue )
		end
	end
end


-- ##vali:generateTags()
-- It generates the CST tags for the mea file, which are the model inputs.

function lib:generateTags()
	local tags={}
	for name,input in pairs(self.model.inputs) do
		table.insert(tags, {name=name, value=input.default, status=(input.status or 'CST'), accuracy=input.accuracy})
	end

	return tags
end


return lib
