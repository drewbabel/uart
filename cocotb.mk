SIM ?= icarus
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = $(wildcard $(PWD)/rtl/*.sv)
TOPLEVEL = uart
MODULE = test_uart
export PYTHONPATH := $(PWD)/tb:$(PYTHONPATH)
include $(shell cocotb-config --makefiles)/Makefile.sim
