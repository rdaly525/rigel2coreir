local R = require "rigel"
local RM = require "modules"
local ffi = require("ffi")
local types = require("types")
local S = require("systolic")
local harness = require "harness"
local C = require "examplescommon"
require "common".export()

--inp = R.input( types.uint(8) )
--a = R.apply("a", C.plus100(types.uint(8)), inp)
--b = R.apply("b", C.plus100(types.uint(8)), a)
--p200 = RM.lambda( "p200", inp, b )

m = C.plus100(types.uint(8))

coreirmod = coreir.systolic:toCoreIR()

print coreirstr

hsfn = RM.makeHandshake(fn)
