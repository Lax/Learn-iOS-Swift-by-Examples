# AVCam-iOS

AVCam demonstrates how to use the AVFoundation capture API to record movies and capture photos.

## Overview

The sample has a record button for recording movies, a photo button for capturing photos, a Live Photo mode button for enabling Live Photo capture, a Depth Data delivery button for enabling depth data delivery in capture, a capture mode control for toggling between photo and movie capture modes, and a camera button for switching between front and back cameras (on supported devices). AVCam runs only on an actual device, either an iPad or iPhone, and cannot be run in Simulator.

## Requirements

### Build

Xcode 9.0, iOS 11.0 SDK

### Runtime

iOS 11.0 or later

## Changes from Previous Version

- Adopt AVCapturePhoto
- Add HEIF and HEVC support
- Include Depth Data Delivery in photo capture
- Upgrade from Swift 3 to Swift 4
- Bug fixes
