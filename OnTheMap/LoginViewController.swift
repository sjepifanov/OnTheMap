//
//  LoginViewController.swift
//  OnTheMap
//
//  Created by Sergei on 29/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import UIKit

extension UIViewController {
	func showAlert(message: String, title: String = "") {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
		alertController.addAction(OKAction)
		Queue.Main.execute { self.presentViewController(alertController, animated: true, completion: nil) }
	}
}

class LoginViewController: UIViewController, UITextFieldDelegate {
	
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var contentView: UIView!
	@IBOutlet weak var emailTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var loginButton: UIButton!
	@IBOutlet weak var signUpButton: UIButton!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	// variable to keep track of active text fields
	weak var activeField = UITextField()
	
	var client = HTTPClient()
	var currentUser = UserInformation()

	override func viewDidLoad() {
		super.viewDidLoad()
		loginButton.layer.cornerRadius = 5
		emailTextField.text = "sjepifanov@hotmail.com"
		passwordTextField.text = "Mong2005!"
	}
	
	override func viewDidLayoutSubviews() {
		// If any of text fields is active do not center scroll view
		if let _ = activeField { return }
		centerContentView()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		subscribeToKeyboardNotifications()
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		unsubscribeFromKeyboardNotifications()
	}

	// MARK: - Actions
	@IBAction func loginButtonAction(sender: AnyObject) {
		attemptLogin()
	}

	@IBAction func signUpButtonAction(sender: AnyObject) {
		openUdacitySignUpPage()
	}

	// MARK: - Methods
	
	func attemptLogin() {
		guard
			let email = emailTextField.text where email != "",
			let password = passwordTextField.text where password != "" else {
				showAlert("Please provide User credentials"); return
		}
		activityIndicator.startAnimating()
		client.sendAuthentictionRequest(email, password: password) { data, error in
			guard let userId = data else {
				Queue.Main.execute { self.activityIndicator.stopAnimating() }
				self.showAlert(error!); return
			}
			defer {
				Queue.Main.execute {
					self.activityIndicator.stopAnimating()
					self.currentUser.userId = userId as! String
					self.completeLogin()
				}
			}
		}
	}
	
	func completeLogin() {
		activityIndicator.startAnimating()
		client.getPublicUserData(currentUser.userId) {data, error in
			guard let user = data else {
				Queue.Main.execute { self.activityIndicator.stopAnimating() }
				self.showAlert(error!); return
			}
			defer {
				Queue.Main.execute {
					self.activityIndicator.stopAnimating()
					self.currentUser.firstName = user["first_name"] as! String
					self.currentUser.lastName = user["last_name"] as! String
					self.showMapViewController()
				}
			}
		}
	}
	
	func showMapViewController() {
		let controller = storyboard!.instantiateViewControllerWithIdentifier(String(MapViewController)) as! MapViewController
		controller.currentUser = currentUser
		presentViewController(controller, animated: true, completion: nil)
	}
	
	func openUdacitySignUpPage() {
		UIApplication.sharedApplication().openURL(NSURL(string: Constants.URL.UdacitySignUpURL)!)
	}
	
	func subscribeToKeyboardNotifications() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
	}
	
	func unsubscribeFromKeyboardNotifications() {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
	}
	
	func keyboardWillShow(notification: NSNotification) {
		let kbHeight = getKeyboardHeight(notification)
		let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, kbHeight, 0.0)
		scrollView.contentInset = contentInsets
		
		var aRect: CGRect = contentView.frame
		aRect.size.height -= kbHeight
		if let activeField = activeField {
			if CGRectContainsPoint(aRect, activeField.frame.origin) {
				scrollView.scrollRectToVisible(activeField.frame, animated: true)
			}
		}
	}
	
	func keyboardWillHide(notification: NSNotification) {
		centerContentView()
	}
	
	func getKeyboardHeight(notification: NSNotification) -> CGFloat {
		let userInfo = notification.userInfo
		let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
		return keyboardSize.CGRectValue().height
	}

	func centerContentView() {
		let scrollViewBounds = scrollView.bounds
		let contentViewBounds = contentView.bounds
		
		var scrollViewInsets = UIEdgeInsetsZero
		scrollViewInsets.top = scrollViewBounds.size.height/2.0;
		scrollViewInsets.top -= contentViewBounds.size.height/2.0;
		
		scrollViewInsets.bottom = scrollViewBounds.size.height/2.0
		scrollViewInsets.bottom -= contentViewBounds.size.height/2.0;
		scrollViewInsets.bottom += 1
		
		scrollView.contentInset = scrollViewInsets
	}
	
	//MARK: - Text Field Delegate
	func textFieldDidBeginEditing(textField: UITextField) {
		activeField = textField
	}
	
	func textFieldDidEndEditing(textField: UITextField) {
		activeField = nil
	}
	
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}
