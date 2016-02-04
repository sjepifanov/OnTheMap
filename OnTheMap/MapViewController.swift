//
//  MapViewController.swift
//  OnTheMap
//
//  Created by Sergei on 29/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, ShowAlertProtocol, DataProviderDelegate {
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	// MARK: - View
	override func viewDidLoad() {
		super.viewDidLoad()
		configureNavigationItems()
		mapView.delegate = self
		mapView.alpha = 0.5
		activityIndicator.startAnimating()
		connectDataProvider()
		DataProvider.UserData.getData()
		DataProvider.Locations.getData()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		self.activityIndicator.stopAnimating()
		self.mapView.alpha = 1.0
	}
	
	// MARK: - Actions
	// Call Information View controller
	func pinBarButtonItemClicked() {
		showPostViewController()
	}
	
	// Refresh map view data
	func refreshBarButtonItemClicked() {
		connectDataProvider()
		if let annotations = DataProvider.Data.annotations {
			mapView.removeAnnotations(annotations)
		}
		activityIndicator.startAnimating()
		mapView.alpha = 0.5
		DataProvider.Locations.getData()
	}
	
	// Logout
	func logoutBarButtonItemClicked() {
		DataProvider.EndSession.endSession()
	}
	
	// MARK: - Data Provider Delegate
	// Here we recieving responses from Data Provider and react accordingly
	func dataProvider(dataProvider: DataProvider, gotUserData succeed: Bool) {
		if let currentUser = DataProvider.Data.currentUser {
			showAlert("Hello, " + currentUser.firstName + " " + currentUser.lastName)
		}
	}
	
	func dataProvider(dataProvider: DataProvider, gotAnnotations succeed: Bool) {
		self.activityIndicator.stopAnimating()
		self.mapView.alpha = 1.0
		guard let annotations = DataProvider.Data.annotations else { return }
		self.mapView.addAnnotations(annotations)
	}
	
	func dataProvider(dataProvider: DataProvider, gotLocations: Bool) {
		DataProvider.Annotations.getData()
	}
	
	func dataProvider(dataProvider: DataProvider, didError error: NSError) {
		self.activityIndicator.stopAnimating()
		self.mapView.alpha = 1.0
		showAlert(error.localizedDescription)
	}
	
	func dataProvider(dataProvider: DataProvider, endSession succeed: Bool) {
		if succeed {
			dismissViewControllerAnimated(true, completion: nil)
		} else {
			showAlertAndDismissViewOnOkTap("Unable to End the Session.")
		}
	}
	
	// Unimplemented Delegates
	func dataProvider(dataProvider: DataProvider, gotLocationFromAddress succeed: Bool) {}
	func dataProvider(dataProvider: DataProvider, didSucceed succeed: Bool) {}
	
	// MARK: - Helpers
	func connectDataProvider () {
		DataProvider.Connect.client = HTTPClient()
		DataProvider.Connect.delegate = self
	}
	
	func disconnectDataProvider () {
		DataProvider.Connect.client = nil
		DataProvider.Connect.delegate = nil
	}
	
	func configureNavigationItems() {
		let logoutButton = UIBarButtonItem(title: "Logout", style: .Plain, target: self, action: "logoutBarButtonItemClicked")
		let pinBarButton = UIBarButtonItem(image: UIImage(named: "pin"), style: .Plain, target: self, action: "pinBarButtonItemClicked")
		let refreshBarButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refreshBarButtonItemClicked")
		navigationItem.leftBarButtonItem = logoutButton
		navigationItem.rightBarButtonItems = [refreshBarButton, pinBarButton]
	}
	
	func showPostViewController() {
		let controller = storyboard!.instantiateViewControllerWithIdentifier(String(PostViewController)) as! PostViewController
		let navController = UINavigationController(rootViewController: controller)
		navController.navigationBarHidden = true
		showViewController(navController, sender: self)
	}
}