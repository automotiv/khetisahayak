---
description: Manual build process for Android release
---

1. Navigate to the app directory
```bash
cd /Users/ponali.prakash/Documents/practice/khetisahayak/kheti_sahayak_app
```

2. Clean and setup dependencies
```bash
flutter clean && flutter pub get
```

3. Build App Bundle (AAB)
```bash
flutter build appbundle --release
```

4. Build APK (Optional - for local testing)
```bash
flutter build apk --release
```
