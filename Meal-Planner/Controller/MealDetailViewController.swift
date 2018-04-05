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

class MealDetailViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    var mealArray = [Meal]()
    var mealPassedIn = Meal()
    var imagePicker = UIImagePickerController()
    var storedImageURL : URL?
    var storedMealImage : UIImage?
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mealImageView: UIImageView!
    @IBOutlet weak var mealNameField: UITextField!
    @IBOutlet weak var mealLinkField: UITextField!
    
    
    // Start the view controller
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        
        mealNameField.delegate = self
        mealLinkField.delegate = self
        
        self.mealNameField.keyboardType = UIKeyboardType.default
        
        loadMeals()
        
        print("\(mealPassedIn.mealName!) detail view")
        
        // Change label to name of meal
        mealNameField.text = mealPassedIn.mealName
        mealLinkField.text = mealPassedIn.mealRecipeLink
        
        // Set meal image
        if mealPassedIn.mealImagePath != nil {
            readImageData()
        } else {
            mealImageView.image = UIImage(named: "mealPlaceholder")
        }
    }
    
    //Mark: Make page scroll up when keyboard appears.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
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
    
    @IBAction func saveButton(_ sender: UIBarButtonItem) {
        // Change meal name to what's in the text field
        mealPassedIn.mealName = mealNameField.text
        saveToAlbum(self)
        saveMealDetail()
        performSegue(withIdentifier: "segueDismissMealDetail", sender: self)
    }
    func saveToAlbum(_ sender: AnyObject) {
        UIImageWriteToSavedPhotosAlbum(mealImageView.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "segueDismissMealDetail", sender: self)
    }
    
    //MARK: Action sheet for photo actions (import, take photo, delete)
    func photoActionSheet() {
        let photoActions = UIAlertController(title: "Photo actions", message: "Message", preferredStyle: UIAlertControllerStyle.actionSheet)
    
        self.present(photoActions, animated: true, completion: nil)
        
        photoActions.addAction(UIAlertAction(title: "Take photo", style: UIAlertActionStyle.default, handler: { action in
            self.takePhoto()
        }))
    
        photoActions.addAction(UIAlertAction(title: "Import photo", style: .default, handler: { action in
            self.chooseImage()
        }))
        
        photoActions.addAction(UIAlertAction(title: "Delete photo", style: .destructive, handler: nil))
        
        photoActions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    }
    
    @IBAction func importImageButton(_ sender: UIButton) {
        photoActionSheet()
//        chooseImage()
    }
    
    func chooseImage() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            mealImageView.contentMode = .scaleAspectFill
            mealImageView.image = pickedImage
            storedMealImage = pickedImage
            
            // get stored image and path
            let fileManager = FileManager.default
            do {
                let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
                let fileURL = documentDirectory.appendingPathComponent("\(pickedImage.imageAsset!)")
                
                let image = pickedImage
                if let imageData = UIImageJPEGRepresentation(image, 1.0) {
                    try imageData.write(to: fileURL)
                    storedImageURL = fileURL
                    mealPassedIn.mealImagePath = storedImageURL!.absoluteString
                    mealPassedIn.mealImagePath = mealPassedIn.mealImagePath?.decodeUrl()
                }
            } catch {
                print(error)
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Take image
    func takePhoto() {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    //MARK: - Saving Image here - not working yet. It saves but to documents? Not photo library. What do I connect this to?
//    @IBAction func saveToAlbum(_ sender: AnyObject) {
//        UIImageWriteToSavedPhotosAlbum(mealImageView.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
//    }
    
    //MARK: - Add image to Library
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
//    //MARK: - Done image capture here
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
//        imagePicker.dismiss(animated: true, completion: nil)
//        imageTake.image = info[UIImagePickerControllerOriginalImage] as? UIImage
//    }
    
    
    //MARK: Model manipulation methods
    func saveMealDetail(){
        do {
            try context.save()
        } catch {
            print("Error saving meals. \(error)")
        }
        print("Detail saved")
    }
    
    func loadMeals(with request: NSFetchRequest<Meal> = Meal.fetchRequest()) {
        do {
            mealArray = try context.fetch(request)
        } catch {
            print("Error loading meals. \(error)")
        }
        print("Meals loaded")
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





