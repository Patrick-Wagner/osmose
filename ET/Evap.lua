--[[------------------------------------------------------

  # Evap

  The model is used to test Vali interface.

--]]------------------------------------------------------

local osmose = require 'osmose'
local evap = osmose.Model 'evap' 

evap.values={
  air_cp=1.007,--;% kJ/kg/C 
  water_cp=4.18,--;% kJ/kg/C 
  ice_cp=2.09,--;% kj/kg/C 
  water_molarmass=18,--; % g/mol 
  air_molarmass=29,--;% g/mol
}

evap.software = {'VALI','evap.bls' }-- (name of soft, name of model)


-- ## INPUTS
evap.inputs = { -- doc 
   
		-- Temperature of product at the inlet of the unit.
		PIN_T = {default = 45, min = 0, max = 40, unit = 'C ', status = 'CST', accuracy = '3'}, 
}

-- ##RESULTS
evap.outputs = { -- doc 

		-- description
		PH1_T= {unit = 'C '},

		-- description
		PH2_T= {unit = 'C '},

		-- description
		PH3_T= {unit = 'C '},

		-- preheat of product
		CPI_LOAD= {unit = 'kW '},

		-- preheat of 2nd product
		QCC1_LOAD= {unit = 'kW '},

		-- recovery heat
		Q_THERM_LOAD= {unit = 'kW '},
}

-- ##ADVANCED
evap.advanced = {  
  -- Heat transfer film coefficient of water is used for all stream definitions.
  -- [math][/math]
  water_h = {default = 1.136, min = 1, max = 2, unit = 'kW/m2 C'},


	h_prod =  {default = 1.136, min = 1, max = 2, unit = 'kW/m2 C'},
} 


-- evap.addUnit("evap_1_effect",type = "Process",IN) -- Flag : IN or OUT

evap:addUnit("evap_1_effect",{ type = "Process"}) 
    evap["evap_1_effect"]:addStreams {      
      prod_preheat_1 =  { 'PIN_T',0,'PH1_T','CPI_LOAD',3, 'h_prod'},
      prod_preheat_2 =  { 'PIN_T','CPI_LOAD','PH1_T',0,3, 'h_prod'},
      prod_preheat_5 = { 'PH1_T', 0,'PH2_T','QCC1_LOAD', 3,'water_h'},
      prod_preheat_6 =  { 'PH3_T','Q_THERM_LOAD','PH2_T',0, 3, 'water_h'}}
    -- evap["evap_1_effect"]:addStreams {      
    --   prod_preheat_1 =  { 36,0,36.01,'CPI_LOAD',3, 'h_prod'},
    --   prod_preheat_5 = { 36, 0,'PH2_T','QCC1_LOAD', 3,'water_h'},
    --   prod_preheat_6 =  { 'PH3_T','Q_THERM_LOAD','PH2_T',0, 3, 'water_h'}}

return evap

