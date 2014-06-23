-- Module for defining the different EI objective functions.

-- @author: Samira Fazlollahi (samira.fazlollahi@a3.epfl.ch)

-- @copyright IPESE

-- @param: Project.objective

-- @release 0.1

-- @return: the extended definition of objective function of mod file

-- @status _proposed

-- The general type of objective functions are; 
-- MER: Costs_Cost['osmose_default_model_DefaultOpCost'] 
-- InvestmentCost: Costs_Cost['osmose_default_model_DefaultInvCost']
-- OperatingCost: Costs_Cost['osmose_default_model_DefaultOpCost'] 
-- MechanicalPower: Costs_Cost['osmose_default_model_DefaultMechPower']
-- Impact: Costs_Cost['osmose_default_model_DefaultImpact']
-- TotalCost: InvestmentCost+OperatingCost 
-- OpCostWithImpact: OperatingCost+Impact
-- TotalCostWithPower: InvestmentCost+OperatingCost+ MechanicalPower
-- TotalCostWithImpact: InvestmentCost+OperatingCost+Impact
-- TotalCostWithImpactAndPower: InvestmentCost+OperatingCost+ MechanicalPower+Impact
-- YearlyOperatingCost

local lub 	= require 'lub'
local lib 	= lub.class 'osmose.ObjectiveFunction'


function lib.new(objective)
	if objective=='MER' then
		--content = content .. lib.generate_solve_function:gsub("osmose_default_model", project.name)
		objective_function = "minimize ObjectiveFunction : Costs_Cost['osmose_default_model_DefaultOpCost']; solve; \n\n"
    
	elseif objective=='OperatingCost' then
		--content = content .. lib.generate_solve_function:gsub("osmose_default_model", project.name)
		objective_function = "minimize ObjectiveFunction : Costs_Cost['osmose_default_model_DefaultOpCost']; solve; \n\n"
    
  elseif objective=='InvestmentCost' then
    objective_function = "# Objective function\n minimize ObjectiveFunction : Costs_Cost['osmose_default_model_DefaultInvCost']; solve; \n\n"
    
  elseif objective=='MechanicalPower' then
    objective_function = "# Objective function\n minimize ObjectiveFunction : Costs_Cost['osmose_default_model_DefaultMechPower']; solve; \n\n"
    
  elseif objective=='Impact' then
    objective_function = "# Objective function\n minimize ObjectiveFunction : Costs_Cost['osmose_default_model_DefaultImpact']; solve; \n\n"
    
  elseif objective=='TotalCost' then
    objective_function = "# Objective function\n minimize ObjectiveFunction : Costs_Cost['osmose_default_model_DefaultOpCost'] + Costs_Cost['osmose_default_model_DefaultInvCost']; solve; \n\n"
   
  elseif objective=='OpCostWithImpact' then
    objective_function = "# Objective function\n minimize ObjectiveFunction : Costs_Cost['osmose_default_model_DefaultOpCost'] + Costs_Cost['osmose_default_model_DefaultImpact']; solve; \n\n"
    
  elseif objective=='TotalCostWithPower' then
        objective_function = "# Objective function\n minimize ObjectiveFunction : Costs_Cost['osmose_default_model_DefaultOpCost'] + Costs_Cost['osmose_default_model_DefaultInvCost'] + Costs_Cost['osmose_default_model_DefaultMechPower']; solve; \n\n"
        
  elseif objective=='TotalCostWithImpact' then
        objective_function = "# Objective function\n minimize ObjectiveFunction : Costs_Cost['osmose_default_model_DefaultOpCost'] + Costs_Cost['osmose_default_model_DefaultInvCost'] + Costs_Cost['osmose_default_model_DefaultImpact']; solve; \n\n" 
        
  elseif objective=='TotalCostWithImpactAndPower' then
    objective_function = "# Objective function\n minimize ObjectiveFunction : Costs_Cost['osmose_default_model_DefaultOpCost'] + Costs_Cost['osmose_default_model_DefaultInvCost'] + Costs_Cost['osmose_default_model_DefaultMechPower'] + Costs_Cost['osmose_default_model_DefaultImpact']; solve; \n\n"
    
  elseif objective=='YearlyOperatingCost' then
		objective_function = "# Objective function\n minimize ObjectiveFunction : YearlyOperatingCost; solve;\n\n"
  else
    print("Project Objective is not valid: ", objective)
    os.exit()
	end
  
return objective_function
	
end


return lib