//
//  MapViewControllerDelegate.swift
//  OnTheMap
//
//  Created by Sergei on 04/02/16.
//  Copyright © 2016 Sergei. All rights reserved.
//
import MapKit

// MARK: - Extension MapViewController. Map View Delegate
extension MapViewController: MKMapViewDelegate {
	
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
