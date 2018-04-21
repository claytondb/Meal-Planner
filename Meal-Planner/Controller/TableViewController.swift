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
import GameplayKit

class TableViewController: UITableViewController {
    
    var mealArray = [Meal]()
    
    var meal = Meal()
    
    var mealsToShuffleArray = [Meal]()
    
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
        if meal.mealImagePath != nil && meal.mealImagePath != ""{
            let mealImageURL = URL(string: (meal.mealImagePath?.encodeUrl())!)
            if let imageData = try? Data(contentsOf: mealImageURL!) {
                cell.mealImage.image = UIImage(data: imageData)
            } else {
                cell.mealImage.image = UIImage(named: "mealPlaceholder")
            }
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
//        if mealArray.count <= 7 {
//        return mealArray.count
//        } else {
//            return 7
//        }
        return mealArray.count
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
        loadMeals()
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
    // New way I'm going to do this:
    // 1. Go through each item in the list, and if it's unlocked put it into mealsToShuffleArray
    // 2. If it's locked, skip to the next meal in the list.
    // 3. When I reach the end/top, shuffle the meals in mealsToShuffle using shuffle function from GameplayKit.
    // 4. Go back through each item in the list, and if it's unlocked, swap in the first item from mealsToShuffleArray.
    // 5. If it's locked, skip to the next meal in the list.
    // 6. Do this swapping until eaching the end/top of the list.
    func randomize(with request: NSFetchRequest<Meal> = Meal.fetchRequest()) {

        // There's a weird bug right now. When you lock an item after shuffling, it shuffles everything including the locked item. But after you do that once it stays in place and it's fine. I need to check where it's loading/saving/reloading table data, where it's randomizing, and make sure they're happening in the right order.
        do {
            mealArray = try context.fetch(request)
            var lastMealInt : Int = mealArray.count - 1
            print("LastMealInt is \(lastMealInt).")

            // step 1
            while(lastMealInt > -1)
            {
                let mealToCheck : Meal = mealArray[lastMealInt]
                if mealToCheck.mealLocked == false {
                    mealsToShuffleArray.append(mealToCheck)
                    print("Put \(mealToCheck.mealName!) into mealsToShuffleArray.")
                }
                // step 2
                else if mealToCheck.mealLocked == true {
                    // do nothing
                }
                lastMealInt -= 1
            }
            
            var lastShuffledMealInt : Int = mealsToShuffleArray.count - 1
            print("Moved \(lastShuffledMealInt) unlocked meals to mealsToShuffleArray.")
            
            // step 3: shuffle the meals
            mealsToShuffleArray = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: mealsToShuffleArray) as! [Meal]
            print("Shuffled unlocked meals in mealsToShuffleArray")
            
            // reset lastMealInt to the bottom item in the list
            lastMealInt = mealArray.count - 1
            print("Reset lastMealInt. Now it's \(lastMealInt).")
            
            // step 4 - never gets to this for some reason?
            while(lastMealInt > -1 && lastShuffledMealInt > -1)
            {
                let mealToCheck : Meal = mealArray[lastMealInt]
                let mealToSwapIn : Meal = mealsToShuffleArray[lastShuffledMealInt]
                if mealToCheck.mealLocked == false {
                    mealArray.remove(at: lastMealInt)
                    mealArray.insert(mealToSwapIn, at: lastMealInt)
                    mealsToShuffleArray.remove(at: lastShuffledMealInt)
                    lastShuffledMealInt -= 1
                }
                    // step 5
                else if mealToCheck.mealLocked == true {
                    // do nothing
                }
                lastMealInt -= 1
            }
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
        performSegue(withIdentifier: "segueToMealDetail", sender: self)
        print("Performed segue to meal detail")
    }
    
    
    //MARK: Button to randomize the list
    @IBAction func randomizeListButton(_ sender: Any) {
        randomize()
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
    

    
    
    @IBAction func lockButton(_ sender: CustomMealCell) {

        print("Setting lock state")

        // find parent of button, then cell, then index of row.
        let parentCell = sender.superview?.superview as! UITableViewCell
        print("set parentCell")

        // Fixed error - added second superview so it's not just UITableViewWrapper being cast as UITableView.
        let parentTable = parentCell.superview?.superview as! UITableView
        print("set parentTable")

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



