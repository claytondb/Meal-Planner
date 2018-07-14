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
        checkCurrentUser()
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
    
    func checkCurrentUser() {
        if Auth.auth().currentUser != nil {
            let user = Auth.auth().currentUser
            if let user = user {
//                let uid = user.uid
                let email = user.email
//                print("\(uid) is signed in and their email is \(email ?? "someone@email.com").")
                self.loggedInLabel.text = "Welcome, \(email ?? "human")."
            }
        } else {
            print("Nobody is signed in.")
        }
    }
    
    @IBAction func logOutPressed(_ sender: Any) {
        //        unwind(for: UIStoryboardSegue, towardsViewController: SettingsViewController)
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    @IBAction func deleteAccountPressed(_ sender: UIButton) {
        let user = Auth.auth().currentUser
        user?.delete { error in
            if error != nil {
                // An error happened.
                print(error ?? "An error occurred.")
            } else {
                // Account deleted.
                print("Account deleted.")
                self.checkCurrentUser()
            }
        }
    }
    
    
}
