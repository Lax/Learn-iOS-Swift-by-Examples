/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The main interface controller.
 */

import WatchKit
import Foundation


class MainInterfaceController: WKInterfaceController, WKExtensionDelegate, URLSessionDownloadDelegate {
    // MARK: Properties
    
    let sampleDownloadURL = URL(string: "http://devstreaming.apple.com/videos/wwdc/2015/802mpzd3nzovlygpbg/802/802_designing_for_apple_watch.pdf?dl=1")!
    
    @IBOutlet var timeDisplayLabel: WKInterfaceLabel!
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .long
        
        return formatter
    }()
    
    // MARK: WKInterfaceController
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        WKExtension.shared().delegate = self
        updateDateLabel()
    }
    
    // MARK: WKExtensionDelegate
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task : WKRefreshBackgroundTask in backgroundTasks {
            print("received background task: ", task)
            // only handle these while running in the background
            if (WKExtension.shared().applicationState == .background) {
                if task is WKApplicationRefreshBackgroundTask {
                    // this task is completed below, our app will then suspend while the download session runs
                    print("application task received, start URL session")
                    scheduleURLSession()
                }
            }
            else if let urlTask = task as? WKURLSessionRefreshBackgroundTask {
                let backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: urlTask.sessionIdentifier)
                let backgroundSession = URLSession(configuration: backgroundConfigObject, delegate: self, delegateQueue: nil)
                
                print("Rejoining session ", backgroundSession)
            }
            // make sure to complete all tasks, even ones you don't handle
            task.setTaskCompleted()
        }
    }

    // MARK: Snapshot and UI updating
    
    func scheduleSnapshot() {
        // fire now, we're ready
        let fireDate = Date()
        WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: fireDate, userInfo: nil) { error in
            if (error == nil) {
                print("successfully scheduled snapshot.  All background work completed.")
            }
        }
    }
    
    func updateDateLabel() {
        let currentDate = Date()
        timeDisplayLabel.setText(dateFormatter.string(from: currentDate))
    }
    
    // MARK: URLSession handling
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("NSURLSession finished to url: ", location)
        updateDateLabel()
        scheduleSnapshot()
    }
    
    func scheduleURLSession() {
        let backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: NSUUID().uuidString)
        backgroundConfigObject.sessionSendsLaunchEvents = true
        let backgroundSession = URLSession(configuration: backgroundConfigObject)
        
        let downloadTask = backgroundSession.downloadTask(with: sampleDownloadURL)
        downloadTask.resume()
    }
    
    // MARK: IB actions
    
    @IBAction func ScheduleRefreshButtonTapped() {
        // fire in 20 seconds
        let fireDate = Date(timeIntervalSinceNow: 20.0)
        // optional, any SecureCoding compliant data can be passed here
        let userInfo = ["reason" : "background update"] as NSDictionary
        
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: userInfo) { (error) in
            if (error == nil) {
                print("successfully scheduled background task, use the crown to send the app to the background and wait for handle:BackgroundTasks to fire.")
            }
        }
    }
    
}
