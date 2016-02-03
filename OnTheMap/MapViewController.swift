//
//  MapViewController.swift
//  OnTheMap
//
//  Created by Sergei on 29/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import UIKit
import MapKit


class MapViewController: UIViewController, MKMapViewDelegate {
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	//lazy var currentUser = UserInformation()
	lazy var client = HTTPClient()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let logoutButton = UIBarButtonItem(title: "Logout", style: .Plain, target: self, action: "logoutBarButtonItemClicked")
		let pinBarButton = UIBarButtonItem(image: UIImage(named: "pin"), style: .Plain, target: self, action: "pinBarButtonItemClicked")
		let refreshBarButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refreshBarButtonItemClicked")
		self.navigationItem.leftBarButtonItem = logoutButton
		self.navigationItem.rightBarButtonItems = [refreshBarButton, pinBarButton]
		
		mapView.delegate = self

		showAlert("Hello, " + DataProvider.Data.currentUser!.firstName + " " + DataProvider.Data.currentUser!.lastName)
		mapView.alpha = 0.5
		activityIndicator.startAnimating()
		getLocationInformation()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	// MARK: - Actions
	// Logout
	func logoutBarButtonItemClicked() {
		Queue.UserInitiated.execute {
			self.client.endCurrentSession { response in
				do {
					let _ = try response()
					Queue.Main.execute { self.dismissViewControllerAnimated(true, completion: nil) }
				} catch let error as NSError {
					Queue.Main.execute {
						self.showAlert(error.localizedDescription)
						self.dismissViewControllerAnimated(true, completion: nil)
					}
				}
			}
		}
	}
	
	// Call Information View controller
	func pinBarButtonItemClicked() {
		let controller = storyboard!.instantiateViewControllerWithIdentifier(String(PostViewController)) as! PostViewController
		// controller.currentUser = currentUser
		navigationController?.navigationBarHidden = true
		navigationController?.toolbarHidden = true
		showViewController(controller, sender: self)
	}
	
	// Refresh map view data
	func refreshBarButtonItemClicked() {
		getLocationInformation()
	}
	
	// MARK: - Methods
	func getLocationInformation() {
		let parameters = ["limit" : "100", "order" : "-updatedAt"]
		Queue.UserInitiated.execute {
			self.client.getStudentLocations(parameters) { response in
				do {
					let locations = try response() as [StudentInformation]
					DataProvider.Data.studentInformation = locations
					let annotations = self.createAnnotationsArray(locations)
					DataProvider.Data.annotations = annotations
					Queue.Main.execute {
						self.activityIndicator.stopAnimating()
						self.mapView.alpha = 1.0
						self.mapView.addAnnotations(annotations)
					}
				} catch let error as NSError {
					Queue.Main.execute {
						self.activityIndicator.stopAnimating()
						self.mapView.alpha = 1.0
						self.showAlert(error.localizedDescription)
					}
				}
			}
		}
	}
	
	func createAnnotationsArray(studentsLocations: [StudentInformation]) -> [MKPointAnnotation] {
		let annotations = studentsLocations.map { (location: StudentInformation) -> MKPointAnnotation in
			let lat = CLLocationDegrees(location.latitude)
			let long = CLLocationDegrees(location.longitude)
			let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
			let first = location.firstName
			let last = location.lastName
			let mediaURL = location.mediaURL
			let annotation = MKPointAnnotation()
			annotation.coordinate = coordinate
			annotation.title = "\(first) \(last)"
			annotation.subtitle = mediaURL
			return annotation
		}
		return annotations
	}
	
	// MARK: - Map View Delegate
	
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		// If the annotation is the user location, just return nil.
		if annotation.isKindOfClass(MKUserLocation) { return nil }
		// Try to dequeue an existing pin view first.
		let reuseID = "pin"
		var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseID) as? MKPinAnnotationView
		// If no pin view exist create a new one.
		guard let pin = pinView else {
			pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
			guard let pin = pinView else { return nil }
			pin.pinTintColor = .redColor()
			pin.animatesDrop = true
			pin.canShowCallout = true
			pin.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
			return pin
		}
		pin.annotation = annotation
		return pin
	}
	
	// This delegate method is implemented to respond to taps. It opens the system browser
	// to the URL specified in the annotationViews subtitle property.
	func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		if control == annotationView.rightCalloutAccessoryView {
			guard let
				subtitle = annotationView.annotation?.subtitle,
				urlString = subtitle,
				url = NSURL(string: (urlString))
				else { return }
			UIApplication.sharedApplication().openURL(url)
		}
	}
}