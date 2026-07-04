#!/usr/bin/env python3
import glob
import sys
import time

import serial


def find_port():
    ports = sorted(glob.glob("/dev/cu.usbserial-*"))
    uart = [p for p in ports if p.endswith("1")]
    if not uart:
        sys.exit(
            "No FT2232 channel-B (UART) device found. Plug in the board and "
            "check `ls /dev/cu.usbserial-*`"
        )
    return uart[0]


def echo_one(ser, value):
    """Send one byte, return the single echoed byte (or None on timeout)."""
    ser.reset_input_buffer()
    ser.write(bytes([value]))
    ser.flush()
    got = ser.read(1)
    return got[0] if got else None


def main():
    args = [a for a in sys.argv[1:]]
    baud = 115200
    if "--baud" in args:
        i = args.index("--baud")
        baud = int(args[i + 1])
        del args[i : i + 2]
    port = args[0] if args else find_port()

    print(f"port {port}  baud {baud}  8N1")
    ser = serial.Serial(port, baud, bytesize=8, parity="N", stopbits=1, timeout=0.3)
    time.sleep(0.2)          # Let the port settle after open
    ser.reset_input_buffer()

    # Sanity ping first, so a dead link fails loudly before the full sweep
    ping = echo_one(ser, 0xA5)
    if ping is None:
        print("FAIL: no echo for 0xA5 (timeout). Link is not returning bytes")
        print("  Check: board flashed with host_loopback_top, right port, baud")
        print("  If still dead, swap RsRx/RsTx in host_loopback.xdc and re-flash")
        ser.close()
        return 1
    if ping != 0xA5:
        print(f"FAIL: sent 0xA5, echo was 0x{ping:02X} (link up, bytes corrupted)")
        print("  A consistent bit-shift points at baud-divisor mismatch")
        ser.close()
        return 1
    print("ping 0xA5 -> 0xA5 ok")

    # Full sweep of every 8-bit value
    mismatches = []
    timeouts = []
    for v in range(256):
        got = echo_one(ser, v)
        if got is None:
            timeouts.append(v)
        elif got != v:
            mismatches.append((v, got))

    ser.close()

    total = 256
    bad = len(mismatches) + len(timeouts)
    print(f"sweep: {total - bad}/{total} bytes echoed correctly")
    if timeouts:
        print(f"  timeouts ({len(timeouts)}): " +
              ", ".join(f"0x{v:02X}" for v in timeouts[:16]) +
              (" ..." if len(timeouts) > 16 else ""))
    if mismatches:
        print(f"  mismatches ({len(mismatches)}): " +
              ", ".join(f"sent 0x{s:02X} got 0x{g:02X}" for s, g in mismatches[:16]) +
              (" ..." if len(mismatches) > 16 else ""))
    if bad == 0:
        print("PASS: the UART core interoperates with foreign UART peer")
        return 0
    print("FAIL: see mismatches/timeouts above")
    return 1


if __name__ == "__main__":
    sys.exit(main())
