# iPhone 16 Pro / iOS 26.0 validation

Tested September 26–27, 2026, on iPhone 16 Pro, iOS 26.0 (23A340), with Xcode 27.0 and a Personal Team development signature. Never put a pairing file, private key, Apple password, or full unsanitized device log in this document.

| Test | Procedure | Expected observation | Result |
|---|---|---|---|
| First build | Build with the physical iPhone selected | Successful compile, link, sign, and launch | Passed |
| Setup | View guide, continue, import pairing, enable helper | Connection screen reflects actual readiness | Passed after converting the pairing record to idevice format |
| Foreground simulation | Select Apple Park and start | Other apps report the selected location | Passed in ALoco and Find My; Apple Maps not checked yet |
| Unplug | Disconnect USB while simulation is active | Selected location remains | Passed for several minutes in Find My and Snapchat, without reported errors |
| Second session | Stop and start a different location while unplugged | New selected location appears without reconnecting the Mac | Passed per owner at 11:12 a.m. |
| Computer independence | Shut down the Mac and change location on phone | New selected location appears in Apple Maps | Pending |
| Background | Switch to Maps for 5 minutes | Location remains; record any resets | Pending |
| Screen lock | Lock for 1, 5, and 15 minutes, then inspect Maps | Record persistence and battery change | Pending |
| Network transition | Start a short return drive, then turn off Wi-Fi | Record connection state and actual reported location | Passed per owner's direct observation: the drive continued on 5G and Find My moved along the route. At arrival the simulated location stayed at the destination, as intended. Mirroring disconnected, so this portion could not be independently watched from the Mac. |
| Cellular start | After a completed drive, attempt a new session on 5G | Record whether supported; do not infer from prior persistence | Failed per owner: the app opened, but Start Drive returned “Could not simulate location (error 3).” A USB screenshot with Wi-Fi off separately showed Connect unavailable and LocalDevVPN guidance. The previous simulated destination remained in effect at arrival. |
| Helper interruption | Disable LocalDevVPN | UI must not be taken as proof of continued simulation; record observed behavior | Pending |
| Restore | Tap Stop, check another location app | Real location resumes after a fresh fix | Passed per owner before the second session |
| Drive route | Plan an automobile route and tap Start Drive | Position advances along the road; elapsed, distance, speed, and ETA update | Passed in ALoco; 1.03 mi route reached Arrived in 2:04 at 30 mph |
| South Mercer Island QFC drive | Search for 8421 SE 68th St, preview, and start | Preview selects the south store and Find My position advances toward it | Passed September 26: 4.43 mi in 8:53; Find My showed the destination area, and Stop restored the real location. |
| Mercer Island church drive | Search Mercer Island United Methodist Church, 7070 SE 24th St; drive there and preview a return to 62nd Ave SE & SE 24th St | Short local route advances and Find My reflects the destination | Outbound passed September 27: ALoco reported Done after 0.38 mi in 00:46 at 30 mph; Find My displayed the church address. Return started and advanced 0.07 mi before Wi-Fi was switched off; further LTE observation was interrupted by Mirroring disconnect. |
| Repeat after September 27 build | Install revised app; start a new Wi-Fi drive to the same church; check Find My and restore | Branding appears, route reaches the church, and real location returns after clearing | Passed: branded ALoco launch appeared promptly; route finished at 0.38 mi in 00:46; Find My showed 7070 SE 24th St. After clearing the simulated location, Find My refreshed back to the real location. The return leg was not repeated in this second run because iPhone Mirroring switched text input to another keyboard layout during destination entry; no unintended destination was simulated. |
| Launch animation | Cold launch ALoco on Wi-Fi and with Wi-Fi off | Branded outline and name appear promptly, without a stuck white screen | After the launch-screen change, the outline animation appeared on Wi-Fi. A USB screenshot with Wi-Fi off showed the connection card, rather than a white screen. The full animation timing without Wi-Fi was not observed. |
| Drive in Find My | Open Find My at route arrival | Find My shows the simulated destination area | Passed |
| Drive Stop | Tap Stop in ALoco, reopen Find My | Find My returns to the phone's real location | Passed |
| Branding | Search installed apps on iPhone | ALoco name and blue outline icon appear | Passed |
| New controls | Open Settings and Point Teleport | Close button dismisses Settings; exact coordinate form validates input | Pending device UI check |
| Multi-stop and suggestions | Add a stop, type a partial address, choose suggestion | Suggested address fills field; route includes each stop | Pending device UI check |
| Completion notice | Finish a drive | Card says Done and authorized device receives “Drive done.” | Pending device UI check |
| Live Activity | Start location and drive, then lock screen | Location/drive status appears on Lock Screen and Dynamic Island | Pending device UI check |
| Automatic speed | Route with local and highway steps | Estimates switch 30/60 mph based on MapKit instructions | Pending device route check; not posted limits |
| Relaunch/reboot | Reopen app and separately reboot phone | Record actual state and recovery steps | Pending |
| Invalid pairing | Attempt import of a harmless invalid file | Clear error; no false ready state | Pending |

Do the first tests in a stationary location where real and test coordinates are easy to distinguish. Stop simulation before using navigation. Do not regard a successful Maps test as proof that all other apps behave identically.
