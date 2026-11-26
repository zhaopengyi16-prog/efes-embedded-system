"""Use the ADC as a voltmeter to check the 23LC1024 pins one by one.

Move the ADC VIN wire to each SRAM pin when asked, press Enter, and the
script prints the average voltage and whether it looks right. No plot.
Usage:  python tools/probe_pins.py COM8        (normal idle levels)
        python tools/probe_pins.py COM8 h      (wiring test: CS low, SCK high, SI high)
Put the ADC VIN wire back on U1B pin 7 when you are done.
"""
import sys
import serial

PORT = sys.argv[1] if len(sys.argv) > 1 else "COM8"
N = 1024
VREF = 3.3

# (pin, name, expected volts, note)
PINS = [
    (8, "VCC",  3.3, "power"),
    (4, "VSS",  0.0, "ground"),
    (7, "HOLD", 3.3, "must be high, otherwise SO stays off"),
    (3, "SIO2", 3.3, "tied to 3V3"),
    (1, "CS",   3.3, "idle high, driven by FPGA D0"),
    (6, "SCK",  0.0, "idle low, driven by FPGA D1"),
    (5, "SI",   0.0, "idle low, driven by FPGA D5"),
]


def measure(ser):
    ser.reset_input_buffer()
    ser.write(b"c")
    codes = []
    while len(codes) < N:
        line = ser.readline().decode("ascii", "ignore").strip()
        if not line:
            sys.exit(f"Timeout after {len(codes)} samples: check COM port / FPGA image.")
        codes.append(int(line, 16))
    volts = [c * VREF / 4095 for c in codes]
    return sum(volts) / N, max(volts) - min(volts)


HOLD_TEST = len(sys.argv) > 2 and sys.argv[2] == "h"
if HOLD_TEST:
    # 'h' wiring test: FPGA forces CS low, SCK high, SI high
    PINS = [(1, "CS", 0.0, "forced LOW by FPGA D0"),
            (6, "SCK", 3.3, "forced HIGH by FPGA D1"),
            (5, "SI", 3.3, "forced HIGH by FPGA D5")]

results = []
with serial.Serial(PORT, 115200, timeout=3) as ser:
    if HOLD_TEST:
        ser.write(b"h")
        print("sent 'h': SRAM lines held at test levels (send 's' or run adc_scope.py COM8 s to end)")
    for pin, name, exp, note in PINS:
        input(f"\nMove the ADC VIN wire to SRAM pin {pin} ({name}) and press Enter...")
        v, pp = measure(ser)
        ok = abs(v - exp) < 0.3 and pp < 0.3
        flag = "OK" if ok else "<-- CHECK"
        print(f"pin {pin} {name:5s}: {v:.2f} V  (ripple {pp:.2f} V)  expected {exp:.1f} V  {flag}   [{note}]")
        results.append((pin, name, v, exp, ok))

print("\n===== summary =====")
for pin, name, v, exp, ok in results:
    print(f"pin {pin} {name:5s}: {v:.2f} V  expected {exp:.1f} V  {'OK' if ok else '<-- CHECK'}")
print("\nPut the ADC VIN wire back on U1B pin 7.")
