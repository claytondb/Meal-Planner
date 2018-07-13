//
//  SettingsViewController.swift
//  Meal Planner
//
//  Created by Clayton, David on 3/28/18.
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

class SettingsViewController: UIViewController, UITextFieldDelegate {
    
    var settingsArray = [Setting]()
    
    @IBOutlet weak var loadingView: CPLoadingView!
    @IBOutlet weak var instructionText: UILabel!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var loggedInContainerView: UIView!
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
        
        loadSettings()
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
    
    func checkCurrentUser() {
        if Auth.auth().currentUser != nil {
            let user = Auth.auth().currentUser
            if let user = user {
                let uid = user.uid
                let email = user.email
                print("\(uid) is signed in and their email is \(email ?? "someone@email.com").")
            }
        } else {
            print("Nobody is signed in.")
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
                print(user)
                self.username = user
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
                self.loggedInContainerView.isHidden = false
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
    
    func loadSettings(with request: NSFetchRequest<Setting> = Setting.fetchRequest()) {
        do {
            settingsArray = try context.fetch(request)
        } catch {
            print("Error loading meals. \(error)")
        }
        print("Settings loaded")
    }
    
}




