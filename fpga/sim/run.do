# Invoked by build.ps1 from fpga/build/sim.
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
vlib work
vmap work work
vlog -work work ../../rtl/efes_top.v ../../sim/efes_top_tb.v
vsim work.efes_top_tb
vcd file efes_top_tb.vcd
vcd add -r /efes_top_tb/*
run 2 us
if {[examine -radix unsigned /efes_top_tb/test_passed] != 1} {
    quit -force -code 1
}
quit -force -code 0
