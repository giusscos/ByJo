# ByJo app icon variants (Icon Composer, 2026-11-12)

Six `.icon` documents, made for Icon Composer (Xcode 27). Open any of them in Icon Composer
(`Xcode > Open Developer Tool > Icon Composer`) to tweak colors, glass and shadows.
`preview.png` shows each one in Light, Dark, Tinted and Clear, rendered with Icon Composer's `ictool`.

| File | Idea |
|---|---|
| `ByJo-1-Mono.icon` | Today's black-on-white Jo, rebuilt as layered glass. White mark on black in dark and tinted. The safe update. |
| `ByJo-2-Emerald.icon` | White glass Jo on the app's green accent. |
| `ByJo-3-Midnight-Gold.icon` | Deep navy with a gold-coin pupil. Reads premium, matches the Pro upsell. |
| `ByJo-4-Sunset.icon` | Warm orange. Stands out among the green and blue finance icons. |
| `ByJo-5-Rising.icon` | A rising net-worth line that ends in Jo's eye. Says what the app does and keeps the character. |
| `ByJo-6-Bars.icon` | Growing bars topped by Jo's eye, on blue. |

The Jo layers (`j.svg`, `ring.svg`, `pupil.svg`) were traced from the current
`ByJo/Assets.xcassets/AppIcon.appiconset/white.png`, so the letterforms match today's icon.

## Using one

Nothing in the Xcode project points at these yet. To switch:

1. Copy the chosen `.icon` into `ByJo/` and rename it `AppIcon.icon`.
2. Remove `ByJo/Assets.xcassets/AppIcon.appiconset`, so only one `AppIcon` exists.
3. Build, then check the Home Screen in light, dark, tinted and clear.
