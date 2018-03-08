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
    
    
    
    //MARK: Tableview datasource methods
    // Create the two datasource methods that specify 1. what the cells should display, and 2. how many rows we want in the tableview.
    // Method 1
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "mealCell", for: indexPath)
        let meal = mealArray[indexPath.row]
//        var incrementingListNumber = meal.index
//        incrementingListNumber += 1
        cell.textLabel?.text = "\(meal.index): " + meal.mealName!
//        cell.textLabel?.text = "\(incrementingListNumber): " + meal.mealName!
        
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

    
    //MARK: Button to randomize the list
    @IBAction func randomizeListButton(_ sender: Any) {
        randomizeList()

        self.saveMeals()
        self.loadMeals()
    }
    
    //MARK: Function that will randomize the order of all of the meals in itemArray AKA mealListArray
    func randomizeList() {
        tableView.reloadData()
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
        tableView.reloadData()
    }
    
    
    
}

