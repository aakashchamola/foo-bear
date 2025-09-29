# 💕 UsTime - A Romantic Flutter App

A beautiful, heartfelt app designed for couples to stay connected with love, joy, and intimate moments. Built with Flutter and Firebase.

## ✨ Features

### 🏠 Animated Home Screen
- **Random Love Buttons**: Buttons like "I Miss You", "Thinking of You", "Love You" appear in random positions each time the app opens
- **Heart Animations**: Tap buttons to send hearts flying to your partner's profile picture
- **Animated Background**: Floating particles and gradient backgrounds for a dreamy experience
- **Real-time Notifications**: Instantly notify your partner when you send love

### 💬 Real-Time Messaging
- Realtime chat with message reactions (hearts, blush, etc.)
- Online status and typing indicators
- Optional audio notes
- Encrypted messages for privacy

### 📸 Photo Galleries
- **Public Gallery**: Shared photo scrapbook with polaroid frames and heart transitions
- **Secret Gallery**: Encrypted, passcode-protected intimate photos
- Date stamps and captions for memories

### 📖 Love Diary
- Personal diary entries visible to both partners
- Animated post-it note interface
- Mood tracking and themes

### 🎮 Mini Games & Surprises
- Love quizzes and daily questions
- Confetti explosions and surprise animations
- Personalized themes that change daily

## 🛠️ Tech Stack

- **Flutter** - Cross-platform mobile development
- **Firebase** - Backend services (free tier)
  - Authentication (email/password)
  - Firestore (realtime database)
  - Cloud Storage (photos)
  - Cloud Messaging (push notifications)
  - Remote Config (themes)
- **Rive/Lottie** - Vector animations
- **AES Encryption** - End-to-end encryption for secret content

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.5.0)
- Firebase account
- Android Studio / VS Code
- Device or emulator for testing

### Installation

1. **Clone the repository**
   \`\`\`bash
   git clone <your-repo-url>
   cd her
   \`\`\`

2. **Install dependencies**
   \`\`\`bash
   flutter pub get
   \`\`\`

3. **Setup Firebase**
   - Follow instructions in [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
   - Add your \`google-services.json\` to \`android/app/\`
   - Add your \`GoogleService-Info.plist\` to \`ios/Runner/\`

4. **Run the app**
   \`\`\`bash
   flutter run
   \`\`\`

## 🎨 Design Philosophy

The app embraces a **romantic, dreamy aesthetic** with:
- Soft pastel colors (pinks, purples, cream whites)
- Handwriting fonts for personal touch
- Whimsical animations and transitions
- Heart-themed interactions throughout
- Randomized UI elements for delightful surprises

## 📁 Project Structure

\`\`\`
lib/
├── main.dart                 # App entry point
├── screens/                  # Screen widgets
│   ├── home_screen.dart     # Main screen with love buttons
│   ├── chat_screen.dart     # Real-time messaging
│   ├── gallery_screen.dart  # Public photo gallery
│   ├── secret_gallery.dart  # Encrypted photo gallery
│   ├── passcode_screen.dart # Security screen
│   └── diary_screen.dart    # Love diary
├── widgets/                  # Reusable UI components
│   ├── floating_hearts.dart # Heart animation system
│   ├── random_love_button.dart # Love button widget
│   ├── love_note_card.dart  # Diary entry cards
│   └── theme_switcher.dart  # Theme management
├── services/                 # Business logic
│   ├── auth_service.dart    # Authentication
│   ├── firestore_service.dart # Database operations
│   ├── notification_service.dart # Push notifications
│   ├── storage_service.dart # File uploads
│   └── encryption_service.dart # Security
├── utils/                    # Constants and helpers
│   └── constants.dart       # App constants and themes
└── models/                   # Data models
\`\`\`

## 🔐 Security Features

- **End-to-end encryption** for chat messages and secret photos
- **Passcode protection** for secret gallery
- **Firebase security rules** for data protection
- **AES encryption** for sensitive content
- **Secure local storage** for authentication tokens

## 🎯 Development Phases

- [x] **Phase 1**: Flutter setup + Firebase configuration
- [x] **Phase 2**: Home screen with animated love buttons
- [ ] **Phase 3**: Real-time chat and notifications
- [ ] **Phase 4**: Photo galleries with Firebase Storage
- [ ] **Phase 5**: Secret gallery with encryption
- [ ] **Phase 6**: Love diary and mood tracking
- [ ] **Phase 7**: Polish, themes, and offline support

## 💝 Contributing

This is a personal romantic project, but suggestions and improvements are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📱 Screenshots

*Coming soon - Screenshots will be added once the app is fully functional*

## 💌 Love Notes

This app is designed to strengthen relationships through technology. Every animation, every notification, every feature is crafted with love in mind. 

**Remember**: The most beautiful UI is meaningless without genuine connection. Use this app as a tool to express your love, but never let it replace real conversations and quality time together.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

Made with 💕 for love, by love, with love.
# foo-bear
