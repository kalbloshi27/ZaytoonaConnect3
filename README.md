# Zaytoona Connect — Design Match v3

This version is a focused UI refinement pass based on the approved Zaytoona/Tahoe concept image.

## What changed
- Custom premium bottom navigation instead of the generic system TabView appearance.
- Home layout tightened to the approved hierarchy: brand, receiver status, Tahoe hero, metrics, saved location, walking/ETA and quick actions.
- "Send to Tahoe" moved out of the main dashboard into the three-dot menu so Home stays visually clean.
- Find My Tahoe rebuilt as a full-screen map with floating receiver controls and a bottom Tahoe card.
- Parking rebuilt around the approved timer + rear Tahoe hero + saved-location + photo-strip layout.
- Car Status rebuilt using the same card spacing, border, typography and green status language as the concept.
- Trips and Settings now use the same visual system rather than looking like generic utility screens.
- Keyboard handling kept: Done button, submit dismissal and interactive scroll dismissal.
- No fake live car-battery data is shown. Unsupported receiver values are clearly marked as not reported.
- iOS 16 compatibility is preserved.
- Local receiver architecture is unchanged: port 8765, Pair Code, Bonjour `_zaytoona._tcp`, local Wi‑Fi/Personal Hotspot only.
- GitHub Actions still builds and uploads `ZaytoonaConnect.ipa`.

## Copy into your Git repository
This ZIP is FLAT: after extraction you should directly see:
- `.github`
- `ZaytoonaConnect`
- `ZaytoonaConnect.xcodeproj`
- `README.md`

Example:

```bat
robocopy "C:\Users\kokoj\Downloads\ZaytoonaConnect_DesignMatch_v3" "C:\Users\kokoj\Downloads\ZaytoonaConnect3" /E
cd /d C:\Users\kokoj\Downloads\ZaytoonaConnect3
git status
git add .
git commit -m "Zaytoona Design Match v3"
git push origin main
```

Then open GitHub Actions and download the `ZaytoonaConnect-IPA` artifact after a successful build.
