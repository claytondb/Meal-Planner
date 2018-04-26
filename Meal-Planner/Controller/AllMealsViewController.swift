//
//  AllMealsViewController.swift
//  Meal Planner
//
//  Created by Clayton, David on 3/26/18.
//  Copyright © 2018 Clayton, David. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class AllMealsViewController: UITableViewController {
    
    var mealArray = [Meal]()
    
    let meal = Meal()
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Fix weird overlapping of status bar with navigation bar
        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
        
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        
        self.tableView.backgroundColor = UIColor.white
        
        //TODO: Register your mealXib.xib file here:
        tableView.register(UINib(nibName: "mealXib", bundle: nil), forCellReuseIdentifier: "customMealCell")
        
        loadMeals()
    }
    
    
    //MARK: Tableview datasource methods
    // Create the two datasource methods that specify 1. what the cells should display, and 2. how many rows we want in the tableview.
    // Method 1
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // indexPath.row has to do with the table. It takes that number and gets the meal from mealArray at that number. For example, it looks at indexPath.row of the table and if it's 3, it gets the meal at 3 in the array.
        let meal = mealArray[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "customMealCell", for: indexPath) as! CustomMealCell
        
        // Set meal name
        if meal.mealName == nil {
            meal.mealName = "Meal name"
        } else {
            cell.mealLabel?.text = meal.mealName!
        }
        
        // Set meal image
        if meal.mealImagePath != nil {
            let mealImageURL = URL(string: (meal.mealImagePath?.encodeUrl())!)
            if let imageData = try? Data(contentsOf: mealImageURL!) {
                cell.mealImage.image = UIImage(data: imageData)
            } else {
                cell.mealImage.image = UIImage(named: "mealPlaceholder")
            }
        } else {
            cell.mealImage.image = UIImage(named: "mealPlaceholder")
        }
        
        cell.mealDay.text = ""
        if cell.mealLockIconBtn != nil {
        cell.mealLockIconBtn.removeFromSuperview()
        }
        
        return cell
    }
    
    
    // Method 2
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            
                    let count = mealArray.count
                    return count
        }
    
    
    // Override to support editing the table view. Swipe to delete.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            let mealToDelete = self.mealArray[indexPath.row]
            
            // Use index of row to delete it from table and CoreData
            self.context.delete(mealToDelete)
            self.mealArray.remove(at: indexPath.row)
            print("Successfully deleted meal.")
            
            // Save data and reload
            self.saveMeals()
            
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        print("can move rows")
        
        return true
    }
    func tableView(_ tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        let itemToMove = mealArray[fromIndexPath.row]
        mealArray.remove(at: fromIndexPath.row)
        mealArray.insert(itemToMove, at: toIndexPath.row)
        
        saveMeals()
    }
    @IBAction func startEditing(_ sender: UIBarButtonItem) {
        if self.isEditing == false {
            setEditing(true, animated: true)
        } else {
            setEditing(false, animated: true)
        }
    }
    
    //MARK: Edit meal name function
    func editMealName() {
        print("Editing meal")
        
        let indexPath : IndexPath = tableView.indexPathForSelectedRow!
        var textField = UITextField()
        let alert = UIAlertController(title: "Edit meal name", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Save", style: .default) { (action) in
            
            let editingMeal = self.mealArray[indexPath.row]
            editingMeal.mealName = textField.text
            
            print("Changed meal name")
            self.saveMeals()
        }
        
        alert.addTextField { (alertTextField) in
            let editingMeal = self.mealArray[indexPath.row]
            print("let editingMeal = Meal")
            alertTextField.text = editingMeal.mealName
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
    
    
    
    //MARK: Lock meal function
    func lockMeal(mealToCheck : Meal, cellToColor : UITableViewCell) {
        if mealToCheck.mealLocked == true {
            mealToCheck.mealLocked = false
            print("\(mealToCheck.mealName!) unlocked")
            cellToColor.backgroundColor = UIColor.clear
        } else if mealToCheck.mealLocked == false {
            mealToCheck.mealLocked = true
            print("\(mealToCheck.mealName!) locked")
            cellToColor.backgroundColor = UIColor.lightGray
        }
        saveMeals()
    }
    
    
    //MARK: Tableview delegate methods - select row, segue to meal detail
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "segueFromAllMealsToDetail", sender: self)
        print("Performed segue to meal detail")
        
    }
    
    
    @IBAction func addMeal(_ sender: UIBarButtonItem) {
        print("Adding meal")
        var textField = UITextField()
        let alert = UIAlertController(title: "Add meal", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add", style: .default) { (action) in
            
            // stuff that happens when user taps add
            let newMeal = Meal(context: self.context)
            newMeal.mealName = textField.text!
            newMeal.mealLocked = true
            self.mealArray.append(newMeal)
            
            print("Assigned index to new meal")
            self.saveMeals()
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Chicken con pollo"
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
    
    // Both deleteMeal and lockButton cause the app to crash on my phone. What's the issue?
    @IBAction func deleteMeal(_ sender: UIButton) {
        print("Deleting meal")
        let alert = UIAlertController(title:"Delete meal?", message: "This action cannot be undone.", preferredStyle: .alert)
        let delete = UIAlertAction(title:"Delete", style: .destructive) { (action) in
            
            // Find parent of the button (cell), then parent of cell (table row), then index of that row.
            let parentCell = sender.superview?.superview as! UITableViewCell
            let parentTable = parentCell.superview?.superview as! UITableView
            //            let parentTable = parentCell.superview as! UITableView
            let indexPath = parentTable.indexPath(for: parentCell)
            let mealToDelete = self.mealArray[indexPath!.row]
            
            // Use index of row to delete it from table and CoreData
            self.context.delete(mealToDelete)
            self.mealArray.remove(at: indexPath!.row)
            print("Successfully deleted meal.")
            
            // Save data and reload
            self.saveMeals()
            
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // do nothing
            print("Cancelled")
        }
        alert.addAction(delete)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: Pass in data on segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueFromAllMealsToDetail" {
            if let destinationVC = segue.destination as? MealDetailViewController {
                print("Prepared for segue")
                let indexPath = tableView.indexPathForSelectedRow
                destinationVC.mealPassedIn = mealArray[(indexPath?.row)!]
                print("Passed in meal")
                
            }
        }
    }
    
    
    //MARK: Model manipulation methods
    func saveMeals(){
        do {
            try context.save()
        } catch {
            print("Error saving meals. \(error)")
        }
        self.tableView.reloadData()
        print("Meals saved and data reloaded")
    }
    
    func loadMeals(with request: NSFetchRequest<Meal> = Meal.fetchRequest()) {
        do {
            mealArray = try context.fetch(request)
        } catch {
            print("Error loading meals. \(error)")
        }
        self.tableView.reloadData()
        print("Meals loaded")
    }
    
    
}




