package = "osmose"
version = "0.1-3"
source = {
   url = "https://github.com/ipese/osmose",
}
description = {
   summary = "OSMOSE : A tool for the design and analysis of integrated energy systems",
   detailed = [[
      OSMOSE is a tool for the design and the analysis of integrated energy systems.

      The goal of the OSMOSE platform is to enable the integration of flowsheeting tools, process integration and costing tools to realise the study of integrated energy conversion systems.

      One of the major goal of OSMOSE is to allow the integration of different models and to organise the process design methods using process integration techniques and multi-objective thermo-economic optimisation techniques.
   ]],
   homepage = "https://github.com/ipese/osmose",
   license = "proprietary"
}
dependencies = {
   "lua >= 5.1, < 5.3",
   "lub >= 1.0.3, < 1.1",
}
build = {
   type = "builtin",
   modules = {
      ['osmose'] = "lib/osmose.lua",
      ['osmose.Eiampl'] = "lib/osmose/Eiampl.lua",
      ['osmose.Glpk'] = "lib/osmose/Glpk.lua",
      ['osmose.Graph'] = "lib/osmose/Graph.lua",
      ['osmose.Layer'] = "lib/osmose/Layer.lua",
      ['osmose.QTStream'] = "lib/osmose/QTStream.lua",
      ['osmose.HTStream'] = "lib/osmose/HTStream.lua",
      ['osmose.MassStream'] = "lib/osmose/MassStream.lua",
      ['osmose.Model'] = "lib/osmose/Model.lua",
      ['osmose.Project'] = "lib/osmose/Project.lua",
      ['osmose.Unit'] = "lib/osmose/Unit.lua",

      ['osmose.helpers.eiamplHelper'] = "lib/osmose/helpers/EiamplHelper.lua",
      ['osmose.helpers.glpkHelper'] = "lib/osmose/helpers/glpkHelper.lua",
      ['osmose.helpers.gnuplotHelper'] = "lib/osmose/helpers/gnuplotHelper.lua",
      ['osmose.helpers.modelHelper'] = "lib/osmose/helpers/modelHelper.lua",
      ['osmose.helpers.projectHelper'] = "lib/osmose/helpers/projectHelper.lua",

      ['osmose.eiampl.vendor.lustache'] = "lib/osmose/eiampl/vendor/lustache.lua",

      ['lustache.context'] = "lib/osmose/eiampl/vendor/lustache/context.lua",
      ['lustache.scanner'] = "lib/osmose/eiampl/vendor/lustache/scanner.lua",
      ['lustache.renderer'] = "lib/osmose/eiampl/vendor/lustache/renderer.lua",

      ['ET.Cip'] = "ET/Cip.lua",
      ['ET.CookingMixing'] = "ET/CookingMixing.lua",
      ['ET.generic_utilities'] = "ET/generic_utilities.lua",

      ['physical'] = "lib/physical.lua",
      ['physical.Unit'] = "lib/physical/Unit.lua",
   },

   install = {
      lua = {
         ['osmose.templates.glpkWithTimes_mustache'] = 'lib/osmose/templates/glpkWithTimes.mustache',
         ['osmose.templates.mea_mustache'] = 'lib/osmose/templates/mea.mustache',
         ['osmose.templates.vif_mustache'] = 'lib/osmose/templates/vif.mustache',

         ['osmose.eiampl.mod.eiampl_p_mod'] = 'lib/osmose/eiampl/mod/eiampl_p.mod',
         ['osmose.eiampl.mod.costing_p_mod'] = 'lib/osmose/eiampl/mod/costing_p.mod',
         ['osmose.eiampl.mod.heat_cascade_no_restrictions_p_mod'] = 'lib/osmose/eiampl/mod/heat_cascade_no_restrictions_p.mod',
         ['osmose.eiampl.mod.heat_cascade_base_glpsol_p_mod'] = 'lib/osmose/eiampl/mod/heat_cascade_base_glpsol_p.mod',
         ['osmose.eiampl.mod."mass_p_mod'] = 'lib/osmose/eiampl/mod/mass_p.mod',
         ['osmose.eiampl.mod.costing_postSolve_p_mod'] = 'lib/osmose/eiampl/mod/costing_postSolve_p.mod',
         ['osmose.eiampl.mod.heat_cascade_base_postSolve_p_mod'] = 'lib/osmose/eiampl/mod/heat_cascade_base_postSolve_p.mod',
         ['osmose.eiampl.mod.mass_postSolve_p_mod'] = 'lib/osmose/eiampl/mod/mass_postSolve_p.mod',
         ['physical.conversion_txt'] = 'lib/physical/conversion.txt',

      }
   },

}