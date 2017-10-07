local convert = require "convert"

return function(tab)
  io.output("out/"..tab.outFile..".coreir")
  io.write(tab.fn.systolicModule:getDependencies("toCoreIR"))
  io.write(tab.fn.systolicModule:toCoreIR())
  io.close()
end