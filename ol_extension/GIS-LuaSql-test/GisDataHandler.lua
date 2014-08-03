---
-- Module for handling some GIS related functions and data tables.
-- GIS data can be taken over using two data formats : i) CSV format, ii) Sqlite3 db file format
-- Ultimately, being based on this module function, the OL SQL handlers and related GIS functions will be packaged.
-- Tag data construction using gis: WIP
-- @module GisDataHandler
-- @param 
-- @return parsed GIS data tables
-- @usage 
-- @author  MinJYoo
-- @copyright IPESE
-- @release 0.1

lfs = require"lfs"
local gis = {}


---
-- Print All table elements created from this test module.
-- @function printAll
-- @param 
-- return true if all internal data was accessible and printable
-- return false otherwise 
function gis.printAll ()
  print ('... The print function to be implemented')
  return true
end


---
-- retrieve one line of data from a given CSV file
-- @function get_lineCSV 
-- @param s text file name which contains some GIS data. The first line of this text data will be used as column index names of the remaining data lines. 
-- @return table data 
function gis.get_lineCSV (s)
   print(s)
   -- add a nil char at the end of the string (for end of file check)
   s = s..string.char(13)

   local linetable = {}
   local fieldstart = 1
   
   repeat
      local nexti = string.find(s, string.char(13), fieldstart)
   
      local substr = string.sub(s, fieldstart, nexti-1)
      print ("------ nexti found :: "..substr)
      table.insert(linetable, substr)
      fieldstart = nexti + 1
   until fieldstart >= string.len(s)
   return linetable
end

---
-- Convert from CSV string to table (converts a single line of a CSV file).
-- @function fromCSV
-- @param s text file name which contains some GIS data. The first line of this text data will be used as column index names of the remaining data lines. 
-- @return t table which contains all fields value included in s csv format file
function gis.fromCSV (s)
  print (" --- within the function fromCSV, string value == ---")
  print (s)
  
  s = s .. ','        -- ending comma
  local t = {}        -- table to collect fields
  local fieldstart = 1
 
  repeat
    -- next field is quoted? (start with `"'?)
    if string.find(s, '^"', fieldstart) then

      local a, c
      local i  = fieldstart
      repeat
        -- find closing quote
        a, i, c = string.find(s, '"("?)', i+1)
      until c ~= '"'    -- quote not followed by quote?
      if not i then error('unmatched "') end
      local f = string.sub(s, fieldstart+1, i-1)
      table.insert(t, (string.gsub(f, '""', '"')))
      fieldstart = string.find(s, ',', i) + 1
    else                -- unquoted; find next comma
      local nexti = string.find(s, ',', fieldstart)
      local substr = string.sub(s, fieldstart, nexti-1)
      table.insert(t, substr)
      fieldstart = nexti + 1
    end
    
  until fieldstart > string.len(s)
  print()
  print("--------- END OF PARSING ----------")
  for k,v in pairs(t) do print(k,v) end
  
  return t
end


---
-- Convert from CSV string to table (converts a single line of a CSV file).
-- @function readcsv 
-- @param filename CSV format file within which some GIS data is written.
-- @return citytable a line of data parsed from the input file in csv format
function gis.readcsv(filename)
  local file = assert(io.open(filename, "r"))
  local t = file:read("*all")
  local citytable = gis.get_lineCSV(t) 
 
  file:close()
  return (citytable)
end


---
-- fill_data
-- @function fill_data
-- @param data_table the data which should be modified
-- @param ndx index number in data_table
-- @param dataline  the data value used to update
-- @return data_table with the updated information
function gis.fill_data (data_table, ndx, dataline)  -- dataline is the information table of a building 
  data_table[ndx] = dataline 
  return data_table
end


---
-- Retrieve the required data element and print it
-- @function show_buildinginfo
-- @param buildingdata
-- @return true if print ok
function gis.show_buildinginfo (buildingdata)       -- buildingdata : a table which contains one line information
                                                -- parsed from csv file 
  print ("  --- Saved Building Information --- ")                                              
  for k,v in pairs(buildingdata) do print(k,v) end
  return true
end


---
-- retrieve the corresponding data value according to a given key string and return the found data
-- @function get_buildingvalue
-- @param dataline the line of data to be searched
-- @param keystr the key string value
-- @return val the found value
function gis.get_buildingvalue (dataline, keystr)
  local val = dataline[keystr]
  return val
end


---
-- Convert from CSV string to table (converts a single line of a CSV file).
-- @function [parent=#CityGisTest] 
-- @param filename CSV format file within which some GIS data is written.
-- @return citytable a line of data parsed from the input file in csv format
function gis.rows (connection, sql_statement)
  local cursor = assert (connection:execute (sql_statement))
  return function ()
    return cursor:fetch()
  end
end


---
-- Start main body of definition which shows how to use the functions 
-- 
-- 

---
--The following statements shows how to use some functions declared in this module.
--A full range test program will be supplied soon. (TestAll.lua WIP)

-- Your file path  
local defaultDataPath = "/Users/minjyoo/"     -- the directory where you put the following two test data
local csvFileName = "small_city_dbf2.csv"
local gisSqlData = "TestGIS.db"
local cityCSV = defaultDataPath..csvFileName  -- input csv file here

local data = gis.readcsv(cityCSV)
  
local citydata ={}
local city_table = {}
local index_table = {}

table.insert(citydata, gis.fromCSV (data[1]))
table.insert(citydata, gis.fromCSV (data[2]))
table.insert(citydata, gis.fromCSV (data[3]))
print(table.getn(citydata))

-- First: Try to read the CSV file into a Lua internal Table Structure
-- index_data: Index file concerning the first line of information
-- disctrict_data: building information data. 
-- Usage district_data[1] corresponds to the first line of building information
-- Data retrieval: district_data[1].OBJECTID, district_data[2].["HP_kWh"]

index_table = citydata[1]
print("  -----  index_table check  -----")
for k,v in pairs(index_table) do print(k,v) end
 
-- following lines for the purpose of constructing content_table mixing index table and citydata

local district_data ={}   -- the whole content of the database
local building_data ={}    -- information of a building in a district

local lnum = table.getn(citydata)-1 

for l=1, lnum do
    local j=l+1
  local t = citydata[j]
  for i=1, 21 do

    building_data[index_table[i]] = t[i]

  end
  --for k,v in pairs(building_data) do print(k,v) end
  gis.show_buildinginfo (building_data);
  table.insert(district_data, l, building_data)
end

----------------------------------------------------
-- The following lines of code is ongoing test yet.
-- Function to be provided.

-- test for luasql while creating an SQL database
-- load driver
local sqlite3 = require "lsqlite3"
print ('--- sqlite3 version is ...')
print (sqlite3.version())

local myDB = sqlite3.open (defaultDataPath..gisSqlData)  -- path to the database
print ('... ECHO print myDB')
print (myDB)
print ('... ECHO print index_table')
print (index_table)

myDB:execute[[ 
run_sql_CREATE ("small_city_db2", column_header = {"OBJETID", "ID_GO", "ESTRID", "Shape_Leng", "Shape_Area", "Year", "EA_Heating"})       
 ]]

      print ("data fetch test")
      print (district_data[1].OBJECTID)
    

      local oid = district_data[1].OBJECTID
      local idgo = district_data[1].ID_GO
      local estr = district_data[1].ESTRID
      local leng = district_data[1].Shape_Leng
      local area = district_data[1].Shape_Area
      local yr = district_data[1].Year
      local heat = district_data[1].EA_Heating
      
      print (' The values to be inserted : '..oid..', '..idgo..', '..estr..', '..leng..', '..area..', '..yr..', '..heat)
      

      local sqlcmd = [[INSERT INTO small_city_db2 VALUES (']].. oid.. [[', ']] .. idgo .. [[', ']] .. estr .. [[',']] .. leng .. [[',']] .. area .. [[', ']] .. yr .. [[',']] ..heat.. [['); 
                      ]]
      myDB:execute (sqlcmd)


print ("SQL EXEC OK")

myDB:close()

return gis
