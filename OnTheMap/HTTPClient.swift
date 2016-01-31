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
		completionHandler: (NSData?, NSURLResponse?, NSError?) -> ()
		) -> NSURLSessionDataTask
}

extension NSURLSession: URLSession {}

class HTTPClient {
	typealias CompletionHandler = (AnyObject?, String?) -> ()
	var session: URLSession = NSURLSession.sharedSession()
}


// MARK: - Extension
// MARK: Send Request
extension HTTPClient {
	func sendRequest(request: (data: NSURLRequest, api: String), handler: CompletionHandler) {
		let task = session.dataTaskWithRequest(request.data) { data, response, error in
			guard let data = data else {
				handler(nil, error?.localizedDescription); return
			}
			// print(NSString(data: data, encoding: NSUTF8StringEncoding))
			switch request.api {
			case String(UdacityHTTP):
				let subData = data.subdataWithRange(NSMakeRange(5, data.length - 5)) /* subset response data! */
				// print(NSString(data: newData, encoding: NSUTF8StringEncoding))
				guard let parsedData = try? NSJSONSerialization.JSONObjectWithData(subData, options: .AllowFragments) else {
					handler(nil, "Error serializing data"); return
				}
				handler(parsedData, nil)
			default:
				guard let parsedData = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) else {
					handler(nil, "Error serializing data"); return
				}
				handler(parsedData, nil)
			}
		}
		task.resume()
	}
}

// MARK: - Extension
// MARK: Network Connection Check
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




