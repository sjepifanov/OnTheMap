//
//  StudentInformation.swift
//  OnTheMap
//
//  Created by Sergei on 29/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation

struct StudentInformation {
	let firstName: String
	let lastName: String
	let mediaURL: String
	let objectId: String
	let uniqueKey: String
	let mapString: String
	let latitude: Double
	let longitude: Double
	
	private init (dictionary: [String : String]) {
			firstName = dictionary[Constants.JSON.FirstName]!
			lastName = dictionary[Constants.JSON.LastName]!
			mediaURL = dictionary[Constants.JSON.MediaURL]!
			objectId = dictionary[Constants.JSON.ObjectID]!
			uniqueKey = dictionary[Constants.JSON.UniqueKey]!
			mapString = dictionary[Constants.JSON.MapString]!
			latitude = Double(dictionary[Constants.JSON.Latitude]!)!
			longitude = Double(dictionary[Constants.JSON.Longitude]!)!
	}
	
	static func parseLocationsData(data: [[String : AnyObject]]) -> [StudentInformation] {
		let parsedResult = data.map { (studentInformation: [String: AnyObject]) -> [String : String] in
			guard let
				firstName = studentInformation[Constants.JSON.FirstName] as? String,
				lastName = studentInformation[Constants.JSON.LastName] as? String,
				mediaURL = studentInformation[Constants.JSON.MediaURL] as? String,
				objectId = studentInformation[Constants.JSON.ObjectID] as? String,
				uniqueKey = studentInformation[Constants.JSON.UniqueKey] as? String,
				mapString = studentInformation[Constants.JSON.MapString] as? String,
				latitude = studentInformation[Constants.JSON.Latitude] as? Double,
				longitude = studentInformation[Constants.JSON.Longitude] as? Double
				else { return [:] }
			let parsedResult: [String : String] = [
				Constants.JSON.FirstName : firstName,
				Constants.JSON.LastName : lastName,
				Constants.JSON.MediaURL : mediaURL,
				Constants.JSON.ObjectID : objectId,
				Constants.JSON.UniqueKey : uniqueKey,
				Constants.JSON.MapString : mapString,
				Constants.JSON.Latitude : String(latitude),
				Constants.JSON.Longitude : String(longitude)
			]
			return parsedResult
			}.filter { $0 != [:] }
		
		return parsedResult.map { StudentInformation(dictionary: $0) }
	}
}