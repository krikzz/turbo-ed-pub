# FPGA Examples

| Path | Description |
|---|---|
| `/ed_pro` | Reference FPGA cores for Turbo EverDrive PRO. |
| `/ed_core` | Reference FPGA cores for Turbo EverDrive CORE. |

Both directories contain the same set of example projects and helper scripts.

## FPGA Cores

| Project | Description |
|---|---|
| `/fpga_std` | Reference base mapper implementation. Includes the system layer. |
| `/fpga_se` | Simplified reference mapper implementation without the system layer. |
| `/fpga_mul` | Example of FPGA based hardware multiplication used by `mul-app`. |

## USB Launch Scripts

| Script | Description |
|---|---|
| `run_std.py` | Launch script for `fpga_std`. |
| `run_se.py` | Launch script for `fpga_se`. |
| `run_mul.py` | Launch script for `fpga_mul`. |