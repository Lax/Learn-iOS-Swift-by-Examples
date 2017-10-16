# AVCamPhotoFilter

Using AV Foundation to capture photos with image processing.

## Overview

AVCamPhotoFilter demonstrates how to use AV Foundation's capture API to draw a live camera preview and capture photos with image processing (filtering) applied.

Two "rosy" filters are provided: one is implemented using Core Image, and the other is implemented as a Metal shader. A horizontal swipe on the camera preview switches between the filters.

On devices that support depth map delivery, AVCamPhotoFilter provides depth data visualization (via a Metal shader). When depth visualization is enabled, a slider enables crossfading between video and depth visualization.

AVCamPhotoFilter also shows how to properly propagate sample buffer attachments and attributes, including EXIF metadata and color space information (e.g. wide gamut).

## Requirements

### Build

Xcode 9.0 or later; iOS 11.0 SDK or later.

- Note: **AVCamPhotoFilter can only be built for an actual iOS device, not for the simulator.**

### Runtime

iOS 11.0 or later

- Note: **AVCamPhotoFilter can only be run on an actual iOS device, not on the simulator.**
