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

class PostViewController: UIViewController, UITextViewDelegate, ShowAlertProtocol, DataProviderDelegate {
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var webLinkTextView: UITextView!
	@IBOutlet weak var headerLabel: UILabel!
	@IBOutlet weak var informationTextView: UITextView!
	@IBOutlet weak var translucentView: UIView!
	@IBOutlet weak var cancelButton: UIButton!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var findOnTheMapButton: UIButton!
	
	// MARK: - View
	override func viewDidLoad() {
		super.viewDidLoad()
		connectDataProvider()
		findOnTheMapButton.layer.cornerRadius = 5
		
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
	}
	
	// MARK: - Actions
	@IBAction func findOnTheMapButtonAction(sender: AnyObject) {
		if findOnTheMapButton.titleLabel?.text == "Find On The Map" { findOnTheMap() }
		if findOnTheMapButton.titleLabel?.text == "Submit" { submitStudentInfo() }
	}
	
	@IBAction func cancelButtonAction(sender: AnyObject) {
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	// MARK: - Methods
	// Try to reverse geoCode provided address. If succeed return prepared Annotation
	func findOnTheMap() {
		if informationTextView.text == "" {
			showAlert("Please provide location information"); return
		}
		activityIndicator.startAnimating()
		DataProvider.AnnotationFromAddress(informationTextView.text).getData()
		if let _ = DataProvider.Data.currentUser {
			// Save mapString to currentUser
			DataProvider.Data.currentUser?.mapString = informationTextView.text
		}
	}
	
	func submitStudentInfo() {
		guard let _ = NSURL(string: webLinkTextView.text) else { showAlert("Invalid URL"); return }
		activityIndicator.startAnimating()
		if let _ = DataProvider.Data.currentUser {
			// Save mediaURL to userInfo. Now we should have all the information to post.
			DataProvider.Data.currentUser?.mediaURL = webLinkTextView.text
		}
		DataProvider.UserData.postData()
	}
	
	// MARK: - DataProviderDelegate
	func dataProvider(dataProvider: DataProvider, gotLocationFromAddress succeed: Bool) {
		guard let annotation = DataProvider.Data.annotationFromAddress else { return }
		// Prepare view
		activityIndicator.stopAnimating()
		headerLabel.hidden = true
		informationTextView.hidden = true
		findOnTheMapButton.setTitle("Submit", forState: .Normal)
		translucentView.alpha = 0.6
		// Zoom map
		let center = annotation.coordinate
		let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0))
		mapView.setRegion(region, animated: true)
	}
	
	func dataProvider(dataProvider: DataProvider, didSucceed succeed: Bool) {
		activityIndicator.stopAnimating()
		showAlertAndDismissViewOnOkTap("Information posted.")
	}
	
	func dataProvider(dataProvider: DataProvider, didError error: NSError) {
		activityIndicator.stopAnimating()
		showAlert(error.localizedDescription)
	}
	
	func dataProvider(dataProvider: DataProvider, endSession succeed: Bool) {}
	func dataProvider(dataProvider: DataProvider, gotLocations succeed: Bool) {}
	func dataProvider(dataProvider: DataProvider, gotAnnotations succeed: Bool) {}
	func dataProvider(dataProvider: DataProvider, gotUserData succeed: Bool) {}
	
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
	
	// MARK: - Helpers
	func connectDataProvider () {
		DataProvider.Connect.client = HTTPClient()
		DataProvider.Connect.delegate = self
	}
	
	func disconnectDataProvider () {
		DataProvider.Connect.client = nil
		DataProvider.Connect.delegate = nil
	}
}