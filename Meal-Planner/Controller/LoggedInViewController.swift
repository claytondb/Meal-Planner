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
import Firebase

class LoggedInViewController: UIViewController {
    
    @IBOutlet weak var loggedInLabel: UILabel!
    
    override func viewDidLoad() {
        // something here
        loggedInLabel.text = "You are logged in."
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // something here
    }
    
    @IBAction func logOutPressed(_ sender: Any) {
//        unwind(for: UIStoryboardSegue, towardsViewController: SettingsViewController)
    }
    
    
    
}
