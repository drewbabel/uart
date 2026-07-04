#   make test    compile + run all demo testbenches; a FAIL exits nonzero
#   make wave T=<seven_seg|debounce|basys3_top>   run that TB + open its waveform
#   make clean   delete build artifacts
#
# Each demo module lives in its own folder (module + tb + waveform layout).

RTL := $(wildcard ../../rtl/*.sv)

test: seven_seg debounce basys3_top

seven_seg:
	@mkdir -p build
	iverilog -g2012 -s seven_seg_cntrl_tb -o build/seven_seg seven_seg/seven_seg_cntrl.sv seven_seg/seven_seg_cntrl_tb.sv
	vvp build/seven_seg

debounce:
	@mkdir -p build
	iverilog -g2012 -s debounce_counter_tb -o build/debounce debounce/debounce_counter.sv debounce/debounce_counter_tb.sv
	vvp build/debounce

basys3_top:
	@mkdir -p build
	iverilog -g2012 -s basys3_top_tb -o build/basys3_top $(RTL) seven_seg/seven_seg_cntrl.sv debounce/debounce_counter.sv basys3_top/basys3_top.sv basys3_top/basys3_top_tb.sv
	vvp build/basys3_top

wave:
	@test -n "$(T)" || { echo "usage: make wave T=<seven_seg|debounce|basys3_top>"; exit 1; }
	$(MAKE) $(T)
	surfer tb.vcd $$(test -f $(T)/$(T).ron && echo "-s $(T)/$(T).ron") &

clean:
	rm -rf build *.vcd

.PHONY: test seven_seg debounce basys3_top wave clean
