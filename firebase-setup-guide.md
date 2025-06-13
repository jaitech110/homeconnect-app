# 🔥 Firebase Setup Guide for HomeConnect

## Step 1: Create Firebase Project

1. **Go to [Firebase Console](https://console.firebase.google.com/)**
2. **Click "Create a project"**
3. **Project name**: `homeconnect-app`
4. **Enable Google Analytics**: Yes (recommended)
5. **Click "Create project"**

## Step 2: Upgrade to Blaze Plan

1. **In Firebase Console**: Go to "Usage and billing"
2. **Click "Modify plan"**
3. **Select "Blaze (Pay as you go)"**
4. **Benefits**: 
   - Cloud Firestore: 50K reads/day free, then $0.06 per 100K reads
   - Cloud Storage: 5GB free, then $0.026/GB
   - Cloud Functions: 2M invocations/month free

## Step 3: Enable Services

### Enable Firestore Database
1. **Go to "Firestore Database"**
2. **Click "Create database"**
3. **Security rules**: Start in test mode (we'll secure later)
4. **Location**: Choose closest to your users

### Enable Authentication
1. **Go to "Authentication"**
2. **Click "Get started"**
3. **Sign-in method**: Enable "Email/Password"

### Enable Storage
1. **Go to "Storage"**
2. **Click "Get started"**
3. **Security rules**: Start in test mode

## Step 4: Get Firebase Config

1. **Go to Project Settings** (gear icon)
2. **Scroll to "Your apps"**
3. **Click "Add app" → Web app**
4. **App nickname**: `homeconnect-web`
5. **Copy the config object** (firebaseConfig)

## Step 5: Add Firebase to Flutter

### Add dependencies to pubspec.yaml:
```yaml
dependencies:
  firebase_core: ^2.24.2
  cloud_firestore: ^4.13.6
  firebase_auth: ^4.15.3
  firebase_storage: ^11.5.6
```

### Initialize Firebase in main.dart:
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "your-api-key",
      authDomain: "homeconnect-app.firebaseapp.com",
      projectId: "homeconnect-app",
      storageBucket: "homeconnect-app.appspot.com",
      messagingSenderId: "123456789",
      appId: "your-app-id"
    ),
  );
  runApp(HomeConnectApp());
}
```

## Step 6: Database Structure

Firestore Collections:
```
users/
  {userId}/
    - email: string
    - role: string
    - isApproved: boolean
    - createdAt: timestamp

buildings/
  {buildingId}/
    - name: string
    - address: string
    - unionIncharge: string

complaints/
  {complaintId}/
    - title: string
    - description: string
    - status: string
    - userId: string
    - createdAt: timestamp

elections/
  {electionId}/
    - title: string
    - candidates: array
    - startDate: timestamp
    - endDate: timestamp
```

## Step 7: Security Rules

### Firestore Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Admin can read all users for approvals
    match /users/{userId} {
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Complaints - users can create, admins can update
    match /complaints/{complaintId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'union incharge'];
    }
  }
}
```

## Step 8: Benefits for HomeConnect

### Real-time Features:
- ✅ Union approvals appear instantly to admins
- ✅ Complaint status updates in real-time
- ✅ Election results update live
- ✅ New residents see building data immediately

### Global Access:
- ✅ Works from any device, anywhere
- ✅ Automatic offline support
- ✅ Data syncs when internet returns
- ✅ All users share same database globally

### Cost Estimation:
- **Small community (100 users)**: ~$5-10/month
- **Medium community (500 users)**: ~$15-25/month  
- **Large community (1000+ users)**: ~$30-50/month

## Step 9: Migration Plan

1. **Set up Firebase** (follow steps above)
2. **Update Flutter app** to use Firebase instead of local server
3. **Migrate existing data** from local JSON to Firestore
4. **Deploy updated app** to GitHub Pages
5. **Test with real users**

## Step 10: Next Steps

Would you like me to:
1. **Help set up the Firebase project**
2. **Update the Flutter app to use Firebase**
3. **Create the data migration scripts**
4. **Set up the security rules**

This approach eliminates the need for a separate backend server and gives you a production-ready, scalable solution! 