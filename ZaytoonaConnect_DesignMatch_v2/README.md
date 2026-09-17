# ZaytoonaConnect

Fixed standalone iOS SwiftUI project for the Zaytoona / Tahoe ecosystem.

## Connection baseline
- iPhone Personal Hotspot / local network only
- Bonjour service: `_zaytoona._tcp`
- Tahoe receiver default port: `8765`
- Pairing: 6-digit code
- `POST /command` JSON: `{ "key": "123456", "type": "auto", "value": "..." }`

## Build
Open `ZaytoonaConnect.xcodeproj` in Xcode 16.4+ and run the shared `ZaytoonaConnect` scheme.

GitHub Actions builds unsigned with `CODE_SIGNING_ALLOWED=NO` so CI does not need an Apple signing identity.

## What was fixed
- All `foregroundStyle(.zGold)` usages are now `foregroundStyle(Color.zGold)`.
- `Color.zGold` is defined in `Theme.swift`.
- Bonjour and CoreLocation delegate callbacks use `nonisolated` + `Task { @MainActor ... }` to avoid Swift actor-isolation warnings becoming Swift 6 errors.
- App icon asset catalog has a single assigned 1024x1024 iOS icon.
- Local-network, Bonjour, and location usage descriptions are included in `Info.plist`.


## iOS 16 build fixes
- Replaced the iOS 17-only MapCameraPosition/UserAnnotation API with the iOS 16 Map coordinateRegion API.
- Replaced the iOS 17 two-parameter onChange closure with the iOS 16-compatible form.
- Removed ineffective @preconcurrency conformance annotations while keeping delegate callbacks nonisolated.
- Set the app target to iPhone only.
- Generated the complete required iPhone AppIcon sizes.

## Design-match v2
This revision realigns the main iPhone app with the approved Zaytoona visual concept:
- Home dashboard with Zaytoona branding, receiver status, Tahoe hero image, parking timer, phone battery, saved location, Walk to Tahoe and Send ETA actions.
- Find My Tahoe map screen with saved Tahoe pin, walking distance estimate and Tahoe actions.
- Parking screen with active timer, Tahoe imagery, saved position, photo strip and Start/Stop Parking.
- Car Status tab with receiver, last connection, GPS accuracy, iPhone battery, local network and storage status.
- Bottom tabs changed to Home / Car / Trips / Settings.
- Keyboard issue fixed with interactive scroll dismissal plus a visible Done button above the keyboard, including number-pad fields.

The Live Activity / Dynamic Island and Home Screen Widgets shown in the concept are separate iOS extension targets and are intentionally not faked inside the main app target. They can be added as the next build stage.
