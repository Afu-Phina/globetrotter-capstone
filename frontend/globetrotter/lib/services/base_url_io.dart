import 'dart:io';

// Used on Android, iOS, and desktop (anywhere dart:io is available).
// The Android emulator can't see "127.0.0.1" as the host machine -- it
// has its own loopback, so it needs the special alias 10.0.2.2 instead.
// Every other native target (iOS simulator, desktop, physical device on
// the same Wi-Fi via adb reverse) can use 127.0.0.1.
String resolveBaseUrl() {
  if (Platform.isAndroid) return 'http://172.20.10.3:5000/api';
  return 'http://172.20.10.3:5000/api';
}
