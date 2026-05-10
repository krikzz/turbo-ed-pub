# EDIO Sample

This sample shows how to use Turbo EverDrive PRO/CORE I/O features.

## Features

- Disk access
- USB communication
- Getting the path to the currently loaded ROM
- Access to ROM memory
- System timer
- Base cartridge hardware library implementation in `everdrive.c`

## Scripts

| Path | Description |
|---|---|
| `usbrun.py` | Loads and runs `edio.pce` via USB. |
| `../edio-cmd/usb_txt_rx.py` | Receives a text string from the console via USB. |
| `../edio-cmd/usb_txt_tx.py` | Sends text from `message.txt` via USB for printing on screen. |