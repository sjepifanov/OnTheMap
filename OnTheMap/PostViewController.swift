//
//  PostViewController.swift
//  OnTheMap
//
//  Created by Sergei on 29/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class PostViewController: UIViewController, UITextViewDelegate {
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var webLinkTextView: UITextView!
	@IBOutlet weak var headerLabel: UILabel!
	@IBOutlet weak var informationTextView: UITextView!
	@IBOutlet weak var translucentView: UIView!
	@IBOutlet weak var cancelButton: UIButton!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var findOnTheMapButton: UIButton!
	
	//lazy var currentUser = UserInformation()
	lazy var annotation = MKPointAnnotation()
	lazy var client = HTTPClient()
	var mapString: String?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		findOnTheMapButton.layer.cornerRadius = 0.5
	}
	
	@IBAction func findOnTheMapButtonAction(sender: AnyObject) {
		if findOnTheMapButton.titleLabel?.text == "Find On The Map" { findOnTheMap() }
		if findOnTheMapButton.titleLabel?.text == "Submit" { submitStudentInfo() }
	}
	
	@IBAction func cancelButtonAction(sender: AnyObject) {
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	func findOnTheMap() {
		if informationTextView.text == "" {
			showAlert("Please provide location information"); return
		}
		activityIndicator.startAnimating()
		// Verify Address and add annotation to map
		geocodeAddress(informationTextView.text) { response in
			do {
				let annotation = try response()
				self.annotation = annotation
				self.mapString = self.informationTextView.text
				// Prepare view
				self.activityIndicator.stopAnimating()
				self.headerLabel.hidden = true
				self.informationTextView.hidden = true
				self.findOnTheMapButton.setTitle("Submit", forState: .Normal)
				self.translucentView.alpha = 0.6
				// Zoom map
				let center = annotation.coordinate
				let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0))
				self.mapView.setRegion(region, animated: true)
			} catch let error as NSError {
				self.activityIndicator.stopAnimating()
				self.showAlert(error.localizedDescription)
			}
		}
	}
	
	// Translate Address to GeoCode
	func geocodeAddress(address: String, handler:(() throws -> MKPointAnnotation) -> Void) {
		let geocoder = CLGeocoder()
		geocoder.geocodeAddressString(address) { data, error in
			guard let placeMarks = data
				else {
					handler { throw error! }; return
			}
			if placeMarks.count > 0 {
				let placeMark = placeMarks[0]
				guard let location = placeMark.location else { return }
				let annotation = MKPointAnnotation()
				annotation.coordinate = location.coordinate
				annotation.title = "\(DataProvider.Data.currentUser!.firstName) \(DataProvider.Data.currentUser!.lastName)"
				handler { return annotation }
			}
		}
	}
	
	func submitStudentInfo() {
		guard let _ = NSURL(string: webLinkTextView.text) else { showAlert("Invalid URL"); return }
		activityIndicator.startAnimating()
		let httpBody: [String : AnyObject] = [
			Constants.JSON.UniqueKey :DataProvider.Data.currentUser!.userId,
			Constants.JSON.FirstName : DataProvider.Data.currentUser!.firstName,
			Constants.JSON.LastName : DataProvider.Data.currentUser!.lastName,
			Constants.JSON.MapString : mapString!,
			Constants.JSON.Longitude : annotation.coordinate.longitude,
			Constants.JSON.Latitude : annotation.coordinate.latitude,
			Constants.JSON.MediaURL : webLinkTextView.text
		]
		for (key, value) in httpBody {
			print("key: \(key), value: \(value)")
		}
		
		client.postStudentInformation(httpBody) { response in
			do {
				let objectId = try response()
				print(objectId)
				self.activityIndicator.stopAnimating()
				self.showAlert("Information Posted.")
				self.dismissViewControllerAnimated(true, completion: nil)
			} catch let error as NSError {
				self.activityIndicator.stopAnimating()
				self.showAlert(error.localizedDescription)
			}
		}
	}
	
	// MARK: - Text View Delegate
	func textViewDidBeginEditing(textView: UITextView) {
		informationTextView.text = ""
		webLinkTextView.text = "http://"
	}
	
	func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
		if(text == "\n") {
			textView.resignFirstResponder()
			return false
		}
		return true
	}
}

