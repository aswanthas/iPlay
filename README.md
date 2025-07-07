# 🎵 iPlay – SwiftUI Audio Player App

**iPlay** is a lightweight and modern audio player built using **SwiftUI**, **Core Data**, and **AVFoundation**. It allows you to import audio files, play them with background support, and manage a personalized list of tracks—all in a sleek, Spotify-inspired interface.

---

## 🚀 Features

### ✅ Audio Management
- Import `.mp3` or `.mp4` audio files from the file system
- Store audio metadata using Core Data
- Delete audio tracks with swipe-to-delete

### 🎧 Playback
- Play and pause local audio files
- Mini player bar pinned to the bottom (like Spotify)
- Support for **Play**, **Pause**, **Next**, and **Previous** track actions
- Background audio playback (with audio session configuration)

### 🔒 Lock Screen + Control Center
- Displays track info on the lock screen
- Supports playback controls via Control Center, headphones, or lock screen
- Integrates with `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter`

---

## 🛠️ Built With

- **SwiftUI** – for declarative UI
- **Core Data** – for persistent track storage
- **AVFoundation** – for audio playback
- **MediaPlayer** – for lock screen and system-level playback integration

---

## 📂 File Import Support

- Currently supports `.mp3` and `.mp4` audio files
- Imported files are copied to the app's local **Documents** directory

---

## 🔧 Getting Started

1. Clone the repo:
   ```bash
   git clone https://github.com/aswanthas/iPlay.git
