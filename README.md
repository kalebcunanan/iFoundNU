# 🔍 iFoundNU: The Official NU Clark Lost & Found App

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Provider](https://img.shields.io/badge/Provider-State_Management-blue?style=for-the-badge)

**iFoundNU** is a mobile application dedicated to National University (NU) Clark students. It serves as a centralized, real-time platform to report, search, and claim lost and found items inside the campus. Built with modern UI/UX principles, the app ensures that lost belongings find their way back to their rightful owners efficiently and securely.

---

## ✨ Key Features

* 🔐 **Exclusive Student Authentication**
    * Secure login and registration powered by Firebase Auth.
    * Strict email verification system to ensure only legitimate students can access the platform.
* 📡 **Real-Time Item Feed**
    * Live updates for "Lost" and "Found" items using Firestore real-time listeners.
    * Quick swipe gestures to toggle between reporting lost or found items.
* 💬 **In-App Messaging**
    * Direct, real-time chat functionality between the item finder and the owner.
    * Integrated live status tracking right inside the chat room.
* 🔎 **Smart Search & Filtering**
    * Dynamic search bar to easily find items based on keywords, descriptions, or locations.
    * Automatic filtering to hide items that are already marked as "Resolved".
* 📸 **Camera & Gallery Integration**
    * Seamless image uploads via Firebase Storage for clear item identification.
* ✅ **Status Management**
    * One-tap "Resolve" feature to close cases once an item is successfully returned.

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend & Database:** Firebase (Authentication, Cloud Firestore, Cloud Storage)
* **State Management:** Provider
* **Architecture:** Clean Architecture (Separation of UI, Models, Services, and Providers)


---

## 🚀 Getting Started

Follow these steps to run the project locally on your machine.

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
* An IDE like Android Studio or VS Code.
* An active Firebase Project.

### Installation

1.  **Clone the repository**
    ```bash
    git clone [https://github.com/kalebcunanan/iFoundNU.git](https://github.com/kalebcunanan/iFoundNU.git)
    ```
2.  **Navigate to the directory**
    ```bash
    cd iFoundNU
    ```
3.  **Install dependencies**
    ```bash
    flutter pub get
    ```
4.  **Connect to Firebase**
    * Make sure you have the Firebase CLI installed.
    * Run `flutterfire configure` to generate your own `firebase_options.dart` file. *(Note: The original Firebase configuration is hidden in `.gitignore` for security).*
5.  **Run the app**
    ```bash
    flutter run
    ```

---

## 👨‍💻 Developer

Developed with 💙 and 💛 by:
* **Kaleb Jeiel D. Cunanan** * *BS Information Technology (Web and Mobile Development)*
* National University (NU) Clark

---
> **Disclaimer:** This is a student project created for academic and portfolio purposes.
