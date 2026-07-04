# Per-module simulation for the split rtl/ + tb/ layout.
# Pass the module under test in MOD; its testbench is tb/$(MOD)_tb.sv.
#
#   make MOD=synchronizer         compile rtl/ + that tb, run; a test FAIL exits nonzero
#   make wave MOD=synchronizer    same, then open the waveform in surfer (opens even on FAIL)
#   make formal MOD=uart_rx       run every SymbiYosys task in formal/$(MOD).sby; a FAIL exits nonzero
#   make cocotb                   run the Python top-level testbench (tb/test_uart.py) on the UART core
#   make clean                    delete build artifacts (build/, *.vcd)

RTL := $(wildcard rtl/*.sv)
TB  := tb/$(MOD)_tb.sv
SIM := build/sim
WAVE_STATE := tb/$(MOD).ron
FORMAL := formal/$(MOD).sby

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
	surfer $$(ls *.vcd 2>/dev/null | head -1) $$(test -f $(WAVE_STATE) && echo "-s $(WAVE_STATE)") &

formal:
	@test -n "$(MOD)" || { echo "usage: make formal MOD=<module>  (e.g. MOD=uart_rx)"; exit 1; }
	sby -f $(FORMAL)

cocotb:
	rm -rf sim_build results.xml
	$(MAKE) -f cocotb.mk

clean:
	rm -rf build *.vcd sim_build results.xml

.DEFAULT_GOAL := run
.PHONY: run wave formal cocotb clean
