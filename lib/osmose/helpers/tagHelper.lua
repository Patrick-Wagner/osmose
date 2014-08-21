local lub = require 'lub'
local lib = {}

-- Look for the value of the tag
function lib.initTag(self, tag, temp) 
  -- If the tag is a Temperature (temp=='T') then we add 273 automatically, 0 otherwise.
  local delta = 0
  if temp=='T' then
    delta = 273
  elseif temp=='Tcorr' then
    delta = 273.0001
  end

  -- iniTag return a function that depend of the model.
  local fct = function(model)
    local value = 0
    if type(self[tag]) == 'string' then
      local res = model[self[tag]]
      if type(res) == 'function' then
        value = res()
      else
        value = res
      end
    elseif type(self[tag]) == 'number' then
      value = self[tag]
    elseif self[tag] then
      value = self[tag](model)
    else
      return nil
    end
    if type(value) == 'table' then
      value = value[1][1]
    end
    return value + delta
  end

  return fct
end


return lib