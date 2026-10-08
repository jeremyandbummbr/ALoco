# <img src="assets/tlocation-icon.png" width="48" alt="ALoco app icon"> ALoco

![maintained](https://img.shields.io/badge/maintained-yes-44cc11)
![license](https://img.shields.io/badge/License-AGPL--3.0-blue)
![platform](https://img.shields.io/badge/platform-iPhone-lightgrey)
![status](https://img.shields.io/badge/status-prototype-orange)

🇬🇧 English

---

## 🇬🇧 English

ALoco is a clean iPhone location tool for setting one location or simulating a drive along a route.

It has a simple Apple-style interface: connect the device, search for a place, choose Point Teleport or Route Playback, then start. ALoco can keep the simulated location active after the Mac is disconnected, and in testing an already-running drive continued after Wi-Fi was turned off and the phone moved on 5G.

> ⚠️ **Connection note:** ALoco currently needs LocalDevVPN, Wi-Fi, and a valid pairing file to start a new session. Once a drive is already running, it may continue after Wi-Fi is turned off. In our test, starting a brand-new drive on 5G alone failed with error 3.

---

## 📱 iPhone Installation

ALoco is not an App Store app yet. To install it, you build it from Xcode with your own Apple account.

### What You Need

- A Mac with the full Xcode app installed.
- An iPhone with Developer Mode enabled.
- A USB cable for first installation.
- LocalDevVPN installed on the iPhone.
- A private pairing file for that iPhone.

### Step 1: Download The Project

Open Terminal on your Mac:

```sh
git clone https://github.com/jeremyandbummbr/ALoco.git
cd ALoco
open TLocation.xcodeproj
```

This downloads the ALoco source code onto your Mac.

### Step 2: Sign In Xcode

In Xcode:

1. Select the blue project icon.
2. Select the `TLocation` target.
3. Open `Signing & Capabilities`.
4. Choose your Apple Development Team under teams. 
5. If Xcode says the bundle identifier is unavailable, change `local.aloco.prototype` to something unique, such as `com.yourname.aloco`.
6. Select the `ALOCOActivity` target and choose the same team.

### Step 3: Install On iPhone

1. Plug the iPhone into the Mac.
2. Unlock the iPhone.
3. Tap **Trust This Computer** if iOS asks.
4. Select the iPhone as the run destination in Xcode.
5. Press **Run**.

If the iPhone blocks the app, open:

`Settings -> General -> VPN & Device Management`

Then trust your developer profile.

---

## 🔌 First Setup

ALoco needs two things before it can simulate location:

1. LocalDevVPN connected on the iPhone.
2. A converted ALoco pairing file imported into the app.

### LocalDevVPN

Open LocalDevVPN on the iPhone and make sure it says connected. iOS should show the VPN indicator before you connect in ALoco.

### Pairing File

Pairing files are private device credentials. Do not upload them, commit them, or share them. A pairing file only works for the exact iPhone it was created for, so it should not be built into a public download.

#### Easy Setup

After ALoco is installed on the iPhone:

1. Keep the iPhone plugged into the Mac.
2. Unlock the iPhone.
3. Open the `tools` folder in this project.
4. Double-click **ALoco Pairing Setup.command**.
5. Wait until it says **Done**.
6. Open LocalDevVPN on the iPhone and make sure it is connected.
7. Open ALoco and tap **Connect**.

The setup helper finds this iPhone, prepares the pairing file, and puts it directly into ALoco. You do not need to copy commands or manually import the file.

#### Manual Setup

If you already have a raw `pymobiledevice3` remote-pairing file, you can still convert it manually on the Mac:

```sh
python3 tools/convert-pymobiledevice3-pairing.py INPUT.plist OUTPUT.plist
```

Then import the converted `OUTPUT.plist` inside ALoco.

---

## 🧭 How To Use

### Connect

1. Join Wi-Fi on the iPhone.
2. Open LocalDevVPN and confirm it is connected.
3. Open ALoco.
4. Tap **Connect**.

### Point Teleport

Point Teleport sets one exact location.

1. Open **Point** mode.
2. Search for a place, tap the map, or enter coordinates.
3. Check the pin.
4. Tap **Simulate Location**.
5. Open Maps, Find My, Snapchat, or another location app to confirm.
6. Tap **Stop** when finished.

### Route Playback

Route Playback makes the location move along a driving route.

1. Open **Routes** mode.
2. Enter a start location.
3. Enter a destination.
4. Add stops if needed.
5. Choose automatic speed or set a custom speed.
6. Tap **Start Drive**.
7. Watch elapsed time, miles driven, speed, and ETA.
8. Wait for **Done** or tap **Stop**.

When the drive finishes, ALoco keeps the simulated location at the destination until you press Stop.

---

## ✨ Features

- 📍 **Point Teleport:** set one fixed location from search, map tap, or coordinates.
- 🚗 **Route Playback:** simulate a drive along Apple Maps directions.
- 🧩 **Multi-Stop Routes:** move through more than two places in one drive.
- ⚡ **Speed Controls:** use route-estimated speed or set a custom speed.
- 🗺️ **Address Suggestions:** search suggestions while typing locations.
- 📊 **Live Trip Stats:** elapsed time, distance, speed, ETA, and destination.
- 🔔 **Drive Done Notification:** local alert when the route finishes.
- 📱 **Lock Screen Activity:** Live Activity for active location and drive status.
- 🎨 **Apple-Inspired UI:** clean map-first design with liquid-glass style panels.
- 🔒 **Local Device Flow:** pairing and location actions stay local to your setup.

---

## 🛠️ Troubleshooting

### Could Not Simulate Location, Error 3

Try this:

1. Turn Wi-Fi on.
2. Reconnect LocalDevVPN.
3. Wake and unlock the iPhone.
4. Reopen ALoco.
5. Tap **Connect** again.

### Address Search Is Empty

Search and route planning use Apple's MapKit services. The iPhone needs internet access for suggestions and directions.

### The App Expired

Personal Apple development builds expire. Reinstall ALoco from Xcode to refresh signing.

---

## 💻 Mac Preview

ALoco also includes an early native Mac preview in [Mac](Mac). It shows the laptop version of the liquid-glass ALoco interface, including Point and Routes modes.

The Mac preview is visual only. It does not connect to an iPhone or change iPhone location yet.

---

## 🧪 Development

Requirements:

- macOS with full Xcode installed.
- iOS platform support in Xcode.
- A physical iPhone for the main app.

Compile without signing:

```sh
bash build-unsigned.sh
```

Build the Mac preview:

```sh
cd Mac
zsh build-mac.sh
```

The bundled `idevice` static library targets physical iOS devices. Do not assume the main iPhone app links for the simulator.

---

## ⚖️ Legal And License

ALoco is licensed under **AGPL-3.0** because it is based on AGPL-licensed upstream work.

Upstream projects:

- [TLocation](https://github.com/truongkma/t-location)
- [StikDebug](https://github.com/StikDebug/StikDebug)
- [`idevice`](https://github.com/jkcoxson/idevice)

LocalDevVPN is separate and is not embedded in this project.

Use ALoco responsibly. Do not use it to mislead people, bypass consent, violate another app's terms, or create unsafe situations.
