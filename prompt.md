# SoundShare Flutter App: Complete Production UI, UX, Animation & Functionality

Build a production-ready Flutter Android application called **SoundShare**.

The app allows a user who is listening to audio through their Bluetooth earbuds/headphones to connect additional compatible Bluetooth audio devices and share the same audio.

The provided UI reference image is the **visual source of truth**. Recreate the same visual language, layout, spacing, gradients, typography, icons, animations, and interaction states as closely as possible.

This must be a real application, not a static UI prototype.

---

# 1. BRAND

App name:

**SoundShare**

Primary tagline:

**Connect multiple devices**

Primary user action:

**Share Audio**

Core idea:

> One audio source, multiple listening devices.

The interface should make this understandable immediately.

Do not use "Listen together" as the primary tagline.

Use:

**Connect multiple devices**

---

# 2. IMPORTANT: LOGO FILE IS PROVIDED

A SoundShare app logo file has been added to the **project root directory**.

Use that provided logo throughout the application.

Do NOT:

* Generate a replacement logo
* Redesign the logo
* Use an emoji
* Create a different logo
* Use a generic music icon as the brand logo

First inspect the project root and identify the provided SoundShare logo asset.

Add it correctly to `pubspec.yaml` under Flutter assets.

Use the same logo consistently for:

* Splash screen
* App branding
* Main screen
* App icon preparation if appropriate
* Any branded loading state

Maintain the logo's original proportions.

Do not stretch it.

Use `BoxFit.contain`.

If the provided logo already contains the gradient/background, do not apply another gradient over it.

---

# 3. VISUAL STYLE

The application should look like a premium modern consumer audio application.

Design language:

* Minimal
* Modern
* Clean
* Premium
* Light interface
* Soft purple/blue gradients
* White cards
* Very subtle borders
* Soft shadows
* Large rounded corners
* Generous whitespace
* Dark navy primary text
* Muted gray secondary text
* Purple/blue accent
* Green success indicators

Avoid:

* Heavy Material UI
* Excessive shadows
* Excessive gradients
* Neon overload
* Crowded layouts
* Tiny controls
* Generic Flutter UI
* Emoji icons
* Random decorative graphics

---

# 4. APP FLOW

The application should have the following major states:

```text
Splash
   ↓
Main Share Screen
   ↓
Bluetooth scanning
   ↓
Device found
   ↓
Connecting
   ↓
Connected
   ↓
Ready to share
   ↓
Sharing audio
   ↓
Stop sharing
```

Every state must have a proper visual transition.

Do not instantly switch between states without animation.

---

# 5. SPLASH SCREEN

Create a clean branded splash screen.

Center:

SoundShare logo

Below:

**SoundShare**

Below:

**Connect multiple devices**

Under the branding, show a subtle animated audio waveform.

At the bottom or below the waveform:

A small animated loading indicator.

Animation:

* Logo fades/scales in smoothly.
* Waveform gradually appears.
* Small loading indicator rotates/pulses.
* Transition to the main screen after initialization.

Do not make the splash unnecessarily long.

Use the actual logo file provided in the project root.

---

# 6. MAIN SHARE SCREEN

Main screen layout:

```text
SoundShare                         Settings

Connect multiple devices

┌─────────────────────────────────────┐
│                                     │
│  [device icon]   Your audio         │
│                  ● Connected        │
│                  Galaxy Buds        │
│                  You are listening  │
│                              100%   │
│                                     │
└─────────────────────────────────────┘

Bluetooth devices                    Scan

┌─────────────────────────────────────┐
│ [icon]  Sony WH-1000XM5       Connect│
│         Available                    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ [icon]  JBL Tune 760NC         Connect│
│         Available                    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│                                     │
│       0 devices connected           │
│ Connect a device to start sharing   │
│                                     │
│  [earbuds] ── waveform ── [headphones]
│                                     │
└─────────────────────────────────────┘

        [ Share Audio ]

Share                              Settings
```

The exact spacing, proportions, and visual hierarchy should follow the supplied reference.

---

# 7. TOP HEADER

Header:

Left:

Provided SoundShare logo.

Next to it:

**SoundShare**

Small text underneath:

**Connect multiple devices**

Right:

Settings icon inside a small circular button.

Add a small subtle status indicator if appropriate.

Do not make the header oversized.

---

# 8. YOUR AUDIO CARD

Create:

`ConnectedAudioCard`

This represents the audio device currently being used by the user.

Example:

**Your audio**

Green dot:

**Connected**

Device:

**Galaxy Buds**

Secondary:

**You are listening**

Right:

Battery icon + actual battery percentage if available.

Example:

`100%`

IMPORTANT:

Never invent battery information.

If Android does not provide battery information, gracefully hide the percentage rather than showing a fake value.

---

# 9. DEVICE ICON SYSTEM

Device icons are extremely important.

Do NOT use emojis.

Do NOT use raster images for generic device icons.

Do NOT use the same icon for every device.

Create a reusable:

`BluetoothDeviceIcon`

The icon must be selected based on the real Bluetooth device category/class provided by Android.

Supported categories:

```text
Earbuds
Headphones
Speaker
Car audio
Audio device
Unknown
```

Use clean vector icons.

For example:

### Earbuds

Use an actual earbuds vector icon.

### Headphones

Use an actual headphones vector icon.

### Speaker

Use an actual speaker vector icon.

### Car audio

Use a suitable car/audio vector icon.

### Unknown

Use a simple Bluetooth/audio vector icon.

Every icon should:

* Be vector based
* Have consistent stroke/weight
* Use the same visual style
* Sit inside a soft circular background
* Have appropriate size
* Adapt to light/dark theme if dark mode is later introduced

Create:

```text
BluetoothDeviceIcon
```

with:

```dart
BluetoothDeviceIcon({
  required BluetoothDeviceType type,
  double size = 24,
});
```

Do not determine device type by checking names such as:

`if name contains "AirPods"`

Use actual Bluetooth metadata whenever Android provides it.

---

# 10. BLUETOOTH DEVICES

Section heading:

**Bluetooth devices**

Right side:

Bluetooth scan icon +:

**Scan**

This must be real Bluetooth discovery.

No mock devices.

No demo mode.

No hardcoded device list.

Only display actual discovered devices.

---

# 11. SCAN ANIMATION

When the user taps Scan:

Change:

`Scan`

to:

`Scanning...`

Use a subtle rotating scan/Bluetooth animation.

Device cards should appear progressively as real devices are discovered.

Do not wait for the entire scan before showing results.

Example:

```text
Scanning...

Bluetooth devices

Sony WH-1000XM5
Discovering...

JBL Flip 6
Discovering...
```

As devices become available:

```text
Sony WH-1000XM5
Available
                     Connect
```

When scanning finishes:

Return to:

`Scan`

Do not continuously scan forever.

Stop scanning appropriately to preserve battery.

---

# 12. DEVICE APPEAR ANIMATION

When a new Bluetooth device is discovered:

Animate its card into the list.

Animation:

* Fade from 0 to 1
* Slight vertical movement
* Approximately 200-300ms
* Smooth easing

Do not use dramatic animations.

If a device disappears, animate the removal subtly.

---

# 13. CONNECT BUTTON

Each device card contains:

**Connect**

When pressed:

```text
Connect
 ↓
Connecting...
 ↓
Connected
```

During connection:

* Disable repeated taps
* Show a small loading indicator
* Keep the device icon visible
* Do not remove the card

After success:

* Show green connection indicator
* Button becomes `Disconnect`
* Update connected-device count
* Update the sharing panel
* Enable Share Audio if requirements are satisfied

---

# 14. SUCCESS CONNECTION ANIMATION

When a Bluetooth device successfully connects:

Perform a subtle success animation.

Suggested animation:

1. Connect button transitions to `Connected`.
2. Small green check appears.
3. Green circular ring expands briefly around the device icon.
4. Device moves/appears in the connected-devices panel.
5. Connected count updates.
6. Share Audio button transitions from disabled to enabled.

The complete animation should feel smooth and fast.

Do not use confetti.

Do not use large popups.

---

# 15. CONNECTION FAILURE

If connection fails:

* Return button to `Connect`.
* Stop loading animation.
* Keep device in the list.
* Show a concise error message.

Example:

**Couldn't connect**

`Make sure the device is available and try again.`

Use a subtle snackbar/banner.

Do not crash.

---

# 16. CONNECTED DEVICES PANEL

Create:

`ConnectedDevicesPanel`

Initial state:

**0 devices connected**

Subtitle:

**Connect a device to start sharing audio.**

Show:

```text
[Your earbuds]
       ···
 [audio waveform]
       ···
[Friend's headphones]
```

Use real device icons.

Do not use emoji.

When one device is connected:

**1 device connected**

Subtitle:

**You can now share audio.**

When sharing starts:

**Sharing audio**

and animate the audio path.

---

# 17. CONNECTED DEVICE ANIMATION

When a device connects successfully, visually show the audio connection being established.

For example:

```text
Your earbuds
     ○ ○ ○
       →
    waveform
       →
Friend's headphones
```

Animate small particles/wave pulses travelling from the source toward the connected device.

The animation must stop when sharing is stopped.

Use:

* CustomPainter
* AnimatedBuilder
* AnimationController

Do not use a GIF.

Do not use a video.

The animation must be native Flutter.

---

# 18. AUDIO WAVEFORM

Create a reusable:

`AudioWaveform`

The waveform should represent active audio.

Do NOT use a random continuously changing waveform with no relationship to application state.

Use a controlled animation.

When audio is active:

* Bars/waveform gently move.
* Amplitude changes smoothly.
* Animation loops.
* Movement should feel like real audio.

When audio is paused/inactive:

* Waveform becomes mostly static.
* Reduce animation.

When sharing:

* Increase waveform activity.
* Add subtle pulse through the connection line.

Implementation can use:

`CustomPainter`

or animated vector shapes.

Do not use an external video.

---

# 19. SHARE AUDIO BUTTON

Large full-width button.

Gradient:

Purple → Blue.

Text:

**Share Audio**

Icon:

Audio/share vector icon.

States:

### Disabled

No secondary compatible device.

Appearance:

Soft muted gradient.

Text:

`Share Audio`

### Ready

Secondary device connected.

Appearance:

Full vibrant gradient.

Text:

`Share Audio`

### Starting

Text:

`Starting...`

Small progress indicator.

### Sharing

Text:

`Sharing Audio`

Show animated audio icon/waveform.

### Stopping

Text:

`Stopping...`

After stopping:

Return to:

`Share Audio`

---

# 20. SHARE SUCCESS STATE

When audio sharing successfully begins:

The entire UI should communicate success without using a popup.

Changes:

Connected device:

Green status.

Connected panel:

**1 device connected**

or the correct count.

Panel subtitle:

**Sharing audio**

Audio waveform becomes active.

Main button:

**Sharing Audio**

Show a subtle animated glow/pulse around the sharing connection.

Optionally show:

`00:12`

sharing duration.

Do not add unnecessary information.

---

# 21. SHARING ANIMATION

When sharing is active:

Create a subtle animated audio flow:

```text
Your earbuds
      ~~~>
        ~~~>
          ~~~>
Friend's headphones
```

Use animated waveform/pulse elements.

Animation should communicate:

**Audio is moving from the source to the connected device.**

Keep it elegant.

No excessive glowing.

---

# 22. STOP SHARING

When the user taps the active Share Audio button:

Show:

`Stopping...`

Then:

* Stop audio-sharing service.
* Stop waveform animation.
* Stop connection-flow animation.
* Return to ready state.
* Keep Bluetooth connection active if appropriate.

The user should not need to reconnect the Bluetooth device just to start sharing again.

---

# 23. SETTINGS SCREEN

Create a clean Settings screen matching the same design.

Top:

Back button

**Settings**

Sections:

### Bluetooth

Show:

`On`

or:

`Off`

Use a real Bluetooth state.

### Audio sharing

Show:

`Available`

or the actual current state.

### Audio quality

Allow quality selection only if technically supported.

Possible options:

* Standard
* High

Do not show settings that are not actually supported.

### Auto connect

Toggle:

**Auto connect**

Subtitle:

`Connect to your last device when available`

### Stay visible

Toggle:

**Stay visible**

Subtitle:

`Allow nearby devices to discover SoundShare`

Only include this if it corresponds to an actual implemented discovery feature.

### About SoundShare

Show:

**Version X.X.X**

Keep the screen minimal.

---

# 24. BOTTOM NAVIGATION

Use a custom lightweight bottom navigation.

Two destinations:

### Share

Icon:

Audio sharing/wireless icon

Label:

`Share`

### Settings

Icon:

Gear

Label:

`Settings`

Active:

Purple.

Inactive:

Muted gray.

Do not use a large Material 3 NavigationBar.

---

# 25. ICON SYSTEM

Create a centralized icon system.

Do not mix random icon libraries.

Use a consistent vector icon style.

Required icons:

```text
SoundShareLogo
Bluetooth
Earbuds
Headphones
Speaker
CarAudio
Audio
Scan
Settings
Share
Play
Pause
Stop
Battery
Check
Close
Back
Warning
Info
Refresh
```

Device icons must be vector based.

Prefer Flutter-compatible vector/SVG assets or custom `CustomPainter` icons.

Do not use emoji.

Do not use platform screenshots as icons.

---

# 26. ICON VISUAL STYLE

All icons should have:

* Consistent visual weight
* Rounded geometry
* Clean lines
* Appropriate padding
* Same general visual language

Device icons should be slightly larger than action icons.

Example:

Device icon:

32-40px.

Action icon:

20-24px.

Navigation icon:

22-24px.

Do not make icons oversized.

---

# 27. MICRO-INTERACTIONS

Add subtle micro-interactions throughout the application.

Examples:

### Connect button

Press:

Slight scale-down.

Release:

Return to normal.

### Device card

When connected:

Border/background transitions smoothly.

### Scan

Bluetooth scan icon rotates.

### Share Audio

Button has a subtle press animation.

### Connection

Green status indicator fades/pulses once.

### Settings

Normal navigation transition.

All animations should be short and smooth.

---

# 28. ANIMATION ARCHITECTURE

Do not put animation code randomly throughout screens.

Create reusable animation widgets/controllers where appropriate:

```text
AudioWaveform
ScanningAnimation
ConnectionSuccessAnimation
AudioFlowAnimation
PulseIndicator
AnimatedStatusBadge
```

Use:

* AnimationController
* CurvedAnimation
* Tween
* AnimatedContainer
* AnimatedOpacity
* AnimatedSwitcher
* CustomPainter

Dispose all controllers correctly.

Respect reduced-motion preferences.

---

# 29. ANDROID BLUETOOTH

Implement real Android Bluetooth functionality.

Use the appropriate Android Bluetooth APIs.

The app must support modern Android versions.

Handle the required Bluetooth permissions according to Android API level.

Handle:

* Bluetooth disabled
* Bluetooth enabled
* Permission denied
* Permission permanently denied
* Bluetooth unavailable
* Scan failure
* Device unavailable
* Device disconnected
* Connection timeout

Do not request unnecessary permissions.

---

# 30. IMPORTANT BLUETOOTH LIMITATION

Do NOT assume that Android allows any third-party app to route the same system audio simultaneously to two independent Bluetooth audio outputs.

The application must first determine what the target Android device actually supports.

Do not fake:

```text
Phone → Bluetooth earbuds A
Phone → Bluetooth headphones B
```

if Android does not permit it.

If direct simultaneous Bluetooth output is not available, the architecture must support the alternative:

```text
Main phone
    ↓
Audio stream
    ↓
Friend's phone
    ↓
Friend's Bluetooth headphones
```

The UI should still remain consistent.

Do not show `Sharing Audio` until the underlying audio-sharing mechanism has actually started successfully.

---

# 31. AUDIO SHARING SERVICE

Create:

```dart
abstract class AudioSharingService {
  Future<bool> canShareAudio();

  Future<void> startSharing();

  Future<void> stopSharing();

  Stream<bool> get isSharing;

  Stream<double> get latency;
}
```

Keep this independent from the UI.

The implementation must use real Android capabilities.

If system audio capture is restricted for a particular source application, respect that restriction.

Do not bypass Android security restrictions.

---

# 32. AUDIO CAPTURE

Clearly separate:

```text
Audio source
     ↓
Audio capture
     ↓
Audio processing
     ↓
Audio transport
     ↓
Audio output
```

Do not assume every Android application allows its audio to be captured.

If the source application prevents capture, show an appropriate explanation.

If SoundShare itself plays the audio, support that source reliably.

---

# 33. FUTURE PEER AUDIO SUPPORT

Design the architecture so phone-to-phone audio sharing can be implemented without rewriting the UI.

Potential architecture:

```text
Phone A
   |
   | Local audio stream
   ↓
Phone B
   |
   ↓
Bluetooth headphones
```

The UI should not care whether the underlying transport is:

* Direct Bluetooth output
* Local peer-to-peer audio
* Another supported transport

Expose the functionality through:

`AudioSharingService`.

---

# 34. STATE MANAGEMENT

Use Riverpod or another production-quality state management solution.

Track:

```text
Bluetooth state
Permission state
Scanning state
Discovered devices
Connecting devices
Connected devices
Device battery
Audio source
Audio sharing availability
Audio sharing state
Sharing duration
Latency
Errors
```

Do not use one huge StatefulWidget.

---

# 35. ARCHITECTURE

Use a clean production structure:

```text
lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       ├── app_gradients.dart
│       └── app_text_styles.dart
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── services/
│   └── utils/
│
├── features/
│   ├── bluetooth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── audio_sharing/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── share/
│   │   └── presentation/
│   │
│   └── settings/
│       └── presentation/
│
└── main.dart
```

---

# 36. THEME

Create a centralized SoundShare theme.

Primary gradient:

Purple → Blue.

Use the exact visual direction from the provided reference.

Create:

```text
AppColors
AppGradients
AppTextStyles
AppTheme
```

Do not scatter colors throughout the application.

The theme should control:

* Background
* Cards
* Borders
* Primary text
* Secondary text
* Purple
* Blue
* Success green
* Error state
* Disabled state

---

# 37. RESPONSIVE DESIGN

Support:

* Small Android phones
* Large Android phones
* Different aspect ratios
* 320px-wide screens
* Modern Android devices

Use:

* SafeArea
* LayoutBuilder
* Flexible
* Expanded
* ConstrainedBox

Avoid fixed screen widths.

No horizontal overflow.

No clipped buttons.

No clipped text.

---

# 38. ACCESSIBILITY

Use:

* Semantic labels
* Accessible touch targets
* Good contrast
* Screen-reader labels
* Proper button semantics

For example:

A Bluetooth device icon should have an accessible label such as:

`Headphones`

Do not rely on the icon alone to communicate information.

---

# 39. ERROR UX

Errors should be helpful but unobtrusive.

Examples:

### Bluetooth off

**Bluetooth is turned off**

`Turn on Bluetooth to find audio devices.`

### Permission denied

**Bluetooth permission required**

`Allow Bluetooth access to find nearby audio devices.`

### No devices

**No Bluetooth audio devices found**

`Make sure your headphones are nearby and discoverable.`

### Sharing unavailable

**Audio sharing isn't available**

`This device or audio source doesn't support sharing.`

Do not blame the user.

Do not use technical error codes in the primary UI.

---

# 40. REAL DATA ONLY

Production application rules:

DO NOT:

* Hardcode Bluetooth device names
* Hardcode connection status
* Fake battery percentages
* Fake scan results
* Fake sharing
* Fake success
* Create demo mode
* Create mock services
* Create placeholder Bluetooth devices

The application must use actual Android data.

---

# 41. NO ACCOUNT / BACKEND

The basic experience should not require:

* Login
* Account
* Firebase
* Supabase
* Cloud database
* Internet connection

Bluetooth discovery and supported local communication should work locally.

Only introduce networking where it is technically required for the phone-to-phone audio-sharing architecture.

---

# 42. LIFECYCLE

Handle:

* App launched
* App resumed
* App paused
* Bluetooth turned off while app is open
* Bluetooth turned on while app is open
* Device disconnected
* Audio sharing interrupted
* App sent to background

Clean up:

* Bluetooth scans
* Stream subscriptions
* Animation controllers
* Audio resources
* Native listeners

---

# 43. PERFORMANCE

The app must be efficient.

Avoid:

* Continuous unnecessary Bluetooth scans
* Excessive widget rebuilds
* Unnecessary animation work
* Memory leaks
* Unreleased streams
* Unreleased native resources

Animations should run only when required.

---

# 44. FINAL UI SCREEN STATES

Implement all of these visually:

### Screen 1

Splash

### Screen 2

Main screen, no devices

### Screen 3

Scanning

### Screen 4

Devices discovered

### Screen 5

Connecting

### Screen 6

Connection successful

### Screen 7

Ready to share

### Screen 8

Sharing audio

### Screen 9

Stopping audio

### Screen 10

Connection failure

### Screen 11

Bluetooth disabled

### Screen 12

Bluetooth permission required

### Screen 13

No devices found

### Screen 14

Settings

Every state should be polished and consistent.

---

# 45. SUCCESS FLOW

The ideal successful experience:

```text
Open SoundShare
        ↓
Splash animation
        ↓
Main screen
        ↓
Real Bluetooth scan
        ↓
Real Bluetooth device appears
        ↓
Tap Connect
        ↓
Connecting animation
        ↓
Android confirms connection
        ↓
Success animation
        ↓
"1 device connected"
        ↓
Share Audio button becomes active
        ↓
Tap Share Audio
        ↓
Audio sharing service starts
        ↓
Waveform becomes active
        ↓
Audio flow animation begins
        ↓
"Sharing Audio"
```

This should feel like one continuous polished experience.

---

# 46. IMPORTANT: DO NOT OVERDESIGN

The application should remain simple.

The user should understand the app within seconds.

Primary message:

**SoundShare**

**Connect multiple devices**

Primary action:

**Share Audio**

Everything else should support this goal.

Do not add unnecessary:

* Tabs
* Dashboards
* Statistics
* Social features
* Profiles
* Accounts
* Complex settings
* Onboarding carousels

---

# 47. FINAL QUALITY REQUIREMENT

Before considering the implementation complete:

1. Run `flutter analyze`.
2. Fix all analyzer errors and warnings where practical.
3. Run the Android build.
4. Verify the app launches.
5. Verify the provided logo is loaded from the project root asset.
6. Verify real Bluetooth scanning.
7. Verify real device icons.
8. Verify connection state.
9. Verify disconnect state.
10. Verify animations.
11. Verify error states.
12. Verify Android permissions.
13. Verify lifecycle handling.
14. Verify no fake devices exist.
15. Verify no demo mode exists.
16. Verify no emoji icons exist.
17. Verify the UI against the supplied reference image.
18. Verify the app does not claim audio sharing is active unless the underlying service confirms it.

The final result should feel like a polished production application rather than a UI demonstration.

# CORE PRODUCT MESSAGE

The user should immediately understand:

**SoundShare lets you connect multiple audio devices and share the same audio.**
