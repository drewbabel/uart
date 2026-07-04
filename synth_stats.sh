#!/usr/bin/env bash
# Synthesize one module of the UART core for the Basys 3 (Xilinx 7-series) and report resource usage
# Reads the whole rtl/ directory so submodules resolve; the top is the module you name
# Usage: ./synth_stats.sh <top_module>   (e.g. ./synth_stats.sh uart)
set -e
TOP="$1"
test -n "$TOP" || { echo "usage: ./synth_stats.sh <top_module>"; exit 1; }
echo "$TOP (synth_xilinx, 7-series):"
yosys -p "read_verilog -sv rtl/*.sv; synth_xilinx -top $TOP -flatten; stat" 2>/dev/null \
| awk '
    /^=== /                                { lut=0; ff=0; carry=0; io=0 }
    /^[[:space:]]+[0-9]+[[:space:]]+LUT/   { lut  += $1 }
    /^[[:space:]]+[0-9]+[[:space:]]+FD/    { ff   += $1 }
    /^[[:space:]]+[0-9]+[[:space:]]+CARRY/ { carry+= $1 }
    $2 == "IBUF" || $2 == "OBUF"           { io   += $1 }
    END {
      printf "  LUTs:        %d\n", lut+0
      printf "  Flip-flops:  %d\n", ff+0
      printf "  Carry cells: %d\n", carry+0
      printf "  I/O buffers: %d\n", io+0
    }'
