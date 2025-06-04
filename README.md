# CCTweaked Utilities

This repository contains Lua scripts for use with [CC: Tweaked](https://tweaked.cc/), a Minecraft mod that adds programmable computers and turtles from ComputerCraft.

## Contents

- [Bootloader/](Bootloader/)  
  Contains startup scripts for initializing computers and automatically downloading/updating scripts from GitHub.

- [FunctionStorageRateDisplay/](FunctionStorageRateDisplay/)  
  Displays item storage rates from a Functional Storage controller on a monitor.

## Projects

### Bootloader

The Bootloader provides a `startup.lua` script that should be installed first on any new ComputerCraft computer.  
**Functionality:**
- Downloads the latest versions of your scripts directly from GitHub using `wget`.
- Ensures your computers always run the most up-to-date code from your repository.

**Quick Setup:**
Copy and paste this command into your ComputerCraft computer to download the bootloader:

```
wget https://raw.githubusercontent.com/Taylor-Hinote/CCTweaked/refs/heads/main/Bootloader/startup.lua startup.lua
```

**Usage:**
1. Place the `startup.lua` from the Bootloader folder onto your computer (or use the command above).
2. On boot, it will automatically fetch and update the required scripts from the provided GitHub raw URLs.

### FunctionStorageRateDisplay

A ComputerCraft program that connects to a Functional Storage controller and a monitor. It displays:

- The current count of each item in storage
- The rate of change (in items per minute) for each item
- Sorting and pagination controls via monitor touch

**Usage:**
1. Place a computer adjacent to a monitor and a Functional Storage controller.
2. Ensure the Bootloader is installed so the latest `main.lua` is downloaded.
3. The script will run automatically after boot, or you can run it manually:
    ```
    lua FunctionStorageRateDisplay/main.lua
    ```
4. Use the monitor to sort and page through items.

## Requirements

- [CC: Tweaked](https://tweaked.cc/)
- [Functional Storage](https://www.curseforge.com/minecraft/mc-mods/functional-storage) (for the storage controller)
- Internet access in-game for `wget` to function (for Bootloader auto-update)

## License

MIT License (add your license here if different)

---

*Created for Minecraft automation with CC: Tweaked.*