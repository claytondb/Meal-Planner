//
//  TableViewController.swift
//  Meal Planner
//
//  Created by Clayton, David on 2/23/18.
//  Copyright © 2018 Clayton, David. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class TableViewController: UITableViewController {
    
    var mealArray = [Meal]()
    
    var meal = Meal()
    
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
        let mealImageURL = URL(string: (meal.mealImagePath?.encodeUrl())!)
        if let imageData = try? Data(contentsOf: mealImageURL!) {
            cell.mealImage.image = UIImage(data: imageData)
        } else {
            cell.mealImage.image = UIImage(named: "mealPlaceholder")
        }
        
        // Set mealDay label to day of the week depending on what row of the table it's in.
        if indexPath.row == 0 {
            cell.mealDay?.text = "Sunday" }
        else if indexPath.row == 1 {
            cell.mealDay?.text = "Monday"
        } else if indexPath.row == 2 {
            cell.mealDay?.text = "Tuesday"
        } else if indexPath.row == 3 {
            cell.mealDay?.text = "Wednesday"
        } else if indexPath.row == 4 {
            cell.mealDay?.text = "Thursday"
        } else if indexPath.row == 5 {
            cell.mealDay?.text = "Friday"
        } else if indexPath.row == 6 {
            cell.mealDay?.text = "Saturday"
        }
        
        // Color cell if it's locked.
        if meal.mealLocked == true {
            cell.backgroundColor = UIColor.lightGray
        } else {
            cell.backgroundColor = UIColor.clear
        }
        
        // Accessing the lock button inside CustomMealCell
        cell.onLockTapped = {
            self.lockMeal(mealToCheck: meal, cellToColor: cell)
        }
        
        return cell
    }
    

    // Method 2
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if mealArray.count <= 7 {
        return mealArray.count
        } else {
            return 7
    }
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
    
    //MARK: Randomize meals function
    func randomize(with request: NSFetchRequest<Meal> = Meal.fetchRequest()) {
    
        // Do-catch statement so that we can catch errors
        do {
            mealArray = try context.fetch(request)
            var lastMealInt : Int = mealArray.count - 1

            while(lastMealInt > -1)
            {
                let randomNumber = Int(arc4random_uniform(UInt32(lastMealInt)))
                let mealAtRandom : Meal = mealArray[randomNumber]
                let mealToCheck : Meal = mealArray[lastMealInt]
                if mealToCheck.mealLocked == false && mealAtRandom.mealLocked == false {
                    mealArray.swapAt(lastMealInt, randomNumber)
                    print("Swapped \(mealToCheck.mealName!) with \(mealAtRandom.mealName!)")
                }
                else if mealToCheck.mealLocked == false && mealAtRandom.mealLocked == true {
                    // do nothing
                }
                else if mealToCheck.mealLocked == true && mealAtRandom.mealLocked == false {
                    // do nothing
                }
                else if mealToCheck.mealLocked == true && mealAtRandom.mealLocked == true {
                    // do nothing
                }
                else {
                    // do nothing
                }
                lastMealInt -= 1
            }
            print("Randomized!")
        }
        
        // Second part of Do-Catch
        catch {
            print("Error loading meals. \(error)")
        }
        saveMeals()
    }
    
    //MARK: Pass in data on segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToMealDetail" {
            if let destinationVC = segue.destination as? MealDetailViewController {
                print("Prepared for segue")
                let indexPath = tableView.indexPathForSelectedRow
                destinationVC.mealPassedIn = mealArray[(indexPath?.row)!]
                print("Passed in meal")

            }
        }
    }
    
    //MARK: Tableview delegate methods - select row, segue to meal detail
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        print("meal = meal at indexpath in the table")
//        let selectedMeal : Meal = mealArray[indexPath.row]
    
        performSegue(withIdentifier: "segueToMealDetail", sender: self)
        print("Performed segue to meal detail")
        
        // When row is selected, you edit the meal name in an alert.
//        editMealName()
        
        // When row is selected, lock/unlock it. Then save it.
//        let meal : Meal = mealArray[indexPath.row]
//        let cell = tableView.dequeueReusableCell(withIdentifier: "customMealCell", for: indexPath) as! CustomMealCell
//        lockMeal(mealToCheck: meal, cellToColor: cell)
        
    }
    
    
    //MARK: Button to randomize the list
    @IBAction func randomizeListButton(_ sender: Any) {
        
        randomize()

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
//            newMeal.sortedIndex = Int32(self.mealArray.count) + 1
//            self.mealArray.append(newMeal)
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
    

    
    
    @IBAction func lockButton(_ sender: CustomMealCell) {

        print("Setting lock state")

        // find parent of button, then cell, then index of row.
        let parentCell = sender.superview?.superview as! UITableViewCell
        print("set parentCell")

        // Fixed error - added second superview so it's not just UITableViewWrapper being cast as UITableView.
        let parentTable = parentCell.superview?.superview as! UITableView
        print("set parentTable")

        // Had to remove second superview because it said could not cast UIWindow as UITableView.
//        let parentTable = parentCell.superview as! UITableView
//        print("set parentTable")

        let indexPath = parentTable.indexPath(for: parentCell)
        print("set indexPath")

        let mealToLock = self.mealArray[indexPath!.row]
        print("set mealToLock")


        // Use index of row to set mealLocked of meal to true/false
        lockMeal(mealToCheck: mealToLock, cellToColor: parentCell)


        // Save data
        saveMeals()

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



