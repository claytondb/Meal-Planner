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
    
    
//    func rearrange<T>(array: Array<T>, fromIndex: Int, toIndex: Int) -> Array<T>{
//        var arr = array
//        let element = arr.remove(at: 0)
//        arr.insert(element, at: 0)
//
//        return arr
//    }
    
    
    //MARK: Tableview datasource methods
    // Create the two datasource methods that specify 1. what the cells should display, and 2. how many rows we want in the tableview.
    // Method 1
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let meal = mealArray[indexPath.row]
        
//        randomize()
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "mealCell", for: indexPath)
        print("Rearrange just happened.")
        cell.textLabel?.text = meal.mealName!
        
        return cell
    }
    
    func randomize() {
        
        // This code works when it's in the Tableview datasource method.
        var last = mealArray.count - 1
        while(last > 0)
        {
            let rand = Int(arc4random_uniform(UInt32(last)))
            mealArray.swapAt(last, rand)
            last -= 1
        }
        
    }
    
    
//    // Override to support editing the table view.
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            // Delete the row from the data source
//            mealArray.remove(at: indexPath.row)
//            // Delete the row from the TableView
//            tableView.deleteRows(at: [indexPath], with: .fade)
//        }
//    }

    // Method 2
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if mealArray.count <= 7 {
//        return mealArray.count
//        } else {
//            return 7
//        }
        let count = mealArray.count
        return count
    }
    
    
    
    //MARK: Tableview delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Don't keep the row selected
        tableView.deselectRow(at: indexPath, animated: true)
    }

//    //MARK: Edit button to bring up delete toggles.
//    @IBAction func editButton(_ sender: UIBarButtonItem) {
//        
////        tableView.setEditing(!tableView.isEditing, animated: true)
//        
//        if(self.tableView.isEditing == true)
//        {
//            self.tableView.setEditing(false, animated: true)
//            self.editButtonItem.title = "Done"
//        }
//        else
//        {
//            self.tableView.setEditing(true, animated: true)
//            self.editButtonItem.title = "Edit"
//        }
//    }
    

    
    //MARK: Button to randomize the list
    @IBAction func randomizeListButton(_ sender: Any) {
        
        randomize()
        
        self.saveMeals()
        print("Saved meals.")
        self.loadMeals()
        print("Loaded meals.")
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
    
    @IBAction func lockButton(_ sender: UIButton) {
        // find parent of button, then cell, then index of row.
        let parentCell = sender.superview?.superview as! UITableViewCell
        let parentTable = parentCell.superview as! UITableView
        let indexPath = parentTable.indexPath(for: parentCell)
        let mealToLock = self.mealArray[indexPath!.row]
        
        // Use index of row to set mealLocked of meal to true
        if mealToLock.mealLocked == true {
            mealToLock.mealLocked = false
            print("Meal unlocked")
        } else {
            mealToLock.mealLocked = true
            print("Meal locked")
        }
        
        // Save data
        self.saveMeals()
        self.loadMeals()
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



