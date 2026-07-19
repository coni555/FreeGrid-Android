# Android Environment

## Installed

- Flutter: `/opt/homebrew/bin/flutter`
- Dart: `/opt/homebrew/bin/dart`
- Android SDK: `/Users/coni/Library/Android/sdk`
- Android platform-tools: `/Users/coni/Library/Android/sdk/platform-tools`
- Android cmdline-tools: installed into SDK via `cmdline-tools;latest`
- NDK: installed on first debug build at `/Users/coni/Library/Android/sdk/ndk/28.2.13676358`
- CMake: installed on first debug build at `/Users/coni/Library/Android/sdk/cmake/3.22.1`
- Android system image: `system-images;android-36;google_apis;arm64-v8a`
- Android emulator: `FreeGrid_Pixel_7_API_36`
- JDK for Flutter: `/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home`

## Useful Environment

```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
export PATH="/opt/homebrew/opt/openjdk@21/bin:$HOME/Library/Android/sdk/platform-tools:$PATH"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
```

Flutter has also been configured directly:

```bash
flutter config --android-sdk "$HOME/Library/Android/sdk"
flutter config --jdk-dir "/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
```

## Notes

- Homebrew `temurin` cask could not be installed because it requires sudo/password through the macOS installer. Homebrew `openjdk@21` was used instead.
- Homebrew `openjdk` 26 was installed first, but Flutter warned it may be too new for the generated Gradle setup. Use JDK 21 for this project.
- CocoaPods is not installed. Ignore that for now because this project is Android only.

## Emulator

Start the Android emulator:

```bash
emulator -avd FreeGrid_Pixel_7_API_36 -no-snapshot-save
```

Run FreeGrid on it:

```bash
flutter run -d emulator-5554
```

The first boot may be slow. If Flutter does not see it yet, wait for:

```bash
adb shell getprop sys.boot_completed
```

Expected value: `1`.
