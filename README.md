🌍 EcoQuest - GitHub Wiki
Welcome to the EcoQuest GitHub Wiki! EcoQuest is a gamified environmental cleanup application built with Flutter and Firebase. It encourages users to take real-world action by cleaning up their local environment, verifying their impact using AI, and competing with friends on leaderboards.

📖 Table of Contents
Introduction
Key Features
Tech Stack
App Architecture
Getting Started (Installation)
Future Roadmap
🌟 Introduction
EcoQuest bridges the gap between digital gamification and real-world environmental impact. Users embark on "Quests" (like Beach Clean-ups), take a "Before" picture of a littered area, clean it up, and take an "After" picture. Our integration with Google's Gemini AI verifies the cleanup in real-time, rewarding the user with Experience Points (EXP) and levels.

✨ Key Features
🤖 AI-Verified Quests: Employs Gemini Flash models to analyze before-and-after images, ensuring that the cleanup was genuinely completed before awarding points.
📈 Gamification & Progression: Users earn 50 EXP per completed quest. The leveling system dynamically scales, requiring more quests to reach higher levels. Progress bars mathematically scale visual completion based on fractional EXP.
👥 Social Squads & Leaderboards: Connect with friends via username, send friend requests, and compete on a global or friends-only leaderboard based on EXP.
📊 Environmental Impact Tracking: Tracks overall quests completed, time invested, and presents a visual history of cleaned areas via interactive user profiles.
🛠️ Tech Stack
Frontend: Flutter (Dart)
Backend: Firebase Authentication, Cloud Firestore
AI Integration: google_generative_ai (Gemini API 2.5 Flash)
Other Packages: cached_network_image, flutter_contacts, permission_handler, image_picker
🏗️ App Architecture
The source code is primarily housed in the lib/ directory:

auth_service.dart
: Handles Firebase Authentication (Sign up, Login) and Firestore user document management (including the Friend Request system).
level_utils.dart
: Contains the mathematical logic for calculating a user's Level and EXP progress dynamically based on gamification thresholds.
quest_screen.dart
: The core gameplay loop. Manages camera/gallery interactions, timer states, and Gemini AI verification API calls with localized loading visualizations.
quest_state.dart
: Manages the local state of an active quest (timers, image caching).
social_screen.dart
: Displays the user's social hub, including their profile card naturally computing UI scaling for EXP bars, the leaderboard of friends' eco-impact, and pending requests.
friend_profile_screen.dart
: Read-only view of a friend's stats, level logic, and eco-impact summary over their total time played.
🚀 Getting Started
Prerequisites
Flutter SDK (latest stable)
A Firebase Project with Authentication (Email/Password) and Firestore enabled.
A Gemini AI API Key from Google AI Studio.
Installation
Clone the repository:
bash
git clone https://github.com/berlinflix/ecoquest.git
cd ecoquest
Install dependencies:
bash
flutter pub get
Firebase Setup:
Run flutterfire configure to link your Firebase project.
Ensure Firestore security rules allow authenticated users to read/write their social and level data securely.
API Key Configuration:
Create a document in Firestore: config/api_keys.
Add a string field gemini_api_key containing your valid Gemini API key. (Note: For production, consider using Firebase App Check and Cloud Functions to completely isolate the API key from the client).
Run the App:
bash
flutter run
🗺️ Future Roadmap
Smart bin hardware and IoT integration.
Geo-location based quests (finding polluted spots on an interactive map).
Push notifications for friend requests and quest reminders.
Advanced Squad features (team co-op quests scaling for thousands of collective EXP).
