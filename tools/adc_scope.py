"""Poor man's oscilloscope for the EFES FPGA.

Sends 'c' to the FPGA, receives 1024 ADC samples (20 kS/s, 12 bit) and plots them.
Usage:  python tools/adc_scope.py COM8
Needs:  pip install pyserial matplotlib
"""
import sys
import serial
import matplotlib.pyplot as plt

PORT = sys.argv[1] if len(sys.argv) > 1 else "COM8"
FS = 20000          # sample rate in Hz
N = 1024            # samples per capture
VREF = 3.3

with serial.Serial(PORT, 115200, timeout=3) as ser:
    ser.reset_input_buffer()
    ser.write(b"c")
    codes = []
    while len(codes) < N:
        line = ser.readline().decode("ascii", "ignore").strip()
        if not line:
            sys.exit(f"Timeout after {len(codes)} samples: check the COM port and the FPGA image.")
        codes.append(int(line, 16))

volts = [c * VREF / 4095 for c in codes]
t_ms = [i * 1000 / FS for i in range(N)]

mean = sum(codes) / N
crossings = sum(1 for a, b in zip(codes, codes[1:]) if a < mean <= b)
freq = crossings / (N / FS)
print(f"min {min(codes)}  max {max(codes)}  mean {mean:.0f} (codes)")
print(f"min {min(volts):.3f} V  max {max(volts):.3f} V  peak-to-peak {max(volts) - min(volts):.3f} V")
print(f"estimated frequency: {freq:.0f} Hz")

plt.plot(t_ms, volts, ".-", markersize=3)
plt.xlabel("time [ms]")
plt.ylabel("ADC input [V]")
plt.title(f"ADC capture, {N} samples at {FS // 1000} kS/s, f ≈ {freq:.0f} Hz")
plt.grid(True)
plt.show()
