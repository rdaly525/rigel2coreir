function initializerCoreIR()
  -- sfs
end

function userModuleFunctions:toCoreIR()
  IR2CoreIR(self.outputNode)
end

--make sure this is only called once
function userModuleFunctions:instanceToCoreIR() 

end


--snode = systollic node
IR2CoreIR = memoize(function (node)
  if node.kind=="select" then
    args = node.inputs
    mux = coreir.insantiate(node.name,"coreir.mux")
    coreir.connect(mux.in0, IR2CoreIR(args[3]))
    coreir.connect(mux.in1, args[2])
    coreir.connect(mux.sel, args[1])
    return mux.out
  end
  if node.kind=="parameter" then
    return .interface(node.name)
  end
end
