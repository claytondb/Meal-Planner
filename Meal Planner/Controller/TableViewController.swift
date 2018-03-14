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
    let meal = Meal()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        
        loadMeals()
    }
    
    
    func rearrange<T>(array: Array<T>, fromIndex: Int, toIndex: Int) -> Array<T>{
        var arr = array
        let element = arr.remove(at: 0)
        arr.insert(element, at: 0)
        
        return arr
    }
    
    
    //MARK: Tableview datasource methods
    // Create the two datasource methods that specify 1. what the cells should display, and 2. how many rows we want in the tableview.
    // Method 1
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // create random number constant
        let randomIndex = arc4random_uniform(UInt32(mealArray.count))
        
        // 'meal' is now the item in mealArray at indexPath.row. This is the index of the row element in the indexpath of mealArray.
        let meal = mealArray[indexPath.row]
        
        // make the sortedIndex property the random number
        meal.sortedIndex = Int32(randomIndex)
        
        // grab the cell known as mealCell for whatever the indexPath is. This is returned at the end of the function as UITableViewCell.
        let cell = tableView.dequeueReusableCell(withIdentifier: "mealCell", for: indexPath)
        
        // rearrange the array so that meal indices are the same as the sortedIndex of each meal.
        mealArray = rearrange(array: mealArray, fromIndex: mealArray.index(of: meal)!, toIndex: Int(meal.sortedIndex))
        print("Rearrange just happened.")
        
        // Change the string to the sorted index (random number) + meal name.
        cell.textLabel?.text = meal.mealName! + (": \(meal.sortedIndex)")
        
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
    
    
    
    //MARK: Tableview delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Don't keep the row selected
        tableView.deselectRow(at: indexPath, animated: true)
    }

    
    // Randomize button pseudocode
    // 1: Function triggered with button
    // 2: var randomSortedIndex = arc4random
    // 3: replace index attribute (not actual index) with randomSortedIndex value on each meal UNLESS locked = true. (How do we make sure we don't have two of the same value?). Don't want to replace actual index of items.
    // 4: save the new order
    // 5: load meals based on their sortedIndex (this I haven't figured out)
    
    //MARK: Button to randomize the list
    @IBAction func randomizeListButton(_ sender: Any) {

//        if mealArray == self.mealArray.sorted(by: { $0.sortedIndex < $1.sortedIndex }) {
//            print("descending")
//            mealArray = self.mealArray.sorted(by: { $0.sortedIndex > $1.sortedIndex })
//        } else {
//            print("ascending")
//            mealArray = self.mealArray.sorted(by: { $0.sortedIndex < $1.sortedIndex })
//        }
        
        self.loadMeals()
        print("Loaded meals.")
        self.saveMeals()
        print("Saved meals.")

    }
    
    
    @IBAction func addMeal(_ sender: UIBarButtonItem) {
        print("Adding meal")
        var textField = UITextField()
        let alert = UIAlertController(title: "Add meal", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add", style: .default) { (action) in
            
            // stuff that happens when user taps add
            let newMeal = Meal(context: self.context)
            newMeal.mealName = textField.text!
            newMeal.mealLocked = false
            newMeal.sortedIndex = Int32(self.mealArray.count) + 1
            self.mealArray.append(newMeal)
            
            print("Assigned index to new meal")
            self.saveMeals()
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Chicken con pollo"
            textField = alertTextField
        }
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func deleteMeal(_ sender: UIButton) {
        print("Deleting meal")
        let alert = UIAlertController(title:"Delete meal?", message: "This action cannot be undone.", preferredStyle: .alert)
        let delete = UIAlertAction(title:"Delete", style: .destructive) { (action) in
            
            // Find parent of the button (cell), then parent of cell (table row), then index of that row.
            let parentCell = sender.superview?.superview as! UITableViewCell
            let parentTable = parentCell.superview as! UITableView
            let indexPath = parentTable.indexPath(for: parentCell)
            let mealToDelete = self.mealArray[indexPath!.row]
            
            // Use index of row to delete it from table and CoreData
            self.context.delete(mealToDelete)
            self.mealArray.remove(at: indexPath!.row)
            print("Successfully deleted meal.")
            
            // Save data and reload
            self.saveMeals()
            self.loadMeals()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // do nothing
            print("Cancelled")
        }
        alert.addAction(delete)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    
    
    //MARK: Model manipulation methods
    func saveMeals(){
        do {
            try context.save()
        } catch {
            print("Error saving meals. \(error)")
        }
        self.tableView.reloadData()
    }
    
    func loadMeals(with request: NSFetchRequest<Meal> = Meal.fetchRequest()) {
        do {
            mealArray = try context.fetch(request)
        } catch {
            print("Error loading meals. \(error)")
        }
        self.tableView.reloadData()
    }
    
    
}



