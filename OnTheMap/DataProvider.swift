//
//  DataProvider.swift
//  OnTheMap
//
//  Created by Sergei on 03/02/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation
import MapKit

// MARK: - DataProviderDelegate protocol
protocol DataProviderDelegate {
	func dataProvider(dataProvider: DataProvider, gotLocationFromAddress succeed: Bool)
	func dataProvider(dataProvider: DataProvider, gotAnnotations succeed: Bool)
	func dataProvider(dataProvider: DataProvider, gotUserData succeed: Bool)
	func dataProvider(dataProvider: DataProvider, gotLocations succeed: Bool)
	func dataProvider(dataProvider: DataProvider, endSession succeed: Bool)
	func dataProvider(dataProvider: DataProvider, didSucceed succeed: Bool)
	func dataProvider(dataProvider: DataProvider, didError error: NSError)
}
// Tried with default implentattion.
extension DataProviderDelegate {
	func dataProvider(dataProvider: DataProvider, gotLocationFromAddress succeed: Bool = true) { }
	func dataProvider(dataProvider: DataProvider, gotAnnotations succeed: Bool = true) { }
	func dataProvider(dataProvider: DataProvider, gotUserData succeed: Bool = true) { }
	func dataProvider(dataProvider: DataProvider, gotLocations succeed: Bool = true) { }
	func dataProvider(dataProvider: DataProvider, didSucceed succeed: Bool = true) { }
}

// MARK: - DataProvider enum with Data and Connect structs
// Tried to stay away from Singleton pattern, and be as close as posble to allow Mockup tests
// though that brings other problesm, as in tabBarController views are losing connection with delegate
// when switching connections back and forth. Probably class would play better than struct in such scenario.
enum DataProvider {
	case UserData
	case Locations
	case Annotations
	case AnnotationFromAddress(String)
	case EndSession
	
	struct Data {
		static var currentUser: UserInformation?
		static var studentInformation: [StudentInformation]?
		static var annotations: [MKPointAnnotation]?
		static var annotationFromAddress: MKPointAnnotation?
	}
	
	struct Connect {
		static var delegate: DataProviderDelegate?
		static var client: HTTPClient?
	}
}

// MARK: - Data Provider Extension. getData() method
extension DataProvider {
	// Provide requested data according to enum cases. The body of function grows
	// with cases introduced to enum. While each case is small, the otheral structure
	// feels prety heavy. Probably separate classes would play better for readability.
	func getData() {
		
		guard let client = Connect.client, delegate = Connect.delegate else { return }
		
		switch self {
			
			// Get Public User Data
		case .UserData:
			guard let currentUser = DataProvider.Data.currentUser else { break }
			Queue.UserInitiated.execute {
				client.getPublicUserData(currentUser.userId) { response in
					do {
						let currentUser = try response() as UserInformation
						Queue.Main.execute {
							DataProvider.Data.currentUser = currentUser
							delegate.dataProvider(self, gotUserData: true)
						}
					} catch let error as NSError {
						Queue.Main.execute { delegate.dataProvider(self, didError: error) }
					}
				}
			}
			
			// Get Student Locations
		case .Locations:
			let parameters = ["limit" : "100", "order" : "-updatedAt"]
			Queue.UserInitiated.execute {
				client.getStudentLocations(parameters) { response in
					do {
						let locations = try response() as [StudentInformation]
						DataProvider.Data.studentInformation = locations
						Queue.Main.execute { delegate.dataProvider(self, gotLocations: true) }
					} catch let error as NSError {
						Queue.Main.execute { delegate.dataProvider(self, didError: error) }
					}
				}
			}
			
			// Prepare Annotations data from StudentInformation data
		case .Annotations:
			guard let locations = DataProvider.Data.studentInformation
				else {
					let description = "There is no Annoatations data. Please tap Refresh button."
					let failureReason = "No data to proceed."
					let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 205).wrappedNSError
					delegate.dataProvider(self, didError: error); break
			}
			let annotations = createAnnotationsArray(locations)
			DataProvider.Data.annotations = annotations
			delegate.dataProvider(self, gotAnnotations: true)
			
			// Create Annotation point from geocoded Data
		case .AnnotationFromAddress(let address):
			Queue.UserInitiated.execute {
				self.geocodeAddress(address) { response in
					do {
						let annotation = try response() as MKPointAnnotation
						DataProvider.Data.annotationFromAddress = annotation
						Queue.Main.execute { delegate.dataProvider(self, gotLocationFromAddress: true) }
					} catch let error as NSError {
						Queue.Main.execute { delegate.dataProvider(self, didError: error) }
					}
				}
			}
			
		default:
			let description = "Unknown request type."
			let failureReason = "Unknown request type."
			let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 299).wrappedNSError
			delegate.dataProvider(self, didError: error)
		}
	}
}

// MARK: - Data Provider Extension. postData() method
extension DataProvider {
	// Prepare current User data with location and mediaURL provided and send the post request
	func postData() {
		guard let client = Connect.client, delegate = Connect.delegate else { return }
		switch self {
		case .UserData:
			guard let
				currentUser = DataProvider.Data.currentUser,
				annotation = DataProvider.Data.annotationFromAddress
				else {
					let description = "Failed to retreve User Data."
					let failureReason = "No user data found."
					let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 290).wrappedNSError
					delegate.dataProvider(self, didError: error); return
			}
			let httpBody: [String : AnyObject] = [
				Constants.JSON.UniqueKey : currentUser.userId,
				Constants.JSON.FirstName : currentUser.firstName,
				Constants.JSON.LastName : currentUser.lastName,
				Constants.JSON.MapString : currentUser.mapString,
				Constants.JSON.Longitude : annotation.coordinate.longitude,
				Constants.JSON.Latitude : annotation.coordinate.latitude,
				Constants.JSON.MediaURL : currentUser.mediaURL
			]
			Queue.UserInitiated.execute {
				client.postStudentInformation(httpBody) { response in
					do {
						let objectId = try response() as String
						// TODO: Remove print
						print(objectId)
						Queue.Main.execute { delegate.dataProvider(self, didSucceed: true) }
					} catch let error as NSError {
						Queue.Main.execute { delegate.dataProvider(self, didError: error) }
					}
				}
			}
		default:
			let description = "There is nothing to post."
			let failureReason = "Wrong request type."
			let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 299).wrappedNSError
			delegate.dataProvider(self, didError: error)
		}
	}
}

// MARK: - Data Provider Extension. endSession() method
extension DataProvider {
	func endSession() {
		guard let client = Connect.client, delegate = Connect.delegate else { return }
		
		switch self {
		case .EndSession:
			Queue.UserInitiated.execute {
				client.endCurrentSession { response in
					do {
						let _ = try response()
						Queue.Main.execute { delegate.dataProvider(self, endSession: true) }
					} catch _ {
						Queue.Main.execute { delegate.dataProvider(self, endSession: false) }
					}
				}
			}
			
		default:
			let description = "Unknown request type."
			let failureReason = "Unknown request type."
			let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 299).wrappedNSError
			delegate.dataProvider(self, didError: error)
		}
	}
}

// MARK: - Data Provider Extension. Private Helpers
extension DataProvider {
	// Create Annotations Array from User Locations
	private func createAnnotationsArray(studentsLocations: [StudentInformation]) -> [MKPointAnnotation] {
		let annotations = studentsLocations.map { (location: StudentInformation) -> MKPointAnnotation in
			let lat = CLLocationDegrees(location.latitude)
			let long = CLLocationDegrees(location.longitude)
			let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
			let first = location.firstName
			let last = location.lastName
			let mediaURL = location.mediaURL
			let annotation = MKPointAnnotation()
			annotation.coordinate = coordinate
			annotation.title = "\(first) \(last)"
			annotation.subtitle = mediaURL
			return annotation
		}
		return annotations
	}
	
	// Translate Address to GeoCode and return Annotation
	private func geocodeAddress(address: String, handler:(() throws -> MKPointAnnotation) -> Void) {
		guard let currentUser = DataProvider.Data.currentUser
			else {
				let description = "Current User information not present. Try to logout and login again."
				let failureReason = "No data present."
				let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 208).wrappedNSError
				handler { throw error }; return
		}
		let geocoder = CLGeocoder()
		geocoder.geocodeAddressString(address) { data, error in
			guard let placeMarks = data
				else {
					// The default error is non informative. Replacing with human readable error.
					let description = "There is no known location by address provided."
					let failureReason = "No location information for address provided"
					let error = WrapError.UserInfo(description: description, failureReason: failureReason, code: 209).wrappedNSError
					handler { throw error }; return
			}
			if placeMarks.count > 0 {
				let placeMark = placeMarks[0]
				guard let location = placeMark.location else { return }
				let annotation = MKPointAnnotation()
				annotation.coordinate = location.coordinate
				annotation.title = "\(currentUser.firstName) \(currentUser.lastName)"
				handler { return annotation }
			}
		}
	}
}