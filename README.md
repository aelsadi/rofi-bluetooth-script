# rofi-bluetooth-script
A script that allows bluetooth devices to be displayed and controlled in rofi
[image]
[image]
## Features
- Toggle bluetooth on/off 
- Pair, connect/disconnect and forget devices
- Enable/disable auto-connect on devices
- See currently connected and paired devices
## Dependencies 
- Rofi
- bluez 
- Libnotify
- Nerd fonts (for icons)
## Setup
- Install dependencies  
- ```bash 
    git clone https://github.com/aelsadi/rofi-bluetooth-script.git
    cd rofi-bluetooth-script
    bash "./script.sh"
    ```
- Optional: add to $Path to allow it to be called from anywhere
## Limitations
- No device information (battery, etc.)
