# LibroSphere Mobile

## Run

Use `dart-define` values so the app does not depend on hardcoded environment-specific settings:

```bash
flutter run ^
  --dart-define=LIBROSPHERE_API_URL=http://10.0.2.2:8080 ^
  --dart-define=LIBROSPHERE_STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key ^
  --dart-define=LIBROSPHERE_STRIPE_COUNTRY_CODE=US
```

Notes:

- `LIBROSPHERE_API_URL` should point to the API reachable from the current device or emulator.
- `LIBROSPHERE_STRIPE_PUBLISHABLE_KEY` is required for checkout.
- `LIBROSPHERE_STRIPE_COUNTRY_CODE` is optional. If omitted, the app uses the device locale country code when available.
