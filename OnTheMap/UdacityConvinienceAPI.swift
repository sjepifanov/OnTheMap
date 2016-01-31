//
//  UdacityConvinience.swift
//  OnTheMap
//
//  Created by Sergei on 29/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation

extension HTTPClient {
	func sendAuthentictionRequest(email: String, password: String, handler: CompletionHandler) {
		
		let httpBody = ["udacity":["username" : email, "password" : password]]
		
		sendRequest(UdacityHTTP.POST(httpBody).request) { data, error in
			guard let data = data else {
				handler(nil, error); return
			}
			if let _ = data.valueForKey("status") as? Int {
				let newError = data.valueForKey("error") as? String
				handler(nil, newError); return
			}
			guard let account = data.valueForKey("account") as? [String: AnyObject] else {
				handler(nil, "Account information not found"); return
			}
			let userId = account["key"] as? String
			handler(userId, nil)
		}
	}
	
	func getPublicUserData(userId: String, handler: CompletionHandler) {
		sendRequest(UdacityHTTP.GET(userId).request) { data, error in
			guard let data = data else {
				handler(nil, error); return
			}
			guard let user = data.valueForKey("user") as? [String : AnyObject] else {
				return handler(nil, "User data not found")
			}
			handler(user, nil)
		}
	}
	
	func endCurrentSession(handler: CompletionHandler) {
		sendRequest(UdacityHTTP.DELETE.request) { data, error in
			guard let data = data else {
				handler(nil, error); return
			}
			guard let session = data.valueForKey("session") as? [String: AnyObject] else {
				handler(nil, "Session is not responding"); return
			}
			handler(session, nil)
		}
	}
}

enum UdacityHTTP {
	case GET(String)
	case POST([String : [String : String]])
	case DELETE
	
	var request: (data: NSURLRequest, api: String) {
		switch self {
		case .GET(let userId):
			let urlString = Constants.URL.UdacityBaseSecure + "/" + Constants.Method.Users + "/" + userId
			let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
			return (request, String(UdacityHTTP))
			
		case .POST(let httpBody):
			let urlString = Constants.URL.UdacityBaseSecure + "/" + Constants.Method.Session
			let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
			request.HTTPMethod = Constants.HTTPMethod.Post
			request.addValue(Constants.HeaderValue.ApplicationJSON, forHTTPHeaderField: Constants.HTTPHeader.Accept)
			request.addValue(Constants.HeaderValue.ApplicationJSON, forHTTPHeaderField: Constants.HTTPHeader.ContentType)
			request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(httpBody, options: .PrettyPrinted)
			return (request, String(UdacityHTTP))
			
		case .DELETE:
			let urlString = Constants.URL.UdacityBaseSecure + "/" + Constants.Method.Session
			let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
			request.HTTPMethod = Constants.HTTPMethod.Delete
			let xsrfCookie = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies?.filter { $0.name == Constants.Cookie.XSRFToken}.first
			if let xsrfCookie = xsrfCookie { request.setValue(xsrfCookie.value, forHTTPHeaderField: Constants.HTTPHeader.XSRFToken) }
			return (request, String(UdacityHTTP))
		}
	}
}
