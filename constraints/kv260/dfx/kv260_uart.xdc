# ============================================================
# KV260 J2 PMOD UART
#
# J2 pin 1 / FPGA H12: UART TX từ KV260
# J2 pin 2 / FPGA E10: UART RX vào KV260
# ============================================================

set_property PACKAGE_PIN H12 [get_ports uart_tx_o]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx_o]
set_property DRIVE 4 [get_ports uart_tx_o]
set_property SLEW SLOW [get_ports uart_tx_o]

set_property PACKAGE_PIN E10 [get_ports uart_rx_i]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx_i]