"""SRAM self-test read-back check for the EFES FPGA.

Sends 't' (SRAM self-test) and 'c' (capture). The FPGA writes word i ^ 0x5AA5 to
every SRAM address, reads them back, and sends the first 1024 read values (low 12 bits).
Usage:  python tools/sram_check.py COM8
"""
import sys
import serial

PORT = sys.argv[1] if len(sys.argv) > 1 else "COM8"
N = 1024

with serial.Serial(PORT, 115200, timeout=5) as ser:
    ser.reset_input_buffer()
    ser.write(b"t")
    ser.write(b"c")
    got = []
    while len(got) < N:
        line = ser.readline().decode("ascii", "ignore").strip()
        if not line:
            sys.exit(f"Timeout after {len(got)} values: check COM port / FPGA image.")
        got.append(int(line, 16))

exp = [(i ^ 0x5AA5) & 0xFFF for i in range(N)]
ok = sum(g == e for g, e in zip(got, exp))
print(f"matches: {ok} / {N}")
print(" addr  expected  got     expected(bin)    got(bin)")
for i in range(16):
    print(f"{i:5d}   {exp[i]:03X}     {got[i]:03X}    {exp[i]:012b}  {got[i]:012b}")

bad = [i for i in range(N) if got[i] != exp[i]]
if bad:
    print(f"\nmismatches ({len(bad)}):")
    print(" addr  expected  got    diff-bits(xor)")
    for i in bad[:40]:
        x = got[i] ^ exp[i]
        print(f"{i:5d}   {exp[i]:03X}     {got[i]:03X}   {x:012b}  ({bin(x).count('1')} bit)")

vals = set(got)
if ok == N:
    print("-> read-back is correct for these addresses")
elif vals == {0xFFF}:
    print("-> always FFF: SO pin floating/high, or the SRAM is not answering (power, CS, HOLD)")
elif vals == {0x000}:
    print("-> always 000: SO stuck low, or SI/SO swapped")
elif all(((e >> 1) == g) for g, e in zip(got, exp)) or all((((e << 1) & 0xFFF) == g) for g, e in zip(got, exp)):
    print("-> off by one bit: SPI sampling-edge / timing problem")
else:
    print("-> mixed pattern: see the table above")
