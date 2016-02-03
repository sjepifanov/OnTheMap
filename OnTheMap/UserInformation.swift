//
//  UserInformation.swift
//  OnTheMap
//
//  Created by Sergei on 29/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation

// Idea taken from https://realm.io/news/david-east-simplifying-login-swift-enums/

protocol LoginProviderDelegate {
	func loginProvider(loginProvider: LoginProvider, didSucceed user: UserInformation)
	func loginProvider(loginProvider: LoginProvider, didError error: NSError)
}

struct UserInformation {
	var userId = ""
	var firstName = ""
	var lastName = ""
}

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

enum LoginProvider {
	case Email(LoginUser)
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
						client.getPublicUserData(userId) { response in
							do {
								let currentUser = try response() as UserInformation
								Queue.Main.execute {
									DataProvider.Data.currentUser = currentUser
									delegate.loginProvider(self, didSucceed: currentUser)
								}
							} catch let error as NSError {
								Queue.Main.execute { delegate.loginProvider(self, didError: error) }
							}
						}
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