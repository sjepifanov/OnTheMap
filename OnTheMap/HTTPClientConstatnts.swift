//
//  HTTPClientConstatnts.swift
//  OnTheMap
//
//  Created by Sergei on 29/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation

struct Constants {
	struct URL {
		static let ParseBaseSecure = "https://api.parse.com/1/classes/StudentLocation"
		static let UdacityBaseSecure = "https://www.udacity.com/api"
		static let UdacitySignUpURL = "https://www.udacity.com/account/auth#!/signup"
	}
	struct APIKey {
		static let Parse = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
		static let ParseAppId = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
	}
	struct Method {
		static let Session = "session"
		static let Users = "users"
	}
	struct HTTPHeader {
		static let Accept = "Accept"
		static let ContentType = "Content-Type"
		static let XSRFToken = "X-XSRF-TOKEN"
		static let ParseAppId = "X-Parse-Application-Id"
		static let ParseApiKey = "X-Parse-REST-API-Key"
	}
	struct HeaderValue {
		static let ApplicationJSON = "application/json"
	}
	struct HTTPMethod {
		static let Post = "POST"
		static let Get = "GET"
		static let Delete = "DELETE"
		static let Put = "PUT"
	}
	struct Cookie {
		static let XSRFToken = "XSRF-TOKEN"
	}
	struct JSON {
		static let Udacity = "udacity"
		static let Email = "username"
		static let Password = "password"
		static let StatusMessage = "status_message"
		static let Error = "error"
		static let ObjectID = "objectId"
		static let UniqueKey = "uniqueKey"
		static let FirstName = "firstName"
		static let LastName = "lastName"
		static let MapString = "mapString"
		static let MediaURL = "mediaURL"
		static let Latitude = "latitude"
		static let Longitude = "longitude"
		static let CreatedAt = "createdAt"
		static let UpdatedAt = "updatedAt"
		static let Results = "results"
		static let UserLastName = "last_name"
		static let UserFirstName = "first_name"
	}
	struct Parameters {
		static let Limit = "limit"
		static let Skip = "skip"
		static let Order = "order"
	}
	struct ErrorDomain {
		static let VirtualTourist = "VirtualTouristErrorDomain"
	}
}