//
//  LoggedInViewController.swift
//  Meal Planner
//
//  Created by Clayton, David on 6/20/18.
//  Copyright © 2018 Clayton, David. All rights reserved.
//
import UIKit
import Foundation
import CoreData
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class LoggedInViewController: UIViewController {
    
    var handle: Any?
    @IBOutlet weak var loggedInLabel: UILabel!
    
    override func viewDidLoad() {
        // something here
        loggedInLabel.text = "You are logged in."
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // something here
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Firebase auth
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            print("Added auth state change listener.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //Firebase auth. Added "as! AuthStateDidChangeListenerHandle" because var handle is of type 'Any?'.
        Auth.auth().removeStateDidChangeListener(handle! as! AuthStateDidChangeListenerHandle)
        print("Removed auth state change listener.")
    }
    
    @IBAction func logOutPressed(_ sender: Any) {
        //        unwind(for: UIStoryboardSegue, towardsViewController: SettingsViewController)
    }
    
    
    
}
