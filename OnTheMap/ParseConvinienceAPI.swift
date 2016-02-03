//
//  ParseConvinience.swift
//  OnTheMap
//
//  Created by Sergei on 29/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation

extension HTTPClient {
	func getStudentLocations(parameters: [String : String], handler: (() throws -> [StudentInformation]) -> Void) {
		sendRequest(ParseHTTP.GET(parameters).request) { response in
			do {
				let result = try response()
				guard let locationsData = result.valueForKey("results") as? [[String : AnyObject]]
					else {
						let description = "Student Location information not found."
						let failureReason = "Error parsing data."
						let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 202).wrappedNSError
						handler { throw error }; return
				}
				let studentInformation = StudentInformation.parseLocationsData(locationsData)
				handler { return studentInformation }
			} catch let error as NSError {
				handler { throw error }
			}
		}
	}
	
	func postStudentInformation(httpBody: [String : AnyObject], handler: (() throws -> String) -> Void) {
		sendRequest(ParseHTTP.POST(httpBody).request) { response in
			do {
				let result = try response()
				guard let objectId = result.valueForKey("objectId") as? String
					else {
						let description = "Post failed."
						let failureReason = "Error parsing data."
						let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 202).wrappedNSError
						handler { throw error }; return
				}
				handler { return objectId }
			} catch let error as NSError {
				handler { throw error }
			}
		}
	}
	
	func updateStudentLocation(objectId: String, httpBody: [String : String], handler: CompletionHandler) {
		sendRequest(ParseHTTP.PUT(objectId, httpBody).request) { response in
			do {
				let result = try response()
				guard let updated = result.valueForKey("updatedAt")
					else {
						let description = "Update failed."
						let failureReason = "Error parsing data."
						let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 202).wrappedNSError
						handler { throw error }; return
				}
				handler { return updated }
			} catch let error as NSError {
				handler { throw error }
			}
		}
	}

	private enum ParseHTTP {
		case GET([String : String])
		case POST([String : AnyObject])
		case PUT(String, [String : String])
		
		var request: (data: NSURLRequest, api: String) {
			switch self {
			case .GET(let parameters):
				// Optional Parameters:
				// limit - (Number) specifies the maximum number of StudentLocation objects to return in the JSON response
				// ex: https://api.parse.com/1/classes/StudentLocation?limit=100
				// skip - (Number) use this parameter with limit to paginate through results
				// ex: https://api.parse.com/1/classes/StudentLocation?limit=200&skip=400
				// order - (String) a comma-separate list of key names that specify the sorted order of the results
				// Prefixing a key name with a negative sign reverses the order (default order is descending)
				// ex: https://api.parse.com/1/classes/StudentLocation?order=-updatedAt
				// Querying for a StudentLocation
				// Required Parameters:
				// where - (Parse Query) a SQL-like query allowing you to check if an object value matches some target value
				// ex: https://api.parse.com/1/classes/StudentLocation?where=%7B%22uniqueKey%22%3A%221234%22%7D
				// the above URL is the escaped form of… https://api.parse.com/1/classes/StudentLocation?where={"uniqueKey":"1234"}
				let urlString = Constants.URL.ParseBaseSecure + "?" + dictionaryToQueryString(parameters)
				let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
				request.addValue(Constants.APIKey.ParseAppId, forHTTPHeaderField: Constants.HTTPHeader.ParseAppId)
				request.addValue(Constants.APIKey.Parse, forHTTPHeaderField: Constants.HTTPHeader.ParseApiKey)
				return (request, Constants.API.Parse)
				
			case .POST(let httpBody):
				let urlString = Constants.URL.ParseBaseSecure
				let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
				request.HTTPMethod = Constants.HTTPMethod.Post
				request.addValue(Constants.APIKey.ParseAppId, forHTTPHeaderField: Constants.HTTPHeader.ParseAppId)
				request.addValue(Constants.APIKey.Parse, forHTTPHeaderField: Constants.HTTPHeader.ParseApiKey)
				request.addValue(Constants.HeaderValue.ApplicationJSON, forHTTPHeaderField: Constants.HTTPHeader.ContentType)
				request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(httpBody, options: .PrettyPrinted)
				return (request, Constants.API.Parse)
				
			case let .PUT(objectId, httpBody):
				// Required Parameters:
				// objectId - (String) the object ID of the StudentLocation to update;
				// specify the object ID right after StudentLocation in URL as seen below
				// ex: https://api.parse.com/1/classes/StudentLocation/8ZExGR5uX8
				let urlString = Constants.URL.ParseBaseSecure + "/" + objectId
				let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
				request.HTTPMethod = Constants.HTTPMethod.Put
				request.addValue(Constants.APIKey.ParseAppId, forHTTPHeaderField: Constants.HTTPHeader.ParseAppId)
				request.addValue(Constants.APIKey.Parse, forHTTPHeaderField: Constants.HTTPHeader.ParseApiKey)
				request.addValue(Constants.HeaderValue.ApplicationJSON, forHTTPHeaderField: Constants.HTTPHeader.ContentType)
				request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(httpBody, options: .PrettyPrinted)
				return (request, Constants.API.Parse)
			}
		}
		
		func dictionaryToQueryString(dictionary: [String : AnyObject]) -> String {
			let queryItems = dictionary.map { NSURLQueryItem(name: $0, value: $1 as? String) }
			let components = NSURLComponents()
			components.queryItems = queryItems
			return components.percentEncodedQuery ?? ""
		}
	}
}