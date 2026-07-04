# Renders loopback_waveform.png (the README waveform) from a simulation CSV, wave.csv
# Regenerate the whole figure from the repo root:
#   iverilog -g2012 -s wave_tb -o wave.vvp rtl/*.sv docs/wave_tb.sv && vvp wave.vvp
#   python3 docs/loopback_waveform.py
import csv
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

rows = list(csv.DictReader(open('wave.csv')))
def _si(s):
    s = s.strip()
    return int(s) if s.lstrip('-').isdigit() else -1  # -1 = unknown (x/z)
def col(n): return [_si(r[n]) for r in rows]
txv, txr, txs = col('tx_valid'), col('tx_ready'), col('tx_serial')
rxv, rxe, rxd = col('rx_valid'), col('rx_error'), col('rx_data')
N = len(rows)

# Window: a few cycles before tx_valid to a few after rx_valid
first_txv = next((i for i, v in enumerate(txv) if v == 1), 0)
rxv_idx = next((i for i, v in enumerate(rxv) if v == 1), N - 1)
a = max(0, first_txv - 6)
b = min(N, rxv_idx + 12)
x = list(range(a, b + 1))

bits = [('tx_valid', txv), ('tx_ready', txr), ('tx_serial', txs),
        ('rx_valid', rxv), ('rx_error', rxe)]
nlanes = len(bits) + 1  # + rx_data bus
lane_h, gap = 0.72, 0.55
pitch = lane_h + gap

fig, ax = plt.subplots(figsize=(13, 0.62 * nlanes + 1.4))
BLUE, RED, GREY = '#2b6cb0', '#c0392b', '#dfe6ee'

def base_of(lane_from_top):
    return (nlanes - 1 - lane_from_top) * pitch

for i, (name, vals) in enumerate(bits):
    base = base_of(i)
    seg = vals[a:b] + [vals[b - 1]]
    ax.axhline(base, color=GREY, lw=0.8, zorder=0)
    ax.step(x, [base + max(v, 0) * lane_h for v in seg], where='post', color=BLUE, lw=1.8, zorder=3)
    ax.text(a - 1.2, base + lane_h / 2, name, ha='right', va='center',
            fontsize=11, family='monospace')

# rx_data as a bus lane (bottom)
base = base_of(nlanes - 1)
top, bot = base + lane_h, base
ax.text(a - 1.2, base + lane_h / 2, 'rx_data', ha='right', va='center',
        fontsize=11, family='monospace')
seg_start = a
for i in range(a + 1, b + 1):
    if i == b or rxd[i] != rxd[i - 1]:
        val = rxd[seg_start]
        ax.plot([seg_start, i], [top, top], color=RED, lw=1.7, zorder=3)
        ax.plot([seg_start, i], [bot, bot], color=RED, lw=1.7, zorder=3)
        ax.plot([seg_start, seg_start], [bot, top], color=RED, lw=1.2, zorder=3)
        if i - seg_start >= 4:
            label = "0x??" if val < 0 else f"0x{val:02X}"
            ax.text((seg_start + i) / 2, base + lane_h / 2, label,
                    ha='center', va='center', fontsize=9.5, family='monospace', color=RED)
        seg_start = i

# Annotate the tx_serial frame fields (start / D0..D7 / stop)
CPB = 32  # Clocks per bit in this scaled demo
ts_base = base_of(2)
start_idx = next((i for i in range(a + 1, b) if txs[i] == 0 and txs[i - 1] == 1), None)
if start_idx is not None:
    fields = ['start', 'D0', 'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'stop']
    for k, lab in enumerate(fields):
        x0 = start_idx + k * CPB
        ax.axvline(x0, color='#b7c4d4', lw=0.7, ls=(0, (3, 3)), zorder=1)
        ax.text(x0 + CPB / 2, ts_base + lane_h + 0.16, lab, ha='center', va='bottom',
                fontsize=7.5, color='#6b7d90', family='monospace')
    ax.axvline(start_idx + 10 * CPB, color='#b7c4d4', lw=0.7, ls=(0, (3, 3)), zorder=1)

ax.set_xlim(a - 7, b + 1)
ax.set_ylim(-0.4, base_of(0) + lane_h + 0.4)
ax.set_yticks([])
ax.set_xlabel('clock cycles', fontsize=10)
xt = list(range(a, b + 1, 8))
ax.set_xticks(xt)
ax.set_xticklabels([str(t - a) for t in xt], fontsize=9)
for s in ('top', 'right', 'left'):
    ax.spines[s].set_visible(False)
ax.set_title('UART Loopback of a Single Frame', fontsize=13, pad=16)
plt.tight_layout()
plt.savefig('loopback_waveform.png', dpi=150, bbox_inches='tight')
print('wrote loopback_waveform.png; window cycles', a, '..', b, 'rx_valid at', rxv_idx)
