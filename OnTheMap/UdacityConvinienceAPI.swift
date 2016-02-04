//
//  UdacityConvinience.swift
//  OnTheMap
//
//  Created by Sergei on 29/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation

extension HTTPClient {
	// Here we return userId or throw error. Handler set to provide correct response Type to responder
	func sendAuthentictionRequest(user: LoginUser, handler: (() throws -> String) -> Void) {
		guard let email = user.email, password = user.password else { return }
		let httpBody = ["udacity":["username" : email, "password" : password]]
		
		sendRequest(UdacityHTTP.POST(httpBody).request) { response in
			do {
				let result = try response()
				if let
					code = result.valueForKey("status") as? Int,
					description = result.valueForKey("error") as? String
				{
					let failureReason = "There was an error authenticating user."
					let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: code).wrappedNSError
					handler { throw error }; return
				}
				guard let userId = result.valueForKeyPath("account.key") as? String
					else {
						let description = "User Account data not found."
						let failureReason = "Error parsing data."
						let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 202).wrappedNSError
						handler { throw error }; return
				}
				handler { return userId }
			} catch let error as NSError {
				handler { throw error}
			}
		}
	}
	// Here we return userInformation or throw error. Handler set to provide correct response Type to responder
	func getPublicUserData(userId: String, handler: (() throws -> UserInformation) -> Void) {
		sendRequest(UdacityHTTP.GET(userId).request) { response in
			do {
				let result = try response()
				guard let
					userData = result.valueForKey("user") as? [String : AnyObject],
					firstName = userData["first_name"] as? String,
					lastName = userData["last_name"] as? String
				else {
					let description = "User data not found."
					let failureReason = "Error parsing data."
					let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 202).wrappedNSError
					handler { throw error }; return
				}
				let currentUser = UserInformation(userId: userId,
					firstName: firstName,
					lastName: lastName,
					mapString: "",
					mediaURL: "")
				handler { return currentUser }
			} catch let error as NSError {
				handler { throw error }
			}
		}
	}
	
	func endCurrentSession(handler: CompletionHandler) {
		sendRequest(UdacityHTTP.DELETE.request) { response in
			do {
				let result = try response()
				guard let session = result.valueForKey("session") as? [String: AnyObject]
					else {
						let description = "No session information found."
						let failureReason = "Error parsing data."
						let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 202).wrappedNSError
						handler { throw error }; return
				}
				handler { return session }
			} catch let error as NSError {
				handler { throw error }
			}
		}
	}
	
	// Keep all request templates in enum. Provide with necessary data upon request.
	private enum UdacityHTTP {
		case GET(String)
		case POST([String : [String : String]])
		case DELETE
		
		var request: (data: NSURLRequest, api: String) {
			switch self {
			case .GET(let userId):
				let urlString = Constants.URL.UdacityBaseSecure + "/" + Constants.Method.Users + "/" + userId
				let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
				return (request, Constants.API.Udacity)
				
			case .POST(let httpBody):
				let urlString = Constants.URL.UdacityBaseSecure + "/" + Constants.Method.Session
				let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
				request.HTTPMethod = Constants.HTTPMethod.Post
				request.addValue(Constants.HeaderValue.ApplicationJSON, forHTTPHeaderField: Constants.HTTPHeader.Accept)
				request.addValue(Constants.HeaderValue.ApplicationJSON, forHTTPHeaderField: Constants.HTTPHeader.ContentType)
				request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(httpBody, options: .PrettyPrinted)
				return (request, Constants.API.Udacity)
				
			case .DELETE:
				let urlString = Constants.URL.UdacityBaseSecure + "/" + Constants.Method.Session
				let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
				request.HTTPMethod = Constants.HTTPMethod.Delete
				let xsrfCookie = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies?.filter { $0.name == Constants.Cookie.XSRFToken}.first
				if let xsrfCookie = xsrfCookie { request.setValue(xsrfCookie.value, forHTTPHeaderField: Constants.HTTPHeader.XSRFToken) }
				return (request, Constants.API.Udacity)
			}
		}
	}
}