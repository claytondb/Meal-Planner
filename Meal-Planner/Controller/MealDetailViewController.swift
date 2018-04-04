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

class MealDetailViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var mealArray = [Meal]()
    var mealPassedIn = Meal()
    let imagePicker = UIImagePickerController()
    var storedImageURL : URL?
    var storedMealImage : UIImage?
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var mealImageView: UIImageView!
    @IBOutlet weak var mealNameLabel: UILabel!
    
    // Start the view controller
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        
        loadMeals()
        
        print("\(mealPassedIn.mealName!) detail view")
        
        // Change label to name of meal
        mealNameLabel.text = mealPassedIn.mealName
        
        // Set meal image
        if mealPassedIn.mealImagePath != nil {
            readImageData()
        } else {
            mealImageView.image = UIImage(named: "mealPlaceholder")
        }
    
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
        saveMealDetail()
        performSegue(withIdentifier: "segueDismissMealDetail", sender: self)
    }
    
    @IBAction func importImageButton(_ sender: UIButton) {
        chooseImage()
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
    

    //MARK: Edit meal name function
    func editMealName() {
        print("Editing meal")
        
        var textField = UITextField()
        let alert = UIAlertController(title: "Edit meal name", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Save", style: .default) { (action) in
            
            print("Changed meal name")
            self.saveMealDetail()
        }
        
        alert.addTextField { (alertTextField) in
//            let editingMeal = self.mealArray[indexPath.row]
            print("let editingMeal = Meal")
//            alertTextField.text = editingMeal.mealName
            textField = alertTextField
            textField.autocorrectionType = .yes
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // do nothing
            print("Cancelled")
        }
        alert.addAction(cancel)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
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





