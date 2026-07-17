#!/usr/bin/env bash
# Fmax and utilization
# Usage ./fmax.sh <module> <harness> <clock> [clock]
set -e

MOD="$1"; HARNESS="$2"; shift 2
CLKS="$*"
CHIPDB="$HOME/Documents/code/nextpnr-xilinx/xilinx/xc7a35t.bin"
mkdir -p build

# Module utilization
sv2v rtl/*.sv > build/util_$MOD.v
yosys -p "read_verilog build/util_$MOD.v; synth_xilinx -top $MOD -flatten; stat" 2>/dev/null \
  | awk '
    /^=== /                                  { lut = 0; ff = 0; bram = 0; dram = 0 }
    /^[[:space:]]+[0-9]+[[:space:]]+LUT/     { lut  += $1 }
    /^[[:space:]]+[0-9]+[[:space:]]+FD/      { ff   += $1 }
    /^[[:space:]]+[0-9]+[[:space:]]+RAMB/    { bram += $1 }
    /^[[:space:]]+[0-9]+[[:space:]]+RAM[0-9]/ { dram += $1 }
    END { printf "util %d %d %d %d\n", lut+0, ff+0, bram+0, dram+0 }' > build/util_$MOD.txt

# Route the harness
sv2v rtl/*.sv fmax/$HARNESS.sv > build/fmax_$HARNESS.v
yosys -q -p "read_verilog build/fmax_$HARNESS.v; synth_xilinx -top $HARNESS -flatten; write_json build/fmax_$HARNESS.json" 2>/dev/null

# Pin pool
CLKPINS=(W5 V17 V16)
IOPINS=(W16 W17 W15 V15 W14 W13 U16 E19 U19 V19)
XDC=build/fmax_$HARNESS.xdc
: > $XDC
ci=0; ii=0
for p in $(python3 - "build/fmax_$HARNESS.json" "$HARNESS" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
ports = d["modules"][sys.argv[2]]["ports"]
print(" ".join(ports.keys()))
PY
); do
  if echo " $CLKS " | grep -q " $p "; then pin=${CLKPINS[$ci]}; ci=$((ci+1)); else pin=${IOPINS[$ii]}; ii=$((ii+1)); fi
  echo "set_property PACKAGE_PIN $pin [get_ports $p]" >> $XDC
  echo "set_property IOSTANDARD LVCMOS33 [get_ports $p]" >> $XDC
done

nextpnr-xilinx --chipdb "$CHIPDB" --xdc $XDC --json build/fmax_$HARNESS.json \
  --fasm build/fmax_$HARNESS.fasm --router router2 2>build/fmax_$HARNESS.log || true

read lut ff bram dram < <(awk '{print $2, $3, $4, $5}' build/util_$MOD.txt)
echo "=== $MOD ==="
echo "  LUTs $lut  Flip-flops $ff  Block RAMs $bram  Distributed RAM $dram"
# Fmax per clock
grep -iE "Max frequency for clock" build/fmax_$HARNESS.log \
  | sed -E "s/.*clock '([^']+)': ([0-9.]+) MHz.*/\1 \2/" \
  | awk '{ f[$1] = $2 } END { for (c in f) printf "  Fmax %-14s %s MHz\n", c, f[c] }'
