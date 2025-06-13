# 🚀 Deploy HomeConnect Backend to Railway

## Step 1: Setup Railway Account
1. Go to [Railway.app](https://railway.app)
2. Sign up with GitHub account
3. Connect your GitHub repository

## Step 2: Deploy from GitHub
1. Click "New Project" → "Deploy from GitHub repo"
2. Select your `homeconnect-app` repository
3. Railway will automatically detect the Dockerfile

## Step 3: Configure Environment
- Railway will auto-set `PORT` environment variable
- Your app will be available at: `https://your-app.railway.app`

## Step 4: Update Flutter App
Once deployed, update your Flutter app's server URLs:

```dart
// In lib/main.dart, replace localhost URLs with your Railway URL
'https://your-app.railway.app',  // Your Railway URL
'http://localhost:5000',         // Keep for local development
```

## Step 5: Rebuild and Deploy Flutter
```bash
flutter build web --release
# Copy build/web/* to your GitHub Pages repo
# Push to GitHub Pages
```

## 🎯 Your app will be globally accessible!
- Backend: `https://your-app.railway.app`
- Frontend: `https://jaitech110.github.io/homeconnect-app/`
- All users worldwide will share the same data! 