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
import Firebase

//@objc(SettingsViewController)  // match the ObjC symbol name inside Storyboard
class SettingsViewController: UIViewController, UITextFieldDelegate {
    
    var settingsArray = [Setting]()
    
    @IBOutlet weak var instructionText: UILabel!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        
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
        
        instructionText.lineBreakMode = NSLineBreakMode.byWordWrapping
        instructionText.numberOfLines = 0
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
        Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { (user, error) in
            if error != nil {
                print(error!)
            } else {
                print("Registration successful.")
            }
        }
    }
    
    //MARK: Log in is pressed
    @IBAction func loginPressed(_ sender: UIButton) {
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




