//
//  StudentInformation.swift
//  OnTheMap
//
//  Created by Sergei on 29/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation

struct StudentInformation {
	
	var firstName = ""
	var lastName = ""
	var mediaURL = ""
	let objectId: String
	let uniqueKey: String
	let mapString: String
	let latitude: Double
	let longitude: Double
	let createdAt: String
	let updatedAt: String
	
	
	init (dictionary: [String : AnyObject]) {
		
		if let firstName = dictionary[Constants.JSON.FirstName] as? String { self.firstName = firstName }
		if let lastName = dictionary[Constants.JSON.LastName] as? String { self.lastName = lastName }
		if let mediaURL = dictionary[Constants.JSON.MediaURL] as? String { self.mediaURL = mediaURL }
		objectId = dictionary[Constants.JSON.ObjectID] as! String
		uniqueKey = dictionary[Constants.JSON.UniqueKey] as! String
		mapString = dictionary[Constants.JSON.MapString] as! String
		latitude = dictionary[Constants.JSON.Latitude] as! Double
		longitude = dictionary[Constants.JSON.Longitude] as! Double
		createdAt = dictionary[Constants.JSON.CreatedAt] as! String
		updatedAt = dictionary[Constants.JSON.UpdatedAt] as! String
  
	}
	
	static func studentsLocationsFromResults(results: [[String : AnyObject]]) -> [StudentInformation] {
		return results.map { StudentInformation(dictionary: $0) }
	}
}