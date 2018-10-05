//
//  FirstRunViewController.swift
//  Meal Planner
//
//  Created by Clayton, David on 10/5/18.
//  Copyright © 2018 Clayton, David. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import CPLoadingView
// Pod for loading animation is documented here https://github.com/cp3hnu/CPLoading
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class FirstRunViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var loadingView: CPLoadingView!
    @IBOutlet weak var instructionText: UILabel!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var loggedInContainerView: UIView!
    @IBOutlet weak var logOutButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var passwordLabel: UILabel!
    
    var handle : Any?
    var username : AuthDataResult?
    //    var ref : DatabaseReference!
    //    let userID = Auth.auth().currentUser?.uid
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.delegate = self
        passwordField.delegate = self
        
        self.emailField.keyboardType = UIKeyboardType.emailAddress
        self.passwordField.keyboardType = UIKeyboardType.default

    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Mark: Make page scroll up when keyboard appears.
        registerKeyboardNotifications()
        
        //MARK: Google analytics stuff
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.set(kGAIScreenName, value: "Settings view controller")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
        //End google analytics stuff.
        
        //Firebase auth
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            print("Added auth state change listener.")
        }
        
        instructionText.lineBreakMode = NSLineBreakMode.byWordWrapping
        instructionText.numberOfLines = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkCurrentUser()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //Firebase auth. Added "as! AuthStateDidChangeListenerHandle" because var handle is of type 'Any?'.
        Auth.auth().removeStateDidChangeListener(handle! as! AuthStateDidChangeListenerHandle)
        print("Removed auth state change listener.")
    }
    
    func goToApp() {
        // This is a function to segue to the rest of the app once registered or logged in. Dismisses view controller.
        performSegue(withIdentifier: "segueToApp", sender: FirstRunViewController.self)
    }
    
    func checkCurrentUser() {
        if Auth.auth().currentUser != nil {
            let user = Auth.auth().currentUser
            if let user = user {
                let uid = user.uid
                let email = user.email
                print("\(uid) is signed in and their email is \(email ?? "someone@email.com").")
                self.instructionText.text = "Welcome, \(email ?? "friend")."
                self.emailLabel.isHidden = true
                self.emailField.isHidden = true
                self.passwordLabel.isHidden = true
                self.passwordField.isHidden = true
                self.registerButton.isHidden = true
                self.logOutButton.isHidden = false
                self.logInButton.isHidden = true
                goToApp()
            }
        } else {
            print("Nobody is signed in.")
            self.instructionText.text = "Never lose your meals! Register or Log In to enable automatic cloud backup."
            self.emailLabel.isHidden = false
            self.emailField.isHidden = false
            self.passwordLabel.isHidden = false
            self.passwordField.isHidden = false
            self.registerButton.isHidden = false
            self.logOutButton.isHidden = true
            self.logInButton.isHidden = false
        }
    }
    
    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillHide,
                                               object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    @objc func keyboardWillShow(notification: NSNotification) {
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardInfo = userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue
        let keyboardSize = keyboardInfo.cgRectValue.size
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + 24, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool // called when 'return' key pressed. return NO to ignore.
    {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        return true
    }
    
    //MARK: Register is pressed
    @IBAction func registerPressed(_ sender: UIButton) {
        // Show loading podfile animation
        self.loadingView.isHidden = false
        self.loadingView.startLoading()
        self.loadingView.progress = 0.0
        self.loadingView.strokeColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        
        Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { (user, error) in
            if error != nil {
                print(error!)
                self.loadingView.strokeColor = UIColor(red: 255, green: 0, blue: 0, alpha: 1.0)
                self.loadingView.progress = 1.0
                self.loadingView.completeLoading(success: false)
                self.loadingView.hidesWhenCompleted = true
                self.errorLabel.text = "\(error!.localizedDescription)"
            } else {
                print("Registration successful.")
                self.errorLabel.text = ""
                self.loadingView.strokeColor = UIColor(red: 0, green: 255, blue: 0, alpha: 1.0)
                self.loadingView.progress = 1.0
                self.loadingView.completeLoading(success: true)
                self.loadingView.hidesWhenCompleted = true
                self.username = user
                self.checkCurrentUser()
                self.goToApp()
            }
        }
    }
    
    //MARK: Log in is pressed
    @IBAction func loginPressed(_ sender: UIButton) {
        self.loadingView.isHidden = false
        self.loadingView.startLoading()
        self.loadingView.progress = 0.0
        self.loadingView.strokeColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        
        Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!) { (user, error) in
            if error != nil {
                print(error!)
                self.loadingView.strokeColor = UIColor(red: 255, green: 0, blue: 0, alpha: 1.0)
                self.loadingView.progress = 1.0
                self.loadingView.completeLoading(success: false)
                self.loadingView.hidesWhenCompleted = true
                self.errorLabel.text = "\(error!.localizedDescription)"
            } else {
                print("Login successful.")
                self.errorLabel.text = ""
                self.loadingView.strokeColor = UIColor(red: 0, green: 255, blue: 0, alpha: 1.0)
                self.loadingView.progress = 1.0
                self.loadingView.completeLoading(success: true)
                self.loadingView.hidesWhenCompleted = true
                self.checkCurrentUser()
                self.goToApp()
            }
        }
    }
    
    @IBAction func logOutButtonPressed(_ sender: UIButton) {
        logOut()
        checkCurrentUser()
    }
    
    // Function to log out
    func logOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    // Function to delete account
    func deleteAccount() {
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
    
    //Unwind segue from LoggedInViewController
    @IBAction func unwindToSettingsViewController(segue: UIStoryboardSegue) {
        //nothing goes here
    }
    
    //MARK: Model manipulation methods
    func saveSettings(){
        do {
            try context.save()
        } catch {
            print("Error saving settings. \(error)")
        }
        print("Settings saved and data reloaded")
    }
    
}




