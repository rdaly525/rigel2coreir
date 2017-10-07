SRCS = $(wildcard examples/*.lua)
SRCS := $(filter-out examples/harness.lua examples/examplescommon.lua examples/pyramid_core.lua examples/harris_core.lua examples/sift_core.lua examples/sift_core_hw.lua examples/campipe_core.lua examples/descriptor_core.lua  examples/stereo_core.lua examples/stereo_tr_core.lua  examples/lk_core.lua examples/lk_tr_core.lua examples/sift_float.lua,$(SRCS))
# NYI
SRCS_COREIR := $(filter-out examples/pad.lua examples/crop.lua examples/stencil.lua examples/downsample_2.lua examples/downsample_4.lua examples/upsample_2.lua examples/upsample_4.lua, $(SRCS))

COREIR = $(patsubst examples/%.lua,out/%.coreir,$(SRCS_COREIR))

all: $(COREIR)

clean:
	rm out/*

out/%.coreir: examples/%.lua
	../../rigel/rigelLuajit $^

