# DE1-SoC oscillator: nominal 50 MHz, one 20 ns clock domain.
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
derive_clock_uncertainty

# KEY0_N is an asynchronous reset, released by the reset synchronizer.
set_false_path -from [get_ports {KEY0_N}]

# The LED has no external synchronous receiver or capture-clock requirement.
# Do not reuse this exception for future UART/ADC/DAC interfaces.
set_false_path -to [get_ports {LEDR0}]
