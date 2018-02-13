# CloudCaptions: How integrate CloudKit into a real application

This sample shows how to use CloudKit to upload and retrieve CKRecords and associated assets. In this example, there are two record types, an “Image” record type and a “Post” record type. Users are able to upload their own photos or select an image already found in an image record type. This example also uses an NSPredicate in its CKQueries to filter results based on tags.

## How to set up

The CloudCaptions.entitlements file lists two entitlements: com.apple.developer.icloud-container-identifiers and com.apple.developer.icloud-services. These are both set automatically by going to the Capabilities tab of the CloudCaptions project, switching iCloud on, and checking the CloudKit checkbox.

iCloud should be set to use the default container. It should be called iCloud.(Your Bundle ID)

Try running CloudCaptions on your device. You may run into provisioning issues. Xcode should be able to take care of most of these problems for you.

Once the app is running, you may see a CKInternalError in the console output. To resolve this, all you need to do is view your container in CloudKit dashboard. You can get to it by going to your project's capabilities tab and clicking the “CloudKit Dashboard” button under iCloud. Keep it open because you will need this later.

Try running the app again. You will start seeing CKUnknownItem errors in the log output. These occur because we're querying for records that CloudKit has never seen before. To resolve these, all we need to do is upload a new post. Tap compose, then tap Take Photo, take a picture and write a caption. Finally, tap post.

You will no longer see CKUnknownItem errors in the console. You now will start seeing CKInvalidArgument errors. By default, CloudKit can't sort or query by record metadata like creation date or last modified date. To change this, go to your container's dashboard and click Record Types. You should see two new record types: Image and Post. For each record type, click Metadata Index and check the box to sort by date created.

Run CloudCaptions one more time (or pull to refresh) and you should see the post you just made. Your container is now set up to use CloudCaptions.

## Requirements

### Build

Xcode 6.0 and iOS 8 SDK

### Runtime

iOS 8 or later

Copyright (C) 2014 Apple Inc. All rights reserved.
