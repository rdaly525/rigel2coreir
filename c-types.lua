local ffi = require('ffi')

local function read_file(file)
  local f = assert(io.open(file, "r"), "Could not open " .. file .. " for reading")
  local content = f:read("*a")
  f:close()
   return content
end

local function to_c_str(s)
  return ffi.new("char[?]", #s+1, s)
end

ffi.cdef(read_file("../../include/coreir-c/coreir-single.h"))

ffi.load("../../lib/libcoreir.dylib")
C = ffi.load("../../lib/libcoreir-c.dylib")

ctx = C.CORENewContext()
global = C.COREGetGlobal(ctx)

ns_core = C.COREGetNamespace(ctx,to_c_str("coreir"))



----------
keys = ffi.new("char*[?]", 3)
keys[0] = to_c_str("in0")
keys[1] = to_c_str("in1")
keys[2] = to_c_str("out")

local vals = ffi.new("COREType*[?]", 3)
vals[0] = C.COREBitIn(ctx)
vals[1] = C.COREBitIn(ctx)
vals[2] = C.COREBit(ctx)

recparams = C.CORENewMap(ctx,keys,vals,3,C.STR2TYPE_ORDEREDMAP)
addwrap_type = C.CORERecord(ctx,recparams)

C.COREPrintType(addwrap_type)
----------------

addwrap = C.CORENewModule(global,to_c_str("andwrap"),addwrap_type,nil);
addwrap_def = C.COREModuleNewDef(addwrap)
C.COREModuleSetDef(addwrap,addwrap_def)


------------
Add = C.CORENamespaceGetGenerator(ns_core,"and");

addkeys = ffi.new("char*[?]", 1)
addkeys[0] = to_c_str("width")

local addvals = ffi.new("COREArg*[?]", 1)
addvals[0] = C.COREArgInt(ctx,1)

addparams = C.CORENewMap(ctx,addkeys,addvals,1,C.STR2ARG_MAP)

emptyparams = C.CORENewMap(ctx,addkeys,addvals,0,C.STR2ARG_MAP)
addinst = C.COREModuleDefAddGeneratorInstance(addwrap_def,to_c_str("adder"),Add,addparams,emptyparams)
-------------
interface = C.COREModuleDefGetInterface(addwrap_def)

in0 = C.COREWireableSelect(interface,to_c_str("in0"))
add_in0 = C.COREWireableSelect(addinst,to_c_str("in0"))
C.COREModuleDefConnect(addwrap_def,in0,add_in0)
-------------
un = C.JHUnary(ctx)
print("A")
linebufferdecl = C.CORENewGeneratorDecl(global,to_c_str("linebuffer"),un,emptyparams, emptyparams)
print("B")
------------
C.COREPrintModule(addwrap)

local err = ffi.new("COREBool[1]")
print("HERE")
C.CORESaveModule(addwrap,to_c_str("addwrap.json"),err)