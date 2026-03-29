# 🚀 Pro-Organizer - Real-Time Todo Application

<p align="center">
  <img src="assets/logo1.png" alt="Pro-Organizer Logo" width="128" height="128">
</p>

<p align="center">
  <strong>A comprehensive, real-time task management and note-taking application built with Flutter and Supabase, featuring offline-first architecture with seamless cloud synchronization.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.0+-blue.svg?style=flat&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.0+-blue.svg?style=flat&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Supabase-Real--time-green.svg?style=flat&logo=supabase" alt="Supabase">
  <img src="https://img.shields.io/badge/Theme-Dark%20%2F%20Light-purple.svg?style=flat" alt="Theme">
</p>
---


## 🎥 Task Demo

https://github.com/user-attachments/assets/c5e954e9-b52e-43dd-a013-4359cb359a4e

---

## ✨ Features

### 🎯 **Core Functionality**
- **Real-time Task Management** - Create, edit, delete, and organize tasks instantly
- **Smart Categories** - Organize tasks with customizable categories and colors
- **Priority System** - 5-level priority system with visual indicators
- **Due Date Tracking** - Set due dates with intelligent overdue detection
- **Offline-First Architecture** - Work seamlessly without internet connection
- **Real-time Synchronization** - Instant sync across all devices when online

### 🔔 **Advanced Notifications**
- **Smart Reminders** - Customizable notification timing (15 min, 1 hour, 1 day before)
- **Real-time Updates** - Live notifications for task updates, completions, and sync status
- **Daily Summary** - End-of-day productivity summaries with completion rates
- **Weekly Achievements** - Motivational notifications for weekly goals
- **Overdue Alerts** - Intelligent reminders for overdue tasks

---

## 🔄 **Real-Time Update System**

### **How Real-Time Updates Work**

This application features a comprehensive real-time synchronization system powered by Firebase Firestore:

#### **Instant Synchronization**
- **Live Listeners** - Firestore real-time listeners track all task changes instantly
- **Multi-Device Sync** - Changes on any device appear immediately on all others
- **Bidirectional Updates** - Both local and cloud changes sync seamlessly
- **Conflict Resolution** - Automatic handling of concurrent edits

#### **Offline-First with Auto-Sync**
- **Local SQLite Database** - All tasks stored locally for immediate offline access
- **Automatic Queueing** - Changes queued automatically when offline
- **Smart Sync** - Pending changes sync automatically when connection restored
- **Retry Mechanism** - Failed syncs retry with exponential backoff

#### **Real-Time Features**
- ⚡ **Instant Task Updates** - See live changes as they happen
- 📊 **Live Analytics** - Real-time productivity metrics and streak calculations
- 🔔 **Live Notifications** - Push notifications for all task events
- 👁️ **Presence Awareness** - Know when other users are active (when shared)

---

## 📱 **Installation & Setup**

### **Prerequisites**
- Flutter 3.0 or higher
- Dart 3.0 or higher
- Android SDK (API 21+) or iOS (13.0+)
- Firebase Project
- Google Play Services

### **Initial Setup**

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/pro-organizer.git
   cd pro-organizer
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Environment Variables**
   ```bash
   cp .env.example .env
   # Edit .env with your Firebase and API credentials
   ```

4. **Configure Firebase**
   - Download `google-services.json` from Firebase Console
   - Place in `android/app/` directory
   - The file is gitignored and NOT included in version control

5. **Configure Firestore Rules & Storage**
   - Copy `firestore.rules` and `storage.rules` (if needed)
   - Deploy using Firebase CLI: `firebase deploy --only firestore:rules,storage`
   - These files are also gitignored for security

6. **Run the App**
   ```bash
   flutter run -d <device_id>
   ```

---

## 🌳 **Git Workflow & Main Branch**

### **Branch Strategy**
- **`main`** - Production-ready code, always stable
- **`develop`** - Integration branch for features
- **`feature/*`** - Feature development branches

### **Real-Time Updates on Main Branch**
The main branch receives regular updates with:
- ✅ Bug fixes and stability improvements
- ✅ New real-time features and optimizations
- ✅ Performance enhancements
- ⚠️ Breaking changes (documented in CHANGELOG)

**Always check the main branch before deploying to production!**

### **Checking for Updates**
```bash
# Fetch latest changes
git fetch origin main

# See what's new
git log main --oneline -10

# Update local main branch
git pull origin main
```

---

## 🔐 **Security & Privacy**

### **What's Gitignored (NOT in version control)**
- ✅ `.env` - Environment variables with API keys
- ✅ `google-services.json` - Firebase Android config
- ✅ `GoogleService-Info.plist` - Firebase iOS config
- ✅ `firestore.rules` - Firestore security rules
- ✅ `storage.rules` - Cloud Storage rules
- ✅ Firebase Emulator files
- ✅ Local analysis and error files

### **Setup Instructions for Contributors**
1. Copy `.env.example` to `.env`
2. Add your own Firebase credentials
3. Download service files from Firebase Console
4. Files are automatically ignored by Git (no accidental commits!)

---

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request to `develop` branch

---

## 📄 **Environment Configuration**

Create a `.env` file in the root directory (copy from `.env.example`):

```env
# Firebase Configuration
FIREBASE_API_KEY=your_key_here
FIREBASE_PROJECT_ID=your_project_id
# ... other configuration
```

**⚠️ Never commit `.env` file to Git!**

---

## 🚀 **Deployment**

### **Building for Production**
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

### **Firebase Deployment**
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage
```

---

## 📝 **Changelog**

See [CHANGELOG.md](CHANGELOG.md) for version history and real-time feature updates.

---

## 📧 **Support & Issues**

Found a bug or have a feature request?
- Open an issue on GitHub
- Include details about your environment
- For real-time sync issues, check Firebase connectivity status in the app

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 **Author**

**Developed with ❤️ for productive task management**

---

<p align="center">
  <strong>⭐ If you find this project helpful, please give it a star!</strong>
</p>
