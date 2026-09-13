# SoundShare — Google Play Store Listing & Submission Guide

## 📱 App Identifiers & Metadata

### Package Name / Application ID
`com.soundshare.soundshare`

### App Title (Max 30 characters)
`SoundShare: Audio Sharing`

*(Alternative Titles:)*
- `SoundShare: Multi Audio Share`
- `SoundShare: Bluetooth Share`
- `SoundShare`

### Category & Tags
- **Primary Category**: `Music & Audio` (or `Tools / Utilities`)
- **Tags**: `Audio Sharing`, `Dual Bluetooth Audio`, `Bluetooth Audio Splitter`, `Headphone Splitter`, `Share Music`, `Multi Audio`, `Spatial Audio`, `3D Sound`

---

## 📝 Store Listing Copy (Primary Focus: Audio Sharing)

### Short Description (Max 80 characters)
`Connect and share audio to multiple Bluetooth headphones and speakers in sync.`

### Full Description (Max 4000 characters)
```text
SoundShare is the ultimate wireless audio sharing app for Android. Easily connect and stream the same music, movie, podcast, or game audio to multiple Bluetooth headphones, earbuds, and speakers simultaneously with synchronized, low-latency playback.

Turn your Android phone into a powerful wireless audio hub. No extra cables or hardware splitters needed!

━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎧 WHY SOUNDSHARE? (MAIN PURPOSE)
━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ever wanted to watch a movie on Netflix or YouTube with a friend on a plane or train using two pairs of wireless earbuds? Or stream your workout playlist to multiple Bluetooth speakers across your room?

SoundShare solves the single-Bluetooth limitation on Android by letting you broadcast synchronized audio to multiple Bluetooth devices at once.

━━━━━━━━━━━━━━━━━━━━━━━━━━━
✨ KEY FEATURES
━━━━━━━━━━━━━━━━━━━━━━━━━━━

📡 1. MULTI-DEVICE BLUETOOTH AUDIO SHARING
• Connect 2 or more Bluetooth headphones, AirPods, earbuds, or portable speakers at the same time.
• Real-time synchronized streaming with ultra-low latency audio pipeline.
• Works with any Bluetooth audio device (Sony, Bose, JBL, Apple AirPods, Galaxy Buds, Beats, etc.).
• Individual volume control for each connected receiver so everyone listens at their preferred loudness.
• One-tap quick connect, pair, and disconnect directly from the main sharing dashboard.

🌐 2. 3D SPATIAL AUDIO & HEAD TRACKING
• Studio-grade 360° binaural spatial sound engine for cinema-like audio immersion.
• Real-time head tracking keeps virtual audio anchored in world space as you move.
• Interactive 360° visualizer: drag and position sound sources anywhere around you.
• Custom acoustic presets: Balanced, Wide, Cinema, Gaming, and Immersive.

🎵 3. BEATSYNC AUDIO-HAPTIC FEEDBACK
• Feel the rhythm! Real-time bass, drop, and beat-synchronized haptic vibrations.
• Works alongside Bluetooth sharing or directly through your phone's built-in audio.
• Customizable vibration strength, sensitivity, and battery-friendly thermal protection.

🎨 4. MODERN DESIGN & THEME SUPPORT
• Full support for Day/Light Mode and Deep Studio Dark Mode.
• Live 60fps audio waveform flow visualizers.
• Clean, minimalist interface with no clutter and zero disruptive ads.
• Background audio playback with notification shade controls.

🔒 5. 100% PRIVATE & ON-DEVICE
• No accounts, logins, or cloud servers required.
• All audio routing and analysis happen entirely on-device in RAM.
• No recordings or personal audio streams are ever stored or uploaded.

━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 COMMON USE CASES
━━━━━━━━━━━━━━━━━━━━━━━━━━━
• 🎬 Movie Nights & Travel: Watch Netflix, Disney+, or movies with a friend using two sets of wireless headphones without disturbing others.
• 🏃 Gym & Running: Share the exact same running tempo playlist with your workout partner in real time.
• 🔊 Multi-Speaker Room Audio: Pair two or more Bluetooth speakers to fill larger spaces with synchronized sound.
• 🎮 Mobile Gaming: Share in-game audio with your co-op teammate with directional 3D spatial cues.

Share your sound, together. Download SoundShare today!
```

---

## 🖼️ Graphic Assets & Specifications

| Asset | Dimensions | Requirements |
|---|---|---|
| **App Icon** | `512 x 512 px` | PNG (32-bit with alpha), max 1 MB, no transparent background. |
| **Feature Graphic** | `1024 x 500 px` | PNG or JPEG, banner highlighting "Share Audio to Multiple Bluetooth Devices". |
| **Phone Screenshots** | Min 2, max 8 | 16:9 or 18:9 aspect ratio (`1080 x 1920 px` or `1080 x 2400 px`). |
| **Screenshot Priority** | | 1. Main Bluetooth Audio Sharing Screen (Connected Devices)<br>2. Dual Audio Volume Controls<br>3. 3D Spatial Audio Screen with 360° Visualizer<br>4. BeatSync Audio-Haptic Screen |

---

## 🛡️ Play Console Data Safety & Permissions Guide

### Permissions Justification (For Google Play Reviewers)

| Permission | Declaration & Justification |
|---|---|
| **`BLUETOOTH_SCAN`** | Required to discover nearby Bluetooth headphones, speakers, and audio receivers. |
| **`BLUETOOTH_CONNECT`** | Required to establish simultaneous audio streams to multiple paired Bluetooth devices. |
| **`BLUETOOTH_ADVERTISE`** | Required to broadcast audio synchronization signals to secondary receivers. |
| **`RECORD_AUDIO`** | Required strictly for real-time frequency analysis and BeatSync haptic beat detection in RAM. **No audio is recorded, saved, or uploaded**. |
| **`FOREGROUND_SERVICE_MEDIA_PLAYBACK`** | Required to maintain uninterrupted Bluetooth audio sharing when the screen is locked or app is minimized. |
| **`VIBRATE`** | Triggers synchronized rhythm haptics in sync with musical beats. |
| **`POST_NOTIFICATIONS`** | Displays active session playback controls (Play, Pause, Stop) in the notification bar. |

---

## 📋 Data Safety Questionnaire Answers

- **Does your app collect or share any user data?** ➔ **No**
- **Is all data processed ephemerally?** ➔ **Yes** (Audio buffers are analyzed purely in volatile memory).
- **Does your app contain ads?** ➔ **No**
- **Target Audience / Age Rating** ➔ **Everyone (PEGI 3 / ESRB Everyone)**
- **Privacy Policy URL**: Host [privacy_policy.md](file:///c:/Users/arind/Documents/Sound-Share/privacy_policy.md) on a public URL (e.g. GitHub Pages).
