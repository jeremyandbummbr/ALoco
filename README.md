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

## 📱 Super Simple iPhone Setup

ALoco is not on the App Store yet, so the first install uses Xcode on a Mac. After it is installed, the app runs on the iPhone.

### What You Need

- A Mac with Xcode installed.
- An iPhone plugged into the Mac.
- The iPhone unlocked.
- Developer Mode turned on.
- LocalDevVPN installed on the iPhone.
- Wi-Fi on when starting a new location session.

### Step 1: Download ALoco

On the GitHub page, press the green **Code** button, then press **Download ZIP**.

Open the ZIP file. Then open the ALoco folder.

### Step 2: Open In Xcode

Double-click:

```text
TLocation.xcodeproj
```

Xcode will open the project.

### Step 3: Pick Your iPhone

At the top of Xcode, choose your iPhone as the device.

If Xcode asks you to sign in, sign in with your Apple Account.

### Step 4: Add Your Apple Team

In Xcode:

1. Click the blue project icon.
2. Click **TLocation**.
3. Click **Signing & Capabilities**.
4. Pick your Apple Development Team.
5. Click **ALOCOActivity** and pick the same team.

If Xcode says the app name is already used, change `local.aloco.prototype` to something unique like:

```text
com.yourname.aloco
```

### Step 5: Install The App

Press the big **Run** button in Xcode.

If the iPhone asks whether to trust the computer, tap **Trust**.

If the iPhone blocks ALoco, open this on the iPhone:

```text
Settings → General → VPN & Device Management
```

Tap your developer profile, then tap **Trust**.

### Step 6: Add The Pairing File The Easy Way

Keep the iPhone plugged in and unlocked.

In the ALoco folder, open the `tools` folder.

Double-click:

```text
ALoco Pairing Setup.command
```

Wait until it says **Done**.

That is it. The pairing file is added to ALoco automatically. You do not need to copy commands, rename files, or import anything by hand.

### Step 7: Connect

On the iPhone:

1. Open **LocalDevVPN**.
2. Make sure it says connected.
3. Open **ALoco**.
4. Tap **Connect**.

When ALoco connects, you can use Point Teleport or Route Playback.

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
