#!/bin/bash

# MacMeter Build Script
# This script builds the MacMeter app into a .app bundle

echo "?? Building MacMeter.app..."

# Clean previous builds
echo "?? Cleaning previous builds..."
rm -rf build/
rm -rf MacMeter.app

# Create build directory
mkdir -p build

# Build the app using swift build
echo "?? Compiling Swift code..."
swift build --configuration release

# Create the .app bundle structure
echo "?? Creating .app bundle..."
mkdir -p MacMeter.app/Contents/{MacOS,Resources}

# Copy the executable
echo "?? Copying executable..."
cp .build/release/MacMeter MacMeter.app/Contents/MacOS/

# Copy Info.plist
echo "?? Copying Info.plist..."
cp Info.plist MacMeter.app/Contents/

# Copy app icon
echo "?? Copying app icon..."
cp -r AppIcon.appiconset MacMeter.app/Contents/Resources/

# Copy all Swift files and resources
echo "?? Copying resources..."
cp -r Views/ MacMeter.app/Contents/Resources/
cp -r Models/ MacMeter.app/Contents/Resources/
cp -r Managers/ MacMeter.app/Contents/Resources/
cp -r Utils/ MacMeter.app/Contents/Resources/
cp -r Extensions/ MacMeter.app/Contents/Resources/
cp -r icon.png MacMeter.app/Contents/Resources/

# Make the app executable
chmod +x MacMeter.app/Contents/MacOS/MacMeter

echo "? MacMeter.app built successfully!"
echo "?? Location: C:\MacMeter/MacMeter.app"
echo "?? You can now run the app by double-clicking MacMeter.app"
