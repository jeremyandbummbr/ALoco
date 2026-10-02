# ALoco for Mac — route preview

This native Mac design preview of ALoco uses a map-first layout with a floating, translucent dark panel, fine luminous borders, cyan accents, and a compact route playback card. The light Apple map stays visible behind the controls. The treatment is inspired by the liquid-glass feel the user liked in Vanish, while retaining ALoco's own name and Israel-outline logo.

The Mac preview can search start and destination places, calculate an automobile route with MapKit, adjust preview speed, and play a moving car along the route. It displays distance, speed, and ETA. The packaged app is `../ALoco-Mac-Preview.zip`; unzip it and open `ALoco.app`. To rebuild locally with Xcode's command-line tools, run `zsh build-mac.sh` from the `Mac` directory.

This preview does **not** connect to an iPhone or change its location. It is a way to evaluate the desktop layout and route-planning flow before adding a phone handoff. The iPhone app remains the location-simulation engine. The iPhone point-teleport flow now shows a short, Liquid Glass status pill and an animated line/marker after a successful teleport. This is a visual transition; it does not send intermediate GPS positions. The preview's route uses Apple's MapKit service, so searching and routing require internet access.

The archive is ad-hoc signed for local evaluation. It is not a notarized, generally distributable Mac release. The source remains subject to the repository's AGPL-3.0 license and upstream attribution.
