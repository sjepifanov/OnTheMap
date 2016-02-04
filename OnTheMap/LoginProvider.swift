//
//  LoginProvider.swift
//  OnTheMap
//
//  Created by Sergei on 04/02/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation

// Idea taken from https://realm.io/news/david-east-simplifying-login-swift-enums/
// LoginProvider delegate protocol
protocol LoginProviderDelegate {
	func loginProvider(loginProvider: LoginProvider, didSucceed succeed: Bool)
	func loginProvider(loginProvider: LoginProvider, didError error: NSError)
}
// Login User Struct to hold the initial user for authentication
struct LoginUser {
	let email: String?
	let password: String?
	
	func isValid() -> Bool {
		guard let email = email where email != "",
			let password = password where password != ""
			else {
				return false
		}
		return true
	}
}

// Login provider with main login function will excute login path depending on chosen case
enum LoginProvider {
	case Email(LoginUser)
	// Facebook left as a placeholder. Due to time constraits the functionality is nit emlemented
	// though current patter will allows to infinite number of possible providers.
	case Facebook
	
	struct Connect {
		static var delegate: LoginProviderDelegate?
		static var client: HTTPClient?
	}
	
	func login() {
		guard let
			delegate = Connect.delegate,
			client = Connect.client
			else { return }
		
		switch self {
		case let .Email(user) where user.isValid():
			Queue.UserInitiated.execute {
				client.sendAuthentictionRequest(user) { response in
					do {
						let userId = try response() as String
						DataProvider.Data.currentUser = UserInformation(userId: userId,
							firstName: "",
							lastName: "",
							mapString: "",
							mediaURL: "")
						Queue.Main.execute { delegate.loginProvider(self, didSucceed: true) }
					} catch let error as NSError {
						Queue.Main.execute { delegate.loginProvider(self, didError: error) }
					}
				}
			}
			
		case let .Email(user) where !user.isValid():
			let description = "Please provide Email and Password."
			let failureReason = "Credentials not set."
			let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 100).wrappedNSError
			delegate.loginProvider(self, didError: error)
			
		case .Facebook:
			break
			
		default:
			break
		}
	}
}