//
//  SecondViewController.swift
//  OnTheMap
//
//  Created by Sergei on 29/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import UIKit

class InformationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	@IBOutlet weak var tableView: UITableView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let logoutButton = UIBarButtonItem(title: "Logout", style: .Plain, target: self, action: "logoutBarButtonItemClicked")
		let pinBarButton = UIBarButtonItem(image: UIImage(named: "pin"), style: .Plain, target: self, action: "pinBarButtonItemClicked")
		let refreshBarButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refreshBarButtonItemClicked")
		self.navigationItem.leftBarButtonItem = logoutButton
		self.navigationItem.rightBarButtonItems = [refreshBarButton, pinBarButton]
		
		tableView.delegate = self
		tableView.dataSource = self
		tableView.reloadData()
		
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		tableView.reloadData()
	}
	
	//lazy var studentLocations = [StudentInformation]()
	lazy var client = HTTPClient()
	//lazy var currentUser = UserInformation()
	
	// MARK: - Actions
	// TODO: - Need a constructor for All Map/Table related calls.
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
		showViewController(controller, sender: self)
	}
	
	// Refresh map view data
	func refreshBarButtonItemClicked() {
		//getLocationInformation()
	}
	
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
		let app = UIApplication.sharedApplication()
		// TODO: Verify URL before opening
		// TODO: Verify student info array. Should not contain nil values.
		app.openURL(NSURL(string: (DataProvider.Data.studentInformation?[indexPath.row].mediaURL)!)!)
	}
	
	
}

