//
//  RiderViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Rob Percival on 11/07/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    func displayAlert(title: String, message: String) {
        
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertcontroller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertcontroller, animated: true, completion: nil)
        
    }
    
    var driverOnTheWay = false

    var locationManager = CLLocationManager()
    
    var riderRequestActive = true
    
    var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    @IBOutlet var map: MKMapView!
    
    // function to call an UCAB 
    
    @IBAction func callAnUCAB(_ sender: AnyObject) {
        
        if riderRequestActive {
            
            callAnUCABButton.setTitle("Call An UCAB", for: [])
            
            riderRequestActive = false
            
            let query = PFQuery(className: "RiderRequest")
            
            query.whereKey("username", equalTo: (PFUser.current()?.username)!)
            
            query.findObjectsInBackground(block: { (objects, error) in
                
                if let riderRequests = objects {
                    
                    for riderRequest in riderRequests {
                        
                            riderRequest.deleteInBackground()
                        
                    }
                    
                }
                
                
            })
            
        } else {
        
        if userLocation.latitude != 0 && userLocation.longitude != 0 {
            
            riderRequestActive = true
            
            self.callAnUCABButton.setTitle("Cancel UCAB", for: [])
        
            let riderRequest = PFObject(className: "RiderRequest")
        
            riderRequest["username"] = PFUser.current()?.username
        
            riderRequest["location"] = PFGeoPoint(latitude: userLocation.latitude, longitude: userLocation.longitude)
            
            riderRequest.saveInBackground(block: { (success, error) in
                
                if success {
                    
                    print("Called an UCAB")
                    
                    
                } else {
                    
                    self.callAnUCABButton.setTitle("Call An UCAB", for: [])
                    
                    self.riderRequestActive = false
                    
                    self.displayAlert(title: "Could not call UCAB", message: "Please try again!")
                   
                }
                
                
            })
            
        } else {
            
            displayAlert(title: "Could not call UCAB", message: "Cannot detect your location.")
            
        }
        
        }
        
    }
    
    @IBOutlet var callAnUCABButton: UIButton!
    
    
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "logoutSegue" {
            
            locationManager.stopUpdatingLocation()
            
            PFUser.logOut()
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.startUpdatingLocation()
        
        callAnUCABButton.isHidden = true
        
        let query = PFQuery(className: "RiderRequest")
        
        query.whereKey("username", equalTo: (PFUser.current()?.username)!)
        
        query.findObjectsInBackground(block: { (objects, error) in
            
            if let objects = objects {
                
                if objects.count > 0 {
                
                    self.riderRequestActive = true
                
                    self.callAnUCABButton.setTitle("Cancel UCAB", for: [])
                    
                    self.callAnUCABButton.isHidden = false
                    
                } else {
                    
                    self.riderRequestActive = false
                    
                    self.callAnUCABButton.setTitle("Request an UCAB", for: [])
                    
                    self.callAnUCABButton.isHidden = false
                    
                }
 
            }
            
            
        })

        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let location = manager.location?.coordinate {
            
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            
            if driverOnTheWay == false {
            
                let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            
                self.map.setRegion(region, animated: true)
            
                self.map.removeAnnotations(self.map.annotations)
            
                let annotation = MKPointAnnotation()
            
                annotation.coordinate = userLocation
                
                annotation.title = "Your Location"
            
                self.map.addAnnotation(annotation)
                
            }
            
            let query = PFQuery(className: "RiderRequest")
            
            query.whereKey("username", equalTo: (PFUser.current()?.username)!)
            
            query.findObjectsInBackground(block: { (objects, error) in
                
                if let riderRequests = objects {
                    
                    for riderRequest in riderRequests {
                        
                        riderRequest["location"] = PFGeoPoint(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                        
                        riderRequest.saveInBackground()
                        
                    }
                    
                }
                
                
            })

            
            
        }
        
        if riderRequestActive == true {
            
            let query = PFQuery(className: "RiderRequest")
            
            query.whereKey("username", equalTo: (PFUser.current()?.username!)!)
            
            query.findObjectsInBackground(block: { (objects, error) in
                
                if let riderRequests = objects {
                    
                    for riderRequest in riderRequests {
                        
                        if let driverUsername = riderRequest["driverResponded"] {
                            
                            let query = PFQuery(className: "DriverLocation")
                            
                            query.whereKey("username", equalTo: driverUsername)
                            
                            query.findObjectsInBackground(block: { (objects, error) in
                                
                                if let driverLocations = objects {
                                    
                                    for driverLocationObject in driverLocations {
                                        
                                        if let driverLocation = driverLocationObject["location"] as? PFGeoPoint {
                                            
                                            self.driverOnTheWay = true
                                            
                                            let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                            
                                            let riderCLLocation = CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                                            
                                            let distance = riderCLLocation.distance(from: driverCLLocation) / 1000
                                            
                                            let roundedDistance = round(distance * 100) / 100
                                            
                                            self.callAnUCABButton.setTitle("Your driver is \(roundedDistance)km away!", for: [])
                                            
                                            let latDelta = abs(driverLocation.latitude - self.userLocation.latitude) * 2 + 0.005
                                            
                                            let lonDelta = abs(driverLocation.longitude - self.userLocation.longitude) * 2 + 0.005
                                            
                                            let region = MKCoordinateRegion(center: self.userLocation, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
                                            
                                            self.map.removeAnnotations(self.map.annotations)
                                            
                                            self.map.setRegion(region, animated: true)
                                            
                                            let userLocationAnnotation = MKPointAnnotation()
                                            
                                            userLocationAnnotation.coordinate = self.userLocation
                                            
                                            userLocationAnnotation.title = "Your location"
                                            
                                            self.map.addAnnotation(userLocationAnnotation)
                                            
                                            let driverLocationAnnotation = MKPointAnnotation()
                                            
                                            driverLocationAnnotation.coordinate = CLLocationCoordinate2D(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                            
                                            driverLocationAnnotation.title = "Your driver"
                                            
                                            self.map.addAnnotation(driverLocationAnnotation)
                                            
                                        }
                                        
                                        
                                    }
                                    
                                }
                                
                                
                            })
                            
                        }
                        
                        
                    }
                    
                }
                
            })
            
        }
        
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
