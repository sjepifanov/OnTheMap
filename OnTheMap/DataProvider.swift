//
//  DataProvider.swift
//  OnTheMap
//
//  Created by Sergei on 03/02/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation
import MapKit

enum DataProvider {
	case Locations
	case Annotations
	case AnnotationFromAddress(String)
	
	struct Data {
		static var currentUser: UserInformation?
		static var studentInformation: [StudentInformation]?
		static var annotations: [MKPointAnnotation]?
		static var annotationFromAddress: MKPointAnnotation?
	}
	
	struct Connect {
		static var client: HTTPClient?
	}
	
	func getData() {
		switch self {
		case .Locations:
			// TODO: Implement
			// getLocationInformation
			// save to Data Locations
			break
		case .Annotations:
			// TODO: Implement
			// getAnnotations from Locations
			// save to Data Annotations
			break
		case .AnnotationFromAddress(let address):
			print(address)
			// TODO: Implement
			// reverseGeocodeAddress
			// getAnnotation
			// get Annotation title and subtitle from Data User Data
			// save annotation to Data
			break
		}
	}
}
