# TableViewPlayground

## Description

This example demonstrates the View Based TableView. The demo focuses on three areas:
1. Basic TableView, 2. Complex TableView, 3. Complex OutlineView.

The same model is shared between the Complex TableView and OutlineView classes.

## Requirements

### Build Requirements

macOS 10.12 SDK or later

### Runtime Requirements

macOS 10.12 or later

## Packing List

ATDesktopEntity.h/.m: 
 The basic sample model for the application. 

ATApplicationController.h/.m:
 Main controller for the application.

ATBasicTableViewWindowController.h/m:
 Basic controller implementation for a basic View Based TableView.

ATColorTableController.h/.m:
 Controller for the color table popup used in the ATComplextTableViewController example

ATColorView.h/.m:
 Simple view that adds an animatable background color.

ATComplexOutlineController.h/.m:
 Complex Outline View example controller.

ATComplexTableViewController.h/.m:
 Complex Table View example controller. 

ATObjectTableRowView.h/.m:
 Extends NSTableRowView by adding an objectValue for the row.

ATSampleWindowRowView.h/.m:
 Extends NSTableRowView by adding custom background drawing.

ATTableCellView.h:
 Extends NSTableCellView primarily for adding outlets to be hooked up in IB.

English.proj:
 Localized NIBs.


Copyright (C) 2010-2017 Apple Inc. All rights reserved.
