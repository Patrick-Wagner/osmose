# equations_p.mod 2126 2010-12-23 14:56:33Z Author:S.Fazlollahi 
# $Id: equations_p.mod 2126 2010-12-23 14:56:33Z S.Fazlollahi $
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# General Equations Layer, to support EI.Equations and EI.EqTerms 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
###It is ok

# Sets
set Equations;
set EqTerms;

# Subsets
set EqTermsOfEquations{Equations} within EqTerms;

set EqTermsOfTime{Time} within EqTerms default {};# It is defined for multi Time!!
set EquationsOfTime{Time} within Equations default {}; # It is defined for multi Time!! 


# Parameters
param Eqs_Sign{e in Equations, t in Time} symbolic in {'<','=<','=','>=','>','!='};
param Eqs_Rht{e in Equations, t in Time};

param EqTs_Coeff{t in EqTerms, t in Time};
param EqTs_Var{q in EqTerms, t in Time} symbolic;



# Constraints
subject to Eqs_solve_l{t in Time,e in EquationsOfTime[t]}:
	sum {q in EqTermsOfEquations[e]:q in EqTermsOfTime[t]} EqTs_Coeff[q,t]*EqTs_Var[q,t]  <= Eqs_Rht[e,t];
