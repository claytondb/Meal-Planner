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

// 1. Get UIImage from image picker. (This works)
// 2. Save the image data (in Documents folder) (This works)
// 3. Get string value for the file path to Documents folder and image there (This works)
// 4. Save this string in Core Data in Meal entity as mealImagePath (This works)
// Do steps 2-4 in reverse elsewhere in the app to use the stored image for that meal. -- doesn't work yet

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
        
        // Retrieve stored image for this meal. Works but URL is formatted weird and has other information that isn't the image filename.
        if mealPassedIn.mealImagePath != nil {
            let decodedString = mealPassedIn.mealImagePath
            let unwrappedDecodedString = decodedString!.removingPercentEncoding
            mealImageView.image = UIImage(contentsOfFile: unwrappedDecodedString!)
            print("Got stored image via URL")
            print("Decoded image path is \(unwrappedDecodedString!)")
        } else {
            mealImageView.image = UIImage(named: "mealPlaceholder")
            print("Used placeholder image")
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
//            let pickedImagePath = Bundle.main.path(forResource: "\(pickedImage)", ofType: "png")
//            print("This is the pickedImagePath: \(pickedImagePath)") // Returns nil
            
            // get stored image and path
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first
            {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent("\(pickedImage)")
                //TODO: Make pickedImage the filename instead of the more detailed asset information.
                
                // set global var storedImageURL to this image's url.
                storedImageURL = imageURL
                print("Stored image URL is \(storedImageURL!)")
                
                // Set mealImagePath to the string version of imageURL
                mealPassedIn.mealImagePath = storedImageURL!.absoluteString
                print("Set mealImagePath to the storedImageURL")
                
//                storedMealImage = UIImage(contentsOfFile: imageURL.path)
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





