import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

@cocotb.test()
async def test_loopback(dut):
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    # Reset
    dut.rst_n.value = 0
    dut.tx_valid.value = 0
    dut.tx_data.value = 0
    dut.rx_serial.value = 1  # UART line idles HIGH
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Start external loopback.
    cocotb.start_soon(serial_loop(dut))

    # Drive a random sequence of bytes and check the loopback
    for i in range(100):
        data = random.getrandbits(8)
        received = await send_byte(dut, data)
        assert received == data, f"received {received:#02x} != sent {data:#02x}"
        assert int(dut.rx_error.value) == 0, f"rx_error = {int(dut.rx_error.value)}"

# Connect serial wires
async def serial_loop(dut):
    while True:
        await RisingEdge(dut.clk)
        dut.rx_serial.value = int(dut.tx_serial.value)

# Send byte
async def send_byte(dut, b):
    while int(dut.tx_ready.value) != 1:
        await RisingEdge(dut.clk)

    dut.tx_data.value = b
    dut.tx_valid.value = 1
    await RisingEdge(dut.clk)
    dut.tx_valid.value = 0

    await RisingEdge(dut.rx_valid)
    return int(dut.rx_data.value)
