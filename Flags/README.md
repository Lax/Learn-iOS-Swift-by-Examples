# Flags: A demonstration of automatic RTL support in Asset Catalogs and UIStackViews

This sample project illustrates the usage of Directional Image Assets in an iOS project. By using Directional Image Assets, images shown on-screen can automatically adapt to different layout directions (e.g. right-to-left contexts when running in Arabic or Hebrew), without requiring special code for loading different image variations at runtime.

This can be seen in the project by:

1. Running the application
2. Tapping on 'Start'

The 'Back' and 'Forward' arrows have been marked as mirrored images in the Xcode project's asset catalog. Therefore, when running in a right-to-left context, these images will automatically mirror themselves horizontally. This can be seen by:

1. Opening up the Scheme editor in Xcode
2. Select 'Run' on the left of the drop-down
3. With the 'Options' tab selected, override the 'Application Language' setting to 'Right-to-left pseudolanguage'

When running in the environment above, both the forward and back arrows will be pointing in the opposite direction, to reflect their new positions relative to English UI.

## Requirements

### Build

Xcode 8.0 or later; iOS 10.0 SDK or later

### Runtime

iOS 10.0 or later

Copyright (C) 2016 Apple Inc. All rights reserved.
