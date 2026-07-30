# Per-module simulation for the split rtl/ + tb/ layout.
# Pass the module under test in MOD; its testbench is tb/$(MOD)_tb.sv.
#
#   make MOD=synchronizer         compile rtl/ + that tb, run; a test FAIL exits nonzero
#   make wave MOD=synchronizer    same, then open the waveform in surfer (opens even on FAIL)
#   make formal MOD=uart_rx       run every SymbiYosys task in formal/$(MOD).sby; a FAIL exits nonzero
#   make trace MOD=uart_rx        print a formal counterexample as text
#   make view-formal MOD=uart_rx  open a formal waveform in surfer; error if .vcd missing
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

# Echoes MOD's run directory, prompting when the .sby split into several tasks
define pick_run
	test -n "$(MOD)" || { echo "usage: make $@ MOD=<module>  (e.g. MOD=uart_rx)" >&2; exit 1; }; \
	runs=$$(for d in formal/$(MOD)/ formal/$(MOD)_*/; do [ -f "$$d/status" ] && echo "$${d%/}"; done); \
	[ -n "$$runs" ] || { echo "No runs for $(MOD), try: make formal MOD=$(MOD)" >&2; exit 1; }; \
	if [ $$(echo "$$runs" | wc -l) -eq 1 ]; then echo "$$runs"; else \
	  i=0; for d in $$runs; do i=$$((i+1)); \
	    printf '  %d) %-12s %-6s%s\n' $$i "$$(basename $$d | sed 's/^$(MOD)_//')" \
	      "$$(cut -d' ' -f1 $$d/status)" \
	      "$$(find $$d -name trace.yw 2>/dev/null | head -1 | sed 's/.*/counterexample/')" >&2; \
	  done; \
	  printf 'Select task: ' >&2; read n; \
	  sel=$$(echo "$$runs" | sed -n "$${n}p" 2>/dev/null); \
	  [ -d "$$sel" ] || { echo "No task $$n" >&2; exit 1; }; \
	  echo "$$sel"; fi
endef

trace:
	@dir=$$($(pick_run)); test -n "$$dir" || exit 1; \
	yw=$$(find $$dir -name 'trace.yw' 2>/dev/null | head -1); \
	test -n "$$yw" || { echo "Error: no trace.yw in $$dir/, that run has no counterexample"; exit 1; }; \
	yosys-witness display $$yw

view-formal:
	@dir=$$($(pick_run)); test -n "$$dir" || exit 1; \
	vcd=$$(find $$dir -name '*.vcd' 2>/dev/null | head -1); \
	test -n "$$vcd" || { echo "Error: no .vcd found in $$dir/"; exit 1; }; \
	echo "surfer $$vcd"; \
	surfer $$vcd $$(test -f $$dir.ron && echo "-s $$dir.ron") &

cocotb:
	rm -rf sim_build results.xml
	$(MAKE) -f cocotb.mk

clean:
	rm -rf build *.vcd sim_build results.xml

.DEFAULT_GOAL := run
.PHONY: run wave formal trace view-formal cocotb clean
