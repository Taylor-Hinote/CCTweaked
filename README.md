# CCTweaked Utilities

This repository contains Lua scripts for use with [CC: Tweaked](https://tweaked.cc/), a Minecraft mod that adds programmable computers and turtles from ComputerCraft.

## Contents

- [Bootloader/](Bootloader/)  
  Contains startup scripts for initializing computers and automatically downloading/updating scripts from GitHub.
- [FunctionStorageRateDisplay/](FunctionStorageRateDisplay/)  
  Displays item storage rates from a Functional Storage controller on a monitor.
- [Mailer/](Mailer/)  
  In-game mail system for sending messages between computers using usernames.

## Projects

### Bootloader

The Bootloader provides a `startup.lua` script that should be installed first on any new ComputerCraft computer.  
**Functionality:**
- Downloads the latest versions of your scripts directly from GitHub using `wget`.
- Ensures your computers always run the most up-to-date code from your repository.
- Now supports a `bootloader.lua` config file: place your desired raw script URL in this file to control what the bootloader downloads and runs.

**Quick Setup:**
Copy and paste this command into your ComputerCraft computer to download and run the bootloader as `startup.lua`:

```
wget run https://raw.githubusercontent.com/Taylor-Hinote/CCTweaked/refs/heads/main/Bootloader/startup.lua startup.lua
```

**Usage:**
1. Place the `startup.lua` from the Bootloader folder onto your computer (or use the command above).
2. On first run, create or edit a file called `bootloader.lua` and paste the raw URL of the script you want to auto-download and run (see below for examples).
3. On boot, the bootloader will fetch and run the script from the URL in `bootloader.lua`.

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

### Mailer

A two-part in-game mail system for CC: Tweaked computers. Allows sending and receiving messages between computers using usernames, with notification sounds and logging.

#### Mailer Client
- Sends and receives mail using usernames (not IDs)
- Plays a notification sound when new mail arrives
- Stores configuration and downloads the notification sound automatically
- Clean, interactive terminal UI

**Install Mailer Client:**
You can use the direct URL below with the bootloader's `bootloader.lua` file, or download directly:
```
https://raw.githubusercontent.com/Taylor-Hinote/CCTweaked/refs/heads/main/Mailer/Client/mail.lua
```
Or, to download manually as `startup.lua` and run immediately:
```
wget run https://raw.githubusercontent.com/Taylor-Hinote/CCTweaked/refs/heads/main/Mailer/Client/mail.lua startup.lua
```

#### Mailer Server
- Listens for mail broadcasts and relays messages to the correct recipient
- Maintains a user map and logs all mail activity
- Clean, real-time terminal UI

**Install Mailer Server:**
You can use the direct URL below with the bootloader's `bootloader.lua` file, or download directly:
```
https://raw.githubusercontent.com/Taylor-Hinote/CCTweaked/refs/heads/main/Mailer/Server/main.lua
```
Or, to download manually as `startup.lua` and run immediately:
```
wget run https://raw.githubusercontent.com/Taylor-Hinote/CCTweaked/refs/heads/main/Mailer/Server/main.lua startup.lua
```

**Usage:**
1. On each client, run `mail.lua` and follow the prompts to register your username.
2. On the server, run `main.lua` to start the mail relay and logging service.
3. To send mail: type `mail @userName "Your message here"` in the client.
4. To test the notification sound: type `soundTest` in the client.

## Requirements

- [CC: Tweaked](https://tweaked.cc/)
- [Functional Storage](https://www.curseforge.com/minecraft/mc-mods/functional-storage) (for the storage controller)
- Internet access in-game for `wget` to function (for Bootloader auto-update)
- Wireless modem attached to all computers using the Mailer

## License

MIT License (add your license here if different)

---

*Created for Minecraft automation with CC: Tweaked.*