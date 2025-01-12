#!/bin/bash
set -e
set -x

projectName=Shoppinglist
projectId=de.luedtke.shoppinglist
executableName=shoppinglist

# Build Flatpak
echo "$(pwd)"

mkdir -p $projectName
tar -xf $projectName-Linux-Portable.tar.gz -C $projectName

# Copy the portable app to the Flatpak-based location.
cp -r $projectName /app/
chmod +x /app/$projectName/$executableName
mkdir -p /app/bin
ln -s /app/$projectName/$executableName /app/bin/$executableName

# Install the icon.
iconDir=/app/share/icons/hicolor/scalable/apps
mkdir -p $iconDir
cp -r $projectId.png $iconDir/

# Install the desktop file.
desktopFileDir=/app/share/applications
mkdir -p $desktopFileDir
cp -r $projectId.desktop $desktopFileDir/

# Install the AppStream metadata file.
metadataDir=/app/share/metainfo
mkdir -p $metadataDir
cp -r $projectId.metainfo.xml $metadataDir/
