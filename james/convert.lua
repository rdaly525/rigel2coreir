local J = require "common"
local types = require "types"

function userModuleFunctions:toCoreIR()
  --if self.verilog~=nil then
  --  print("Warn: Module "..self.name.." is defined by verilog!!")
  --  print(self.verilog)
  --end

  local s = {}

  table.insert(s,"Module "..self.name)
  table.insert(s,"Interface:")
  table.insert(s,"  input bool CLK")

  -- Enumerate the module interface
  local CEseen={}
  for fnname,fn in pairs(self.functions) do
    -- our purity analysis isn't smart enough to know whether a valid bit is needed when onlyWire==true.
    -- EG, if we use the valid bit to control clock enables or something. So just do what the user said (include the valid unless it was implicit)
    if fn:isPure()==false or self.onlyWire then 
      if self.onlyWire and fn.implicitValid then
      else table.insert(s,"  input bool "..fn.valid.name) end
    end
    
    if fn.CE~=nil and CEseen[fn.CE.name]==nil then CEseen[fn.CE.name]=1; table.insert(s,"  input bool "..fn.CE.name) end
    
    if fn.inputParameter.type~=types.null() and fn.inputParameter.type:verilogBits()>0 then 
      table.insert(s, "  input "..tostring(fn.inputParameter.type).." "..fn.inputParameter.name)
    end
    
    if fn.output~=nil and fn.output.type~=types.null() and fn.output.type:verilogBits()>0 then 
      table.insert(s,"  output "..tostring(fn.output.type).." "..fn.outputName)  
    end
  end

  table.insert(s,"Definition:")
  -- add the instances
  for k,v in pairs(self.instances) do
    if v.module.kind=="reg" then
      table.insert(s,"  "..v.name.." = instantiate Reg_"..tostring(v.module.type).."_hasCE"..tostring(v.module.hasCE).."_hasValid"..tostring(v.module.hasValid).."_init"..tostring(v.module.initial).."_resetValue"..tostring(v.module.resetValue))
    elseif v.module.kind=="assert" then
      table.insert(s,"  "..v.name.." = instantiate Assert")
    elseif v.module.kind=="print" then
      table.insert(s,"  "..v.name.." = instantiate Print")
    elseif v.module.kind=="ram128" then
      table.insert(s,"  "..v.name.." = instantiate Ram128")
    elseif v.module.kind=="bram2KSDP" then
      table.insert(s,"  "..v.name.." = instantiate BRAM2KSDP")
    elseif v.module.kind=="user" then
      table.insert(s,"  "..v.name.." = instantiate "..v.module.name)
    else
      print("NYI - module type "..v.module.kind)
      assert(false)
    end

  end

  local defn = {}
  local r = CIR(self.ast, defn)
  for k,v in ipairs(defn) do table.insert(s,"  "..v) end

  table.insert(s,"") -- endline
  table.insert(s,"") -- endline

  return table.concat(s,"\n")
end

-- DEADBEEFs
function systolicModuleConstructor:toCoreIR()
  self:complete()
  return self.module:toCoreIR()
end

-- don't bother writing out code for the built-ins
function regModuleFunctions:toCoreIR() return "" end
function fileModuleFunctions:toCoreIR() return "" end
function printModuleFunctions:toCoreIR() return "" end
function assertModuleFunctions:toCoreIR() return "" end
function ram128ModuleFunctions:toCoreIR() return "" end
function bramModuleFunctions:toCoreIR() return "" end

CIR = J.memoize(function (n,defn)
  if n.kind=="call" then
    local fn = n.inst.module.functions[n.fnname]
    if n.inputs[1]~=nil and n.inputs[1].type~=types.null() then table.insert(defn,"wire "..n.inst.name.."."..n.inst.module.functions[n.fnname].inputParameter.name..", "..CIR(n.inputs[1],defn)) end

    -- *** There is something really fishy here, I don't think all the valids are getting wired
    if n.inputs[2]~=nil and n.inputs[2].type~=types.null() and fn.valid~=nil then 
      table.insert(defn,"wire "..n.inst.name.."."..n.inst.module.functions[n.fnname].valid.name..", "..CIR(n.inputs[2],defn)) 
    end
    if n.inputs[3]~=nil and n.inputs[3].type~=types.null()  then table.insert(defn,"wire "..n.inst.name.."."..n.inst.module.functions[n.fnname].CE.name..", "..CIR(n.inputs[3],defn)) end

    if n.inst.module.functions[n.fnname].output~=nil and n.inst.module.functions[n.fnname].output.type~=types.null() then
      return n.inst.name.."."..n.inst.module.functions[n.fnname].outputName
    else
      return "__DEADBEEF_NO_OUTPUT"
    end
  elseif n.kind=="select" then
    table.insert(defn,n.name.." = instantiate Select")
    table.insert(defn,"wire "..n.name..".cond, "..CIR(n.inputs[1],defn))
    table.insert(defn,"wire "..n.name..".iftrue, "..CIR(n.inputs[2],defn))
    table.insert(defn,"wire "..n.name..".iffalse, "..CIR(n.inputs[3],defn))
    return n.name..".out"
  elseif n.kind=="constant" then
    return "Constant("..tostring(n.type)..","..tostring(n.value)..")"
  elseif n.kind=="tuple" then
    local tmp = ""
    for _,v in ipairs(n.inputs) do
      tmp = tmp..CIR(v,defn)..","
    end

    table.insert(defn,n.name.." = concat("..tmp..")")
    return n.name
  elseif n.kind=="slice" then
    table.insert(defn,n.name.." = "..CIR(n.inputs[1],defn).."["..n.idxLow..":"..n.idxHigh.."]["..n.idyLow..":"..n.idyHigh.."] // slice")
    return n.name
  elseif n.kind=="bitSlice" then
    table.insert(defn,n.name.." = "..CIR(n.inputs[1],defn).."["..n.low..":"..n.high.."] // bitslice")
    return n.name
  elseif n.kind=="cast" then
    table.insert(defn,n.name.." = instantiate Cast_"..tostring(n.inputs[1].type).."_to_"..tostring(n.type))
    table.insert(defn,"wire "..n.name..".in, "..CIR(n.inputs[1],defn).." //cast")
    return n.name..".out"
  elseif n.kind=="binop" then
    table.insert(defn,n.name.." = instantiate Binop_"..n.op.."_lhs"..tostring(n.inputs[1].type).."_rhs"..tostring(n.inputs[2].type).."_out"..tostring(n.type))
    table.insert(defn,"wire "..n.name..".lhs, "..CIR(n.inputs[1],defn))
    table.insert(defn,"wire "..n.name..".rhs, "..CIR(n.inputs[2],defn))
    return n.name..".out"
  elseif n.kind=="unary" then
    table.insert(defn,n.name.." = instantiate unary_"..n.op.."_input"..tostring(n.inputs[1].type).."_out"..tostring(n.type))
    table.insert(defn,"wire "..n.name..".in, "..CIR(n.inputs[1],defn))
    return n.name..".out"
  elseif n.kind=="parameter" then
    return n.name
  elseif n.kind=="null" then
    return "__SYSTOLIC_DEADBEEF_NULL"
  elseif n.kind=="fndefn" then
    if n.fn.output~=nil and n.fn.output.type~=types.null() then 
      table.insert(defn,"wire "..n.fn.outputName..", "..CIR(n.inputs[1],defn))
    end
    return "__ERR_DEADBEEF_FNDEFN"
  elseif n.kind=="module" then
    for _,v in pairs(n.inputs) do CIR(v,defn) end
    return "__ERR_DEADBEEF_MODULE"
  else
    print("NYI - CIR "..n.kind)
    assert(false)
  end
end)