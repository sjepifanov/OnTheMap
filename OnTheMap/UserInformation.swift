//
//  UserInformation.swift
//  OnTheMap
//
//  Created by Sergei on 29/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation

protocol LoginProviderDelegate {
	func loginProvider(loginProvider: LoginProvider, didSucceed user: UserInformation)
	func loginProvider(loginProvider: LoginProvider, didError error: NSError)
}

enum LoginProvider {
	case Facebook
	case Email(LoginUser)
	
	func login(delegate delegate: LoginProviderDelegate) {
		
		let client = HTTPClient()
		
		switch self {
		case .Email(let user) where user.isValid():
			Queue.UserInitiated.execute {
				client.sendAuthentictionRequest(user.email!, password: user.password!) { response in
					do {
						guard let userId = try response() as? String else {
							let description = "UserId not found."
							let failureReason = "Error parsing data."
							let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 202).wrappedNSError
							delegate.loginProvider(self, didError: error); return
						}
						client.getPublicUserData(userId) { response in
							do {
								guard let
									user = try response() as? [String : AnyObject],
									firstName = user["first_name"] as? String,
									lastname = user["last_name"] as? String else {
										let description = "User Data not found."
										let failureReason = "Error parsing data."
										let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 202).wrappedNSError
										delegate.loginProvider(self, didError: error); return
								}
								Queue.Main.execute {
									var currentUser = UserInformation()
									currentUser.userId = userId
									currentUser.firstName = firstName
									currentUser.lastName = lastname
									delegate.loginProvider(self, didSucceed: currentUser)
								}
							} catch let error as NSError {
								delegate.loginProvider(self, didError: error); return
							}
						}
					} catch let error as NSError {
						delegate.loginProvider(self, didError: error); return
					}
				}
			}
			
		case .Email(let user) where !user.isValid():
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

struct LoginUser {
	let email: String?
	let password: String?
	func isValid() -> Bool {
		guard
			let email = email where email != "",
			let password = password where password != "" else {
				return false
		}
		return true
	}
}

struct UserInformation {
	var userId = ""
	var firstName = ""
	var lastName = ""
}

