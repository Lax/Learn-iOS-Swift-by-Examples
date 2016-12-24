/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `MapViewController` allow the user to select a location using the map.
                This location will be passed back to the sender when the user saves the view.
*/

import UIKit
import MapKit

/**
    Allows the sender to get notified when there
    have been changes to the region.
*/
protocol MapViewControllerDelegate {
    /**
        Notifies the delegate that the `MapViewController`'s
        region has been updated.
    */
    func mapViewDidUpdateRegion(region: CLCircularRegion)
}

/**
    A view controller which allows the selection of a
    circular region on a map.
*/
class MapViewController: UIViewController, UISearchBarDelegate, CLLocationManagerDelegate, MKMapViewDelegate {
    // MARK: Types
    
    struct Identifiers {
        static let circularRegion = "MapViewController.Region"
    }
    
    /// When the view loads, we'll zoom to this longitude/latitude span delta.
    static let InitialZoomDelta: Double = 0.0015
    
    /// When the view loads, we'll zoom into this span.
    static let InitialZoomSpan = MKCoordinateSpan(latitudeDelta: MapViewController.InitialZoomDelta, longitudeDelta: MapViewController.InitialZoomDelta)
    
    // The inverse of the percentage of the map view that should be captured in the region.
    static let MapRegionFraction: Double = 4.0
    
    // The size of the query region with respect to the map's zoom.
    static let RegionQueryDegreeMultiplier: Double = 5.0
    
    // MARK: Properties
    
    @IBOutlet weak var overlayView: MapOverlayView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    
    var delegate: MapViewControllerDelegate?
    
    var targetRegion: CLCircularRegion?
    
    var circleOverlay: MKCircle? {
        didSet {
            // Remove the old overlay (if exists)
            if let oldOverlay = oldValue {
                mapView.removeOverlay(oldOverlay)
            }
            
            // Add the new overlay (if exists)
            if let overlay = circleOverlay {
                mapView.addOverlay(overlay)
            }
        }
    }
    
    var locationManager = CLLocationManager()
    
    // MARK: View Methods
    
    /// Configures the map view, search bar and location manager.
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.pitchEnabled = false
        locationManager.delegate = self
    }
    
    /// Loads the user's location and zooms the target region.
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        if let region = targetRegion {
            annotateAndZoomToRegion(region)
        }
    }
    
    /// Updates the overlay when the orientation changes.
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        overlayView.setNeedsDisplay()
    }
    
    // MARK: Button Actions
    
    /**
        Generates a map region based on the map's position
        and zoom, then notifies the delegate that the region has changed.
        This will dismiss the view.
    */
    @IBAction func didTapSaveButton(sender: UIBarButtonItem) {
        let circleDegreeDelta: CLLocationDegrees
        let pointOnCircle: CLLocation
        
        if mapView.region.span.latitudeDelta > mapView.region.span.longitudeDelta {
            circleDegreeDelta = mapView.region.span.longitudeDelta / MapViewController.MapRegionFraction
            pointOnCircle = CLLocation(latitude: mapView.region.center.latitude, longitude: mapView.region.center.longitude - circleDegreeDelta)
        }
        else {
            circleDegreeDelta = mapView.region.span.latitudeDelta / MapViewController.MapRegionFraction
            pointOnCircle = CLLocation(latitude: mapView.region.center.latitude - circleDegreeDelta, longitude: mapView.region.center.longitude)
        }
        
        
        let mapCenterLocation = CLLocation(latitude: mapView.region.center.latitude, longitude: mapView.region.center.longitude)
        let distance = pointOnCircle.distanceFromLocation(mapCenterLocation)
        let genericRegion = CLCircularRegion(center: mapView.region.center, radius: distance, identifier: Identifiers.circularRegion)
        
        circleOverlay = MKCircle(centerCoordinate: genericRegion.center, radius: genericRegion.radius)
        delegate?.mapViewDidUpdateRegion(genericRegion)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    /// Dismisses the view without notifying the delegate.
    @IBAction func didTapCancelButton(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Search Bar Methods
    
    /**
        Dismisses the keyboard and runs a new search from the
        search bar.
    */
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        mapView.removeAnnotations(mapView.annotations)
        performSearch()
    }
    
    // MARK: Location Manager Methods
    
    /// Zooms to the user's location if the region is not set.
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last else { return }
        if targetRegion != nil {
            // Do not zoom to the user's location if there is already a target region.
            return
        }
        let newRegion = MKCoordinateRegion(center: lastLocation.coordinate, span: MapViewController.InitialZoomSpan)
        mapView.setRegion(newRegion, animated: true)
    }
    
    /**
        The method is required.
        Simply logs the error.
    */
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("System: Location Manager Error: \(error)")
    }
    
    /**
        When the user updates the authorization status, we want to
        zoom to their current location by asking for it.
    */
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        locationManager.requestLocation()
    }
    
    // MARK: Helper Methods
    
    /**
        Updates the region overlay and zooms the map region
        
        - parameter region: The new `CLCircularRegion`.
    */
    private func annotateAndZoomToRegion(region: CLCircularRegion) {
        circleOverlay = MKCircle(centerCoordinate: region.center, radius: region.radius)
        let multiplier = MapViewController.MapRegionFraction
        let mapRegion = MKCoordinateRegionMakeWithDistance(region.center, region.radius*multiplier, region.radius*multiplier)
        mapView.setRegion(mapRegion, animated: false)
    }
    
    /**
        Performs a natural language search for locations
        in the map's region that match the `searchBar`'s text.
    */
    private func performSearch() {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBar.text
        let multiplier = MapViewController.RegionQueryDegreeMultiplier
        let querySpan = MKCoordinateSpan(latitudeDelta: mapView.region.span.latitudeDelta*multiplier, longitudeDelta: mapView.region.span.longitudeDelta*multiplier)
        request.region = MKCoordinateRegion(center: mapView.region.center, span: querySpan)
        
        let search = MKLocalSearch(request: request)
        
        var matchingItems = [MKMapItem]()
        
        search.startWithCompletionHandler { response, error in
            let mapItems: [MKMapItem] = response?.mapItems ?? []
            for item in mapItems {
                matchingItems.append(item)
                let annotation = MKPointAnnotation()
                annotation.coordinate = item.placemark.coordinate
                annotation.title = item.name
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    /// - returns:  An `MKOverlayRenderer` with our custom stroke and fill.
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.fillColor = UIColor.blueColor().colorWithAlphaComponent(0.2)
        circleRenderer.strokeColor = UIColor.blackColor()
        circleRenderer.lineWidth = 2.0
        return circleRenderer
    }
}
