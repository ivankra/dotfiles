# One launcher per profile in dvim.lua (its `host == "dvim..."` branches)
LAUNCHERS := $(shell grep -o 'host == "dvim[^"]*"' dvim.lua | cut -d'"' -f2)
include ../editors-base/build.mk
