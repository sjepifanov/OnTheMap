//
//  HTTPClient.swift
//  OnTheMap
//
//  Created by Sergei on 29/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation
import SystemConfiguration

protocol URLSession {
	func dataTaskWithRequest(
		request: NSURLRequest,
		completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void
		) -> NSURLSessionDataTask
}

extension NSURLSession: URLSession {}

class HTTPClient {
	// Idea taken from http://appventure.me/2015/06/19/swift-try-catch-asynchronous-closures/
	// For asyncronus function be able to throw we encapsulating the error into a throwable closure
	// This closure will either provide the result of the computation, or it will throw.
	// The closure itself is being constructed during the computation by one of two means:
	// In case of an error: { throw error }
	// In case of success: { return result }
	typealias CompletionHandler = (() throws -> AnyObject) -> Void
	
	// Shared URLSession
	var session: URLSession = NSURLSession.sharedSession()
}

/**
Wrap Error Message to NSError

ex: WrapError.UserInfo(description: description, failureReason: failureReason, code: code).wrappedNSError

- parameters:
	- description: String
	- failureReason: String
	- code: int
- returns:
	NSError
*/
enum WrapError {
	case UserInfo(description: String, failureReason: String, code: Int)
	
	var wrappedNSError: (NSError) {
		switch self {
		case .UserInfo(let description, let failureReason, let code):
			var dict = [String: AnyObject]()
			dict[NSLocalizedDescriptionKey] = description
			dict[NSLocalizedFailureReasonErrorKey] = failureReason
			let error = NSError(domain: Constants.ErrorDomain.VirtualTourist, code: code, userInfo: dict)
			return error
		}
	}
}


// MARK: - Extension Send Request

extension HTTPClient {
	
	func sendRequest(request: (data: NSURLRequest, api: String), handler: CompletionHandler) {
		let task = session.dataTaskWithRequest(request.data) { data, response, error in
			guard let data = data else {
				guard let error = error else {
					let description = "There is no data returned by request"
					let failureReason = "No data received."
					let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 100).wrappedNSError
					handler({ throw error }); return
				}
				handler({ throw error }); return
			}
			
			switch request.api {
			case String(UdacityHTTP):
				do {
					let subData = data.subdataWithRange(NSMakeRange(5, data.length - 5)) /* subset response data! */
					let parsedData = try NSJSONSerialization.JSONObjectWithData(subData, options: .AllowFragments)
					handler({ return parsedData } )
				} catch let error as NSError {
					handler({ throw error })
				}
				
			case String(ParseHTTP):
				do {
					let parsedData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
					handler({ return parsedData})
				} catch let error as NSError {
					handler({ throw error})
				}
				
			default:
				let description = "The request type is unknown."
				let failureReason = "Unknown request."
				let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 99).wrappedNSError
				handler({ throw error })
			}
		}
		task.resume()
	}
}

// MARK: - Extension Network Connection Check

// Taken from Mastering Swift 2.0 book - https://www.packtpub.com/application-development/mastering-swift-2
extension HTTPClient {
	// Check Network Connection
	enum ConnectionType {
		case NONETWORK
		case MOBILE3GNETWORK
		case WIFINETWORK
	}
	
	func networkConnectionType(hostname: NSString) -> ConnectionType {
		let reachabilityRef = SCNetworkReachabilityCreateWithName(nil, hostname.UTF8String)
		var flags = SCNetworkReachabilityFlags()
		SCNetworkReachabilityGetFlags(reachabilityRef!, &flags)
		let reachable: Bool = (flags.rawValue & SCNetworkReachabilityFlags.Reachable.rawValue) != 0
		let needsConnection: Bool = (flags.rawValue & SCNetworkReachabilityFlags.ConnectionRequired.rawValue) != 0
		if reachable && !needsConnection {
			//what type of connection is available
			let isCellularConnection = (flags.rawValue & SCNetworkReachabilityFlags.IsWWAN.rawValue) != 0
			if isCellularConnection {
				// cellular conection available
				return ConnectionType.MOBILE3GNETWORK
			} else {
				return ConnectionType.WIFINETWORK
			}
		}
		return ConnectionType.NONETWORK // no connection at all
	}
}