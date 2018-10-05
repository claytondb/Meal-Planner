//
//  MealDetailViewController.swift
//  Meal Planner
//
//  Created by Clayton, David on 3/28/18.
//  Copyright © 2018 Clayton, David. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class MealDetailViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    var mealArray = [Meal]()
    var mealPassedIn = Meal()
    var imagePicker = UIImagePickerController()
    var cameraImagePicker = UIImagePickerController()
    var storedImageURL : URL?
    var storedMealImage : UIImage?
    var cameFromAllMeals : Bool?
    var cameFromWeekMeals : Bool?
    var handle : Any?
    var ref : DatabaseReference!
    var user : User?
//    let userID = Auth.auth().currentUser?.uid
    
    // Firebase Storage
    let storage = Storage.storage()
    var imageReference: StorageReference {
        return Storage.storage().reference().child("images")
    }
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mealImageView: UIImageView!
    @IBOutlet weak var mealNameField: UITextField!
    @IBOutlet weak var mealLinkField: UITextField!
    @IBOutlet weak var mealLinkLabel: UILabel!
    @IBOutlet weak var mealLinkButtonOutlet: UIButton!
    
    
    // Start the view controller
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        mealNameField.delegate = self
        mealLinkField.delegate = self
        
        self.mealNameField.keyboardType = UIKeyboardType.default
        
        print("\(mealPassedIn.mealName!) detail view")
        
        // Change label to name of meal
        if mealPassedIn.mealName == nil {
            mealPassedIn.mealName = "New meal"
        } else if mealPassedIn.mealName != nil {
            mealNameField.text = mealPassedIn.mealName
        }
        
        // Change recipe link text
        if mealPassedIn.mealRecipeLink == nil {
            mealLinkField.text = "http://www.allrecipes.com"
            mealLinkLabel.text = "http://www.allrecipes.com"
            mealPassedIn.mealRecipeLink = "http://www.allrecipes.com"
            mealLinkButtonOutlet.setTitle("http://www.allrecipes.com", for: .normal)
        } else if mealPassedIn.mealRecipeLink != nil {
            mealLinkLabel.text = mealPassedIn.mealRecipeLink
            mealLinkField.text = mealPassedIn.mealRecipeLink
            mealLinkButtonOutlet.setTitle(mealPassedIn.mealRecipeLink, for: .normal)
        }
        
        // Set meal image
        if mealPassedIn.mealImagePath != nil && mealPassedIn.mealImagePath != "" {
            readImageData()
        } else {
            mealImageView.image = UIImage(named: "mealPlaceholder")
        }
    }
    
    
    //Mark: Make page scroll up when keyboard appears.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
        
        //MARK: Google analytics stuff
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.set(kGAIScreenName, value: "Meal Detail view controller")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
        //End google analytics stuff.
        
        //Firebase auth
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            print("Added auth state change listener.")
        }
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
        mealNameField.resignFirstResponder()
        mealLinkField.resignFirstResponder()
        mealLinkField.isHidden = true
        mealLinkButtonOutlet.isHidden = false
        mealLinkButtonOutlet.setTitle(mealLinkField.text, for: .normal)
        mealPassedIn.mealRecipeLink = mealLinkField.text
        return true
    }
    
    //MARK: Function to read back image data
    func readImageData() {
        
        let mealImageURL = URL(string: (mealPassedIn.mealImagePath?.encodeUrl())!)
        print("Meal image URL is \(mealImageURL!)")
        
        if let imageData = try? Data(contentsOf: mealImageURL!) {
            mealImageView.image = UIImage(data: imageData)
        } else {
            // do nothing
        }
    }
    
    // MARK: Save meal to Firebase
    @IBAction func saveButton(_ sender: UIBarButtonItem) {
        
        // Change meal name to what's in the text field
        mealPassedIn.mealName = mealNameField.text
        
        // Create dictionary for firebase
        let mealDictionary = ["MealOwner": Auth.auth().currentUser?.email ?? "",
                              "MealName": mealPassedIn.mealName!,
                              "MealLocked": mealPassedIn.mealLocked,
                              "MealSortedOrder": mealPassedIn.mealSortedOrder,
                              "MealImagePath": mealPassedIn.mealImagePath ?? "",
                              "MealIsReplacing": mealPassedIn.mealIsReplacing,
                              "MealRecipeLink": mealPassedIn.mealRecipeLink ?? "http://www.allrecipes.com",
                              "MealReplaceMe": mealPassedIn.mealReplaceMe,
                              "MealFirebaseID": mealPassedIn.mealFirebaseID!
                              ] as [String : Any]
        
        let mealFirebaseIDDataRef = mealPassedIn.mealFirebaseID
        // Once I know the Firebase ID for the meal, I can update that specific meal on save.
        
        self.ref = Database.database().reference().child("Meals").child(self.user!.uid)
        self.ref.child(mealFirebaseIDDataRef!).setValue(mealDictionary) {
            (error, reference) in
            if error != nil {
                print(error!)
            } else {
                print("Meal saved successfully to Firebase")
            }
        }
        
        if cameFromAllMeals == true {
            self.performSegue(withIdentifier: "unwindToAllMeals", sender: self)
        } else if cameFromWeekMeals == true {
            self.performSegue(withIdentifier: "unwindToWeekMeals", sender: self)
        }
    }
    
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        if cameFromAllMeals == true {
            self.performSegue(withIdentifier: "unwindToAllMeals", sender: self)
        } else if cameFromWeekMeals == true {
            self.performSegue(withIdentifier: "unwindToWeekMeals", sender: self)
        }
    }
    
    
    //MARK: Action sheet for photo actions (import, take photo, delete)
    func photoActionSheet() {
        let photoActions = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        self.present(photoActions, animated: true, completion: nil)
        
        photoActions.addAction(UIAlertAction(title: "Take photo", style: UIAlertActionStyle.default, handler: { action in
            self.takePhoto()
        }))
        
        photoActions.addAction(UIAlertAction(title: "Import photo", style: .default, handler: { action in
            self.chooseImage()
        }))
        
        photoActions.addAction(UIAlertAction(title: "Delete photo", style: .destructive, handler: { action in
            self.deleteImage()
        }))
        
        photoActions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    }
    
    @IBAction func importImageButton(_ sender: UIButton) {
        photoActionSheet()
    }
    
    func chooseImage() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods. This is for importing an image.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            mealImageView.contentMode = .scaleAspectFill
            mealImageView.image = pickedImage
            storedMealImage = pickedImage
            
            // get stored image and path (image path on device when importing)
//            let fileManager = FileManager.default
//            do {
//                let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
//                let fileURL = documentDirectory.appendingPathComponent("\(pickedImage.imageAsset!)") // Only needed if I'm going to reference the image in FileManager on the device. Since it will be coming from Firebase, I can probably delete this.
                
                // I think I only need the below if I'm saving the image to the device.
                // 1. Defines "image" as the image that was picked in the picker
                // 2. Creates "imageData" and gives it quality
                // 3. Tries to write imageData to the file path on the device.
                // 4. Sets variable storedImageURL to the file path of the new image on the device.
                // 5. Sets meal.mealImagePath to the new URL of the image on the device.
//                let image = pickedImage
//                if let imageData = UIImageJPEGRepresentation(image, 0.1) {
//                    try imageData.write(to: fileURL)
//                    storedImageURL = fileURL
//                    mealPassedIn.mealImagePath = storedImageURL!.absoluteString
//                    mealPassedIn.mealImagePath = mealPassedIn.mealImagePath?.decodeUrl()
//                }
                
                // For firebase
                let image = pickedImage
                guard let imageData = UIImageJPEGRepresentation(image, 0.1) else {return}
                mealPassedIn.mealImagePath = "\(pickedImage.imageAsset!)"
                
                // Firebase image upload. This works! Just need to figure out download...
                let uploadImageRef = imageReference.child("\(pickedImage.imageAsset!)") // What's the right file name?
                let uploadTask = uploadImageRef.putData(imageData, metadata: nil) { (metadata, error) in
                    print("Upload task finished.")
                    print(metadata ?? "No metadata for this image.")
                    print(error ?? "No errors.")
                }
                
                uploadTask.observe(.progress) { (snapshot) in
                    print(snapshot.progress ?? "No more progress.")
                }
                
                uploadTask.resume()
                
//            } catch {
//                print(error)
//            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Take image
    func takePhoto() {
        cameraImagePicker.delegate = self
        cameraImagePicker.sourceType = .camera
        cameraImagePicker.allowsEditing = true
        present(cameraImagePicker, animated: true, completion: nil)
    }
    
    //MARK: - Saving Image here
    @IBAction func savePhoto(_ sender: AnyObject) {
        UIImageWriteToSavedPhotosAlbum(mealImageView.image!, self, #selector(imageSaveToLibrary(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    //MARK: - Add image to Library
    @objc func imageSaveToLibrary(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    //MARK: - Done image capture here
    func cameraImagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            UIImageWriteToSavedPhotosAlbum(pickedImage, self, #selector(imageSaveToLibrary(_:didFinishSavingWithError:contextInfo:)), nil)
            dismiss(animated: true, completion: nil)
        }
    }
    
    //MARK: Delete image function
    func deleteImage() {
        let mealImageURL = URL(string: (mealPassedIn.mealImagePath?.encodeUrl())!)
        print("Meal image to be deleted: \(mealImageURL!)")
        
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: (mealImageURL)!)
            mealPassedIn.mealImagePath = nil
            mealImageView.image = UIImage(named: "mealPlaceholder")
            print("Meal image deleted.")
        } catch let err {
            print(err)
        }
    }
    
    //MARK: Edit link button pressed
    @IBAction func editLinkPressed(_ sender: UIButton) {
        if mealLinkField.isHidden == true {
            mealLinkField.isHidden = false
            mealLinkLabel.isHidden = true
            mealLinkField.isEnabled = true
        } else if mealLinkField.isHidden == false {
            mealLinkField.isHidden = true
            mealLinkLabel.isHidden = false
            mealLinkField.isEnabled = false
        }
    }
    
    @IBAction func mealLinkButtonPressed(_ sender: UIButton) {
        // Open URL of mealRecipesLink
        if let url = NSURL(string: mealPassedIn.mealRecipeLink!){
            UIApplication.shared.open(url as URL)
        }
    }
    
    //MARK: Model manipulation methods
    func saveMealDetail(){
        do {
            try context.save()
        } catch {
            print("Error saving meals. \(error)")
        }
        print("Detail saved")
    }

}

extension String
{
    func encodeUrl() -> String
    {
        return self.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    func decodeUrl() -> String
    {
        return self.removingPercentEncoding!
    }
    
}





