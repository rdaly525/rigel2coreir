SRCS = $(wildcard examples/*.lua)
# NYI
SRCS_COREIR := $(filter-out examples/pad.lua examples/crop.lua examples/stencil.lua examples/downsample_2.lua examples/downsample_4.lua examples/upsample_2.lua examples/upsample_4.lua, $(SRCS))

COREIR = $(patsubst examples/%.lua,out/%.coreir,$(SRCS_COREIR))

all: $(COREIR)

clean:
	rm out/*

out/%.coreir: examples/%.lua
	../../rigel/rigelLuajit $^

