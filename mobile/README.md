# navigatore_burocratico — Mobile

Flutter app (iOS + Android) for the Navigatore Burocratico project.

## Running the app

See the [root README](../README.md) for full setup instructions (backend + Flutter).

Quick reference:

```bash
# Android emulator (tunnels port to host)
adb reverse tcp:8000 tcp:8000
flutter run

# Physical device (replace with your PC's local IP)
flutter run --dart-define=API_BASE_URL=http://<YOUR_PC_IP>:8000
```

## Project structure

```
mobile/lib/
├── core/           # Constants, theme, shared utilities
├── features/
│   ├── auth/       # Login and registration
│   ├── home/       # Procedure list
│   ├── procedure/  # Step-by-step procedure flow
│   └── chat/       # AI assistant
└── main.dart
```
