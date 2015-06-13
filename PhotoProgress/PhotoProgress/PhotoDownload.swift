/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
                PhotoDownload supports NSProgressReporting and "downloads" a file URL.
            
*/

import Foundation

class PhotoDownload: NSObject, NSProgressReporting {
    // MARK: Properties

    /// The URL to be downloaded.
    let downloadURL: NSURL
    
    /**
        The completionHandler is called once the download is finished with either 
        the downloaded data, or an `NSError`.
    */
    var completionHandler: ((data: NSData?, error: NSError?) -> Void)?

    let progress: NSProgress

    /// A class containing the fake parts of our download.
    private class DownloadState {
        /// The dispatch queue that all of our callbacks will be invoked on.
        var queue: dispatch_queue_t!

        /// The timer that drives the "download".
        var downloadTimer: dispatch_source_t?
        
        /// The error that our didFail callback should be called with.
        var downloadError: NSError?
 
        /// Whether or not we're paused.
        var isPaused = false
    }

    private var downloadState: DownloadState

    // MARK: Initializers
    
    init(URL: NSURL) {
        downloadURL = URL.copy() as! NSURL

        downloadState = DownloadState()
        
        progress = NSProgress()
        
        /*
            The progress starts out as indeterminate, since we don't know how many 
            bytes there are to download yet.
        */
        progress.totalUnitCount = -1

        /*
            Since our units are bytes, we use NSProgressKindFile so the NSProgress's
            localizedDescription and localizedAdditionalDescription return 
            something nicer.
        */
        progress.kind = NSProgressKindFile
        
        // We say we're a file operation so the localized descriptions are a little nicer.
        progress.setUserInfoObject(NSProgressFileOperationKindDownloading, forKey: NSProgressFileOperationKindKey)
    }
    
    /// Start the download. Can only be called once.
    func start() {
        assert(nil == downloadState.queue, "`downloadState.queue` must not be nil in \(__FUNCTION__).")
        
        // Fake a download.
        downloadState.queue = dispatch_queue_create("download queue", nil)
        dispatch_async(downloadState.queue) {
            do {
                // Fetch the data
                let data = try NSData(contentsOfURL: self.downloadURL, options: [])

                // Our parameters for the "download".
                
                // Update every 0.5 seconds.
                let interval: Double = 0.5
                
                // Bytes per second.
                let throughput: Double = 5000
                
                // Create a timer
                let downloadTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.downloadState.queue)

                self.downloadState.downloadTimer = downloadTimer
                
                var downloadedBytes = 0

                // Add a random delay to the start, to simulate latency.
                let randomMilliseconds = Int64(arc4random_uniform(500))
                
                let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * Double(NSEC_PER_SEC)) - Int64(randomMilliseconds * Int64(NSEC_PER_MSEC)))
                
                dispatch_source_set_timer(downloadTimer, delay, UInt64(interval * Double(NSEC_PER_SEC)), 0)

                dispatch_source_set_event_handler(downloadTimer) {
                    // Update the downloaded bytes.
                    downloadedBytes += Int(throughput * interval)
                
                    if downloadedBytes >= data.length {
                        // We've finished!
                        dispatch_source_cancel(downloadTimer)
                        return
                    }
                    
                    // Call out that we've "downloaded" new data.
                    self.didDownloadData(data, numberOfBytes: downloadedBytes)
                }
            
                dispatch_source_set_cancel_handler(downloadTimer) {
                    if downloadedBytes >= data.length {
                        // Call out that we finished "downloading" data.
                        self.didFinishDownload(data)
                    }
                    else {
                        // Call out that we finished "downloading" data.
                        self.didFailDownloadWithError(self.downloadState.downloadError!)
                    }
                    
                    self.downloadState.downloadTimer = nil
                }
                
                // Call out that we will begin to "download" data.
                self.willBeginDownload(data.length)
                
                dispatch_resume(downloadTimer)
            }
            catch let error {
                // Call out that we failed to "download" data.
                self.didFailDownloadWithError(error as NSError)
            }
        }
    }
    
    private func failDownloadWithError(error: NSError) {
        guard let downloadTimer = downloadState.downloadTimer else { return }

        dispatch_async(downloadState.queue) {
            /*
                Set the downloadError, then cancel. The timer's cancellation handler 
                will invoke the fail callback with the error, if we haven't finished
                by then.
            */
            self.downloadState.downloadError = error
            
            // Resume the timer before cancelling it.
            if self.downloadState.isPaused {
                dispatch_resume(downloadTimer)
            }
            
            dispatch_source_cancel(downloadTimer)
        }
    }
    
    private func suspendDownload() {
        if let downloadTimer = downloadState.downloadTimer {
            dispatch_async(downloadState.queue) {
                // Do not suspend if we're already suspended, or if we're cancelled.
                guard !self.downloadState.isPaused && 0 == dispatch_source_testcancel(downloadTimer) else { return }

                // Simply suspend the timer.
                self.downloadState.isPaused = true
                dispatch_suspend(downloadTimer)
            }
        }
    }
    
    private func resumeDownload() {
        if let downloadTimer = downloadState.downloadTimer {
            dispatch_async(downloadState.queue) {
                // Only resume if we're suspended and we're not cancelled.
                guard self.downloadState.isPaused && 0 == dispatch_source_testcancel(downloadTimer) else { return }
                
                // Simply resume the timer.
                dispatch_resume(downloadTimer)
                self.downloadState.isPaused = false
            }
        }
    }
    
    private func callCompletionHandler(data data: NSData?, error: NSError?) {
        // Call the completion handler if we have one.
        completionHandler?(data:data, error: error)
        
        // Break any retain cycles by setting it to nil.
        completionHandler = nil
    }

    // Called when the "download" begins
    func willBeginDownload(downloadLength: Int) {
        progress.totalUnitCount = Int64(downloadLength)

        progress.cancellable = true
        progress.cancellationHandler = {
            let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
            self.failDownloadWithError(error)
        }

        progress.pausable = true

        progress.pausingHandler = {
            self.suspendDownload()
        }
        
        progress.resumingHandler = {
            self.resumeDownload()
        }
    }
    
    /**
        Called periodically as the "download" occurs. data and numberOfBytes are
        aggregated values, and contain the entire download up to that point.
    */
    func didDownloadData(data: NSData, numberOfBytes: Int) {
        progress.completedUnitCount = Int64(numberOfBytes)
    }
    
    /// Called when the "download" is completed.
    func didFinishDownload(downloadedData: NSData) {
        progress.completedUnitCount = Int64(downloadedData.length)
        callCompletionHandler(data: downloadedData, error: nil)
    }
    
    /// Called if an error occurs during the "download"
    func didFailDownloadWithError(error: NSError) {
        callCompletionHandler(data: nil, error: error)
    }
}
