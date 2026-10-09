
## macOS installation

The app bundle is `AetherClash.app`. If Gatekeeper blocks the first launch, run:

```bash
xattr -dr com.apple.quarantine "/Applications/AetherClash.app"
codesign --force --deep --sign - "/Applications/AetherClash.app"
open "/Applications/AetherClash.app"
```

For an older release still installed as `po0-clash.app`, use the same commands with `/Applications/po0-clash.app`.
