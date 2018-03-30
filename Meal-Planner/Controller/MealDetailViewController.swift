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
    
    @IBOutlet weak var mealImageView: UIImageView!
    
    @IBOutlet weak var mealNameLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        
        loadMeals()
        
        print("meal name is \(mealPassedIn.mealName!)")
        mealNameLabel.text = mealPassedIn.mealName
        
        //MARK: Make imageView a button
        let button = UIButton(type: .custom)
//        button.frame = CGRect(x: 160, y: 100, width: 50, height: 50)
//        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        button.setImage(UIImage(named:"\(mealImageView.image!)"), for: .normal)
        button.addTarget(self, action: #selector(chooseImage), for: .touchUpInside)
        view.addSubview(button)
        
    }
    
    @IBAction func saveButton(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "segueDismissMealDetail", sender: self)
    }
    
    @IBAction func importImageButton(_ sender: UIButton) {
        chooseImage()
    }
    
    @objc func chooseImage() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            mealImageView.contentMode = .scaleAspectFill
            mealImageView.image = pickedImage
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
            
//            let editingMeal = self.mealArray[indexPath.row]
//            editingMeal.mealName = textField.text
            
            print("Changed meal name")
            self.saveMeals()
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
    
    
//    @IBAction func addMeal(_ sender: UIBarButtonItem) {
//        print("Adding meal")
//        var textField = UITextField()
//        let alert = UIAlertController(title: "Add meal", message: "", preferredStyle: .alert)
//        let action = UIAlertAction(title: "Add", style: .default) { (action) in
//            
//            // stuff that happens when user taps add
//            let newMeal = Meal(context: self.context)
//            newMeal.mealName = textField.text!
//            newMeal.mealLocked = true
//            newMeal.sortedIndex = Int32(self.mealArrayPassedIn.count) + 1
//            self.mealArrayPassedIn.append(newMeal)
//            
//            print("Assigned index to new meal")
//            self.saveMeals()
//        }
//
//        alert.addTextField { (alertTextField) in
//            alertTextField.placeholder = "Chicken con pollo"
//            textField = alertTextField
//            textField.autocorrectionType = .yes
//        }
//
//        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
//            // do nothing
//            print("Cancelled")
//        }
//        alert.addAction(cancel)
//        alert.addAction(action)
//        present(alert, animated: true, completion: nil)
//    }
    
    // Both deleteMeal and lockButton cause the app to crash on my phone. What's the issue?
//    @IBAction func deleteMeal(_ sender: UIButton) {
//        print("Deleting meal")
//        let alert = UIAlertController(title:"Delete meal?", message: "This action cannot be undone.", preferredStyle: .alert)
//        let delete = UIAlertAction(title:"Delete", style: .destructive) { (action) in
//
//            // Find parent of the button (cell), then parent of cell (table row), then index of that row.
//            let parentCell = sender.superview?.superview as! UITableViewCell
//            let parentTable = parentCell.superview?.superview as! UITableView
//            //            let parentTable = parentCell.superview as! UITableView
//            let indexPath = parentTable.indexPath(for: parentCell)
//            let mealToDelete = self.mealArrayPassedIn[indexPath!.row]
//
//            // Use index of row to delete it from table and CoreData
//            self.context.delete(mealToDelete)
//            self.mealArrayPassedIn.remove(at: indexPath!.row)
//            print("Successfully deleted meal.")
//
//            // Save data and reload
//            self.saveMeals()
//
//        }
//        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
//            // do nothing
//            print("Cancelled")
//        }
//        alert.addAction(delete)
//        alert.addAction(cancel)
//        present(alert, animated: true, completion: nil)
//    }
    
    
    //MARK: Model manipulation methods
    func saveMeals(){
        do {
            try context.save()
        } catch {
            print("Error saving meals. \(error)")
        }
//        self.tableView.reloadData()
        print("Meals saved and data reloaded")
    }
    
    func loadMeals(with request: NSFetchRequest<Meal> = Meal.fetchRequest()) {
        do {
            mealArray = try context.fetch(request)
        } catch {
            print("Error loading meals. \(error)")
        }
//        self.tableView.reloadData()
        print("Meals loaded")
    }

    
}





