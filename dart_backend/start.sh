#!/bin/bash
echo "🚀 Starting HomeConnect Backend..."
echo "📂 Current directory: $(pwd)"
echo "📋 Environment: $NODE_ENV"
echo "🌐 Port: ${PORT:-5000}"

# Install dependencies if needed
echo "📦 Installing dependencies..."
dart pub get

# Start the server
echo "🔥 Starting Dart server..."
dart run bin/server.dart 