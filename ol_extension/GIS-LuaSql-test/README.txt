  README.txt  GIS_LuaSql_test    This directory includes WIP Lua modules concerning LuaSql driver and SQLite libraries which are used for GIS data reading.  The database API and LuaSql driver are used in order to read an extract of dbf file (in CVS format).  For the purpose of testing the module, you should first of all install SQLite3 and LuaSql.     Here is the description of containted files.    * small_city_dbf2.cvs : extract of a GIS data file
  * TestGIS.db : a Sql example data  * GisDataHandler : several functions to read dbf file data and save 

  How to use ?

  1. Copy the small_city_dbf2.csv and TestFis.db within your chosen directory
  2. Copy the GisDataHandler.lua within Your_Lua_Test or Work In Progress directory (such as projects, for example)
  3. Modify the directDataPath value in the module GisDataHandler (local defaultDataPath = "/Users/minjyoo/“) according to your directory name.
  4. run the GisDataHandler module using lua command.

A complete test example will be soon given.
