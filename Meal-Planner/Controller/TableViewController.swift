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
//    let meal = Meal.init(entity: (NSEntityDescription.entity(forEntityName: "Meal", in: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext))!, insertInto: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
    
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "customMealCell", for: indexPath) as! CustomMealCell
        
        print("Loaded cell")
        if meal.mealName == nil {
            meal.mealName = "Meal name"
        }
        cell.mealLabel?.text = meal.mealName!
        print("Got meal name")
        cell.mealImage.image = UIImage(named: "mealPlaceholder")
        print("Got meal placeholder image")
        
//        self.tableView.rowHeight = UITableViewAutomaticDimension;
//        self.tableView.estimatedRowHeight = 64.0;
        
        // color cells if lockeds
        if meal.mealLocked == true {
            cell.backgroundColor = UIColor.lightGray
        } else {
            cell.backgroundColor = UIColor.clear
        }
        
        return cell
    }
    

    func randomize(with request: NSFetchRequest<Meal> = Meal.fetchRequest()) {
            do {
                mealArray = try context.fetch(request)
                
                // This code works!
                var last = mealArray.count - 1
                
                // Compiles but doesn't do anything. This sets meal to generic Meal class, which always has locked state of false. Also ends up creating a null meal and crashes later.
//                let meal = Meal(context: self.context)
//                let meal = self.meal
                
                // this throws an error because it doesn't know what "meal" is.
//                if meal.mealLocked == false {
                while(last > 0)
                {
                    let rand = Int(arc4random_uniform(UInt32(last)))
                    mealArray.swapAt(last, rand)
                    last -= 1
                }
//                } else if meal.mealLocked == true {
//                    mealArray.swapAt(last, last)
                    // do nothing
//                }
                print("Randomized!")
            } catch {
                print("Error loading meals. \(error)")
            }

        self.tableView.reloadData()
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
    
    
    
    //MARK: Tableview delegate methods - select row
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Editing meal")
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
        saveMeals()
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
//            self.loadMeals()
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
        if mealToLock.mealLocked == true {
            mealToLock.mealLocked = false
            print("Meal unlocked")
            parentCell.backgroundColor = UIColor.clear
        } else if mealToLock.mealLocked == false {
            mealToLock.mealLocked = true
            print("Meal locked")
            parentCell.backgroundColor = UIColor.lightGray
        }
        
        // Save data
        self.saveMeals()
//        self.loadMeals()
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



