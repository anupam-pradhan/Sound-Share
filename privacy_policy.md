# Privacy Policy for SoundShare

**Effective Date:** August 31, 2026  
**Last Updated:** August 31, 2026  

SoundShare ("we", "our", or "the App") is committed to protecting your privacy. This Privacy Policy explains how our application operates and handles user information.

---

### 1. Information We Do NOT Collect
SoundShare is built with a **privacy-first architecture**. 
- We do **not** collect, store, or sell any personal identifying information (PII).
- We do **not** require account creation, logins, or tracking cookies.
- We do **not** transmit any telemetry, usage metrics, or user recordings to external servers.

---

### 2. Device Permissions and Usage

SoundShare requests only the permissions necessary to deliver core audio-sharing and haptic feedback features:

#### a. Bluetooth & Nearby Devices (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE`)
- **Purpose**: Used strictly to search for, pair with, and route audio to nearby Bluetooth headphones, earbuds, and speakers.
- **Data Handling**: Device identifiers (MAC addresses/names) are processed locally in RAM and are never uploaded.

#### b. Audio Capture (`RECORD_AUDIO` / `MODIFY_AUDIO_SETTINGS`)
- **Purpose**: Used solely by the **BeatSync** feature for real-time frequency analysis and transient beat detection (identifying kicks, drops, and rhythms for synchronized vibration).
- **Data Handling**: Audio samples are analyzed ephemerally in device memory and immediately discarded. **No audio is recorded, saved, or uploaded**.

#### c. Vibration (`VIBRATE`)
- **Purpose**: Used by the BeatSync engine to deliver synchronized haptic pulses to the device's vibration motor.

#### d. Foreground Services & Notifications (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `POST_NOTIFICATIONS`)
- **Purpose**: Allows audio sharing and BeatSync sessions to continue uninterrupted when the device screen is off or when switching between apps, providing ongoing notification controls.

---

### 3. Third-Party Services & Analytics
SoundShare contains **no third-party advertising SDKs, trackers, or data-collection analytics libraries**.

---

### 4. Children's Privacy
SoundShare does not knowingly collect any personal information from children under the age of 13.

---

### 5. Contact Information
If you have any questions or feedback regarding this Privacy Policy, please contact the developer via the official SoundShare GitHub repository or Google Play Store listing.
