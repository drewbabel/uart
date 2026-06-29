# Per-module simulation for the split rtl/ + tb/ layout.
# Pass the module under test in MOD; its testbench is tb/$(MOD)_tb.sv.
#
#   make MOD=synchronizer         compile rtl/ + that tb, run; a test FAIL exits nonzero
#   make wave MOD=synchronizer    same, then open the waveform in surfer (opens even on FAIL)
#   make clean                    delete build artifacts (build/, *.vcd)

RTL := $(wildcard rtl/*.sv)
TB  := tb/$(MOD)_tb.sv
SIM := build/sim

run:
	@test -n "$(MOD)" || { echo "usage: make MOD=<module>  (e.g. MOD=uart_rx)"; exit 1; }
	@mkdir -p build
	iverilog -g2012 -s $(MOD)_tb -o $(SIM) $(RTL) $(TB)
	vvp $(SIM)

wave:
	@test -n "$(MOD)" || { echo "usage: make wave MOD=<module>"; exit 1; }
	@mkdir -p build
	iverilog -g2012 -s $(MOD)_tb -o $(SIM) $(RTL) $(TB)
	-vvp $(SIM)
	surfer $$(ls *.vcd 2>/dev/null | head -1) &

clean:
	rm -rf build *.vcd

.DEFAULT_GOAL := run
.PHONY: run wave clean
