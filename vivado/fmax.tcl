# README fmax repro
# usage vivado -mode batch -source vivado/fmax.tcl -tclargs <harness> <clk> [clk2]
# same harnesses as fmax.sh
# one loose pass understates fmax
# two clocks declared async

set root    [file normalize [file join [file dirname [info script]] ..]]
set harness [lindex $argv 0]
set clks    [lrange $argv 1 end]
set part    xc7a35tcpg236-1
set outdir  [file join $root vivado build $harness]
file mkdir $outdir

proc apply_clocks {periods} {
  foreach c [dict keys $periods] {
    set p [dict get $periods $c]
    if {[llength [get_clocks -quiet $c]]} {
      set_property PERIOD $p [get_clocks $c]
    } else {
      create_clock -name $c -period $p [get_ports $c]
    }
  }
  if {[llength [dict keys $periods]] > 1} {
    set groups {}
    foreach c [dict keys $periods] { lappend groups -group [get_clocks $c] }
    set_clock_groups -asynchronous {*}$groups
  }
}

proc implement {periods} {
  apply_clocks $periods
  opt_design -quiet
  place_design -quiet
  phys_opt_design -quiet
  route_design -quiet
}

# intra-domain slack only
proc slack_per_clock {clks} {
  set d {}
  foreach c $clks {
    set p [get_timing_paths -quiet -from [get_clocks $c] -to [get_clocks $c] \
                            -delay_type max -max_paths 1]
    if {[llength $p]} {
      dict set d $c [get_property SLACK $p]
    } else {
      dict set d $c 0.0
    }
  }
  return $d
}

set pkgs {}
set rest {}
foreach f [lsort [glob [file join $root rtl *.sv]]] {
  if {[string match *_pkg [file rootname [file tail $f]]]} { lappend pkgs $f } else { lappend rest $f }
}
if {[llength $pkgs]} { read_verilog -sv $pkgs }
read_verilog -sv $rest
read_verilog -sv [file join $root fmax $harness.sv]

synth_design -top $harness -part $part -flatten_hierarchy full
write_checkpoint -force [file join $outdir post_synth.dcp]

# pass 1 aggressive
set periods {}
foreach c $clks { dict set periods $c 2.0 }
implement $periods
set s1 [slack_per_clock $clks]

# pass 2 reachable period
set periods2 {}
foreach c $clks {
  dict set periods2 $c [expr {2.0 - [dict get $s1 $c]}]
}
open_checkpoint [file join $outdir post_synth.dcp]
implement $periods2
set s2 [slack_per_clock $clks]

report_utilization    -file [file join $outdir utilization.rpt]
report_timing_summary -file [file join $outdir timing_summary.rpt]
write_checkpoint -force [file join $outdir ${harness}_routed.dcp]

proc count_cells {pattern} {
  if {[catch {llength [get_cells -hier -quiet -filter "REF_NAME =~ $pattern"]} n]} { return -1 }
  return $n
}

set fh [open [file join $outdir fmax.txt] w]
puts $fh "harness $harness"
foreach c $clks {
  set p [dict get $periods2 $c]
  set s [dict get $s2 $c]
  set f [expr {1000.0 / ($p - $s)}]
  puts $fh [format "fmax %s %.1f MHz (target %.3f ns, slack %.3f ns)" $c $f $p $s]
  puts     [format "RESULT %s %s %.1f MHz" $harness $c $f]
}
puts $fh [format "luts %d"       [count_cells "LUT*"]]
puts $fh [format "flipflops %d"  [count_cells "FD*"]]
puts $fh [format "block_rams %d" [count_cells "RAMB*"]]
close $fh
puts "RESULT $harness done"
