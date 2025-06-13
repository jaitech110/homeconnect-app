# 🚀 Deploy HomeConnect Backend to Render.com

## Step 1: Setup Render Account
1. Go to [Render.com](https://render.com)
2. Sign up with GitHub account
3. Connect your GitHub repository

## Step 2: Create Web Service
1. Click "New" → "Web Service"
2. Connect your GitHub repo: `homeconnect-app`
3. Configure:
   - **Name**: `homeconnect-backend`
   - **Root Directory**: `dart_backend`
   - **Environment**: `Docker`
   - **Plan**: `Free`
   - **Auto-Deploy**: `Yes`

## Step 3: Environment Variables
Render will automatically set:
- `PORT=10000` (automatically configured)

## Step 4: Deploy
- Click "Create Web Service"
- Wait for build (5-10 minutes)
- Your app will be at: `https://homeconnect-backend.onrender.com`

## Step 5: Test Deployment
Visit: `https://homeconnect-backend.onrender.com/test`
Should see: `{"message":"Dart backend with in-memory storage is working!"}`

## Step 6: Update Flutter App URLs
```dart
// In lib/main.dart, add your Render URL as first priority:
if (kIsWeb) {
  serverUrls = [
    'https://homeconnect-backend.onrender.com',  // Production server
    'http://localhost:5000',                      // Local development
    'http://192.168.18.16:5000',                 // Local network
  ];
}
```

## Step 7: Rebuild and Deploy Flutter
```bash
cd homeconnect_app
flutter build web --release
Copy-Item -Path "build\web\*" -Destination "." -Recurse -Force
git add .
git commit -m "Update with cloud backend URL"
git push origin gh-pages
```

## 🌍 Your app is now globally accessible!
- ✅ Backend: `https://homeconnect-backend.onrender.com`
- ✅ Frontend: `https://jaitech110.github.io/homeconnect-app/`
- ✅ Shared data across all users worldwide
- ✅ No network restrictions - works on any device, any network! 