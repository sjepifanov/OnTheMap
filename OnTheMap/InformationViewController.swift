//
//  SecondViewController.swift
//  OnTheMap
//
//  Created by Sergei on 29/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import UIKit

class InformationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ShowAlertProtocol, DataProviderDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	// MARK: - View
	override func viewDidLoad() {
		super.viewDidLoad()
		configureNavigationItems()
		tableView.delegate = self
		tableView.dataSource = self
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		tableView.reloadData()
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		self.activityIndicator.stopAnimating()
	}
	
	// MARK: - Actions
	// Call Post View controller
	func pinBarButtonItemClicked() {
		showPostViewController()
	}
	
	// Refresh map view and get new set of data
	func refreshBarButtonItemClicked() {
		connectDataProvider()
		DataProvider.Data.studentInformation = nil
		tableView.reloadData()
		activityIndicator.startAnimating()
		DataProvider.Locations.getData()
	}
	
	// Logout
	func logoutBarButtonItemClicked() {
		DataProvider.EndSession.endSession()
	}
	
	// MARK: - Table View Delegate
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return DataProvider.Data.studentInformation?.count ?? 0
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cellReuseIdentifier = "StudentInformationViewCell"
		let student = DataProvider.Data.studentInformation?[indexPath.row]
		let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier)!
		cell.textLabel?.text = (student?.firstName)! + " " + (student?.lastName)!
		cell.imageView?.image = UIImage(named: "pin")
		cell.imageView?.contentMode = .ScaleAspectFit
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let
			mediaUrl = DataProvider.Data.studentInformation?[indexPath.row].mediaURL,
			url = NSURL(string: mediaUrl)
		else { return }
		UIApplication.sharedApplication().openURL(url)
	}
	
	// MARK: - Data Provider Delegate
	func dataProvider(dataProvider: DataProvider, gotLocations succeed: Bool) {
		activityIndicator.stopAnimating()
		tableView.reloadData()
	}
	
	func dataProvider(dataProvider: DataProvider, didError error: NSError) {
		activityIndicator.stopAnimating()
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
	func dataProvider(dataProvider: DataProvider, didSucceed succeed: Bool) {}
	func dataProvider(dataProvider: DataProvider, gotLocationFromAddress succeed: Bool) {}
	func dataProvider(dataProvider: DataProvider, gotAnnotations succeed: Bool) {}
	func dataProvider(dataProvider: DataProvider, gotUserData succeed: Bool) {}
	
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
		self.navigationItem.leftBarButtonItem = logoutButton
		self.navigationItem.rightBarButtonItems = [refreshBarButton, pinBarButton]
		automaticallyAdjustsScrollViewInsets = false
	}
	
	func showPostViewController() {
		let controller = storyboard!.instantiateViewControllerWithIdentifier(String(PostViewController)) as! PostViewController
		let navController = UINavigationController(rootViewController: controller)
		navController.navigationBarHidden = true
		showViewController(navController, sender: self)
	}
}