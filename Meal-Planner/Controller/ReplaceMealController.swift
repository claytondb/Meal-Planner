//
//  ReplaceMealController.swift
//  Meal Planner
//
//  Created by Clayton, David on 4/30/18.
//  Copyright © 2018 Clayton, David. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class ReplaceMealController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    var mealArray = [Meal]()
    var mealSortedOrderArray = [Meal]()
    var filteredMealsArray = [Meal]()
    let meal = Meal()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var mealPassedIn = Meal()
    var mealToPassBack = Meal()
    var mealToPassBackNewSortOrder : Int32 = 0
    var mealPassedInNewSortOrder : Int32 = 0
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mealSearchField: UISearchBar!
    
    override func viewDidLoad() {
        
        print("View did load ReplaceMealController")
        
        super.viewDidLoad()
        
        loadMeals()
        sortMeals()
        
        //TODO: Register your mealXib.xib file here:
        tableView.register(UINib(nibName: "mealXib", bundle: nil), forCellReuseIdentifier: "customMealCell")
        print("Loaded custom mealXib")
        
        tableView.backgroundColor = UIColor.white
    
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.mealSearchField.delegate = self
        filteredMealsArray = mealArray
        
    }
    
    
    //MARK: Tableview datasource methods
    // Create the two datasource methods that specify 1. what the cells should display, and 2. how many rows we want in the tableview.
    // Method 1
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // indexPath.row has to do with the table. It takes that number and gets the meal from mealArray at that number. For example, it looks at indexPath.row of the table and if it's 3, it gets the meal at 3 in the array.
//        let meal = mealArray[indexPath.row]
        let meal = filteredMealsArray[indexPath.row]
        
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
        
        if cell.mealSwapBtn != nil {
            cell.mealSwapBtn.removeFromSuperview()
        }
        
        // Hide the swap and lock buttons
//        cell.mealSwapBtn.isHidden = true
//        cell.mealLockIconBtn.isHidden = true
        
        return cell
    }
    
    
    // Method 2
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        let count = mealArray.count
        let count = filteredMealsArray.count
        return count
    }
    
    
    
    //MARK: Tableview delegate methods - select row and it will segue back to week view and pass in the selection.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "customMealCell", for: indexPath) as! CustomMealCell
//        cell.backgroundColor = UIColor.blue
        mealToPassBack = filteredMealsArray[indexPath.row]
        print("mealToPassBack is \(mealToPassBack.mealName!)")
//        mealToPassBack.mealIsReplacing = true
        
        swapSortingOrders()
        
        saveMeals()
        performSegue(withIdentifier: "unwindToWeekMeals", sender: self)
    }
    
    //MARK: Function to swap sorting orders
    func swapSortingOrders() {
        mealToPassBackNewSortOrder = mealPassedIn.mealSortedOrder
        mealPassedInNewSortOrder = mealToPassBack.mealSortedOrder
        mealPassedIn.mealSortedOrder = mealPassedInNewSortOrder
        mealToPassBack.mealSortedOrder = mealToPassBackNewSortOrder
        print("Swapped sorted orders")
    }
    
    
    //MARK: Function to sort tableview according to mealSortedIndex
    func sortMeals() {
        do {
            var lastMealInt : Int = filteredMealsArray.count - 1
            lastMealInt = filteredMealsArray.count - 1
            mealSortedOrderArray = filteredMealsArray
            while(lastMealInt > -1)
            {
                let mealToCheck : Meal = filteredMealsArray[lastMealInt]
                do {
                    mealSortedOrderArray.remove(at: Int(mealToCheck.mealSortedOrder))
                    mealSortedOrderArray.insert(mealToCheck, at: Int(mealToCheck.mealSortedOrder))
                }
                lastMealInt -= 1
            }
            filteredMealsArray = mealSortedOrderArray
            mealSortedOrderArray = [Meal]()
        }
        print("Sorted meals.")
    }
    

    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "unwindToWeekMeals", sender: self)
    }
    
    
    // This method updates filteredData based on the text in the Search Box
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // When there is no text, filteredData is the same as the original data
        // When user has entered text into the search box
        // Use the filter method to iterate over all items in the data array
        // For each item, return true if the item should be included and false if the
        // item should NOT be included
        filteredMealsArray = searchText.isEmpty ? mealArray : mealArray.filter { (item: Meal) -> Bool in
            // If dataItem matches the searchText, return true to include it
            return item.mealName?.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        }
        
        tableView.reloadData()
    }
    
    
    //MARK: Pass in data on segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToWeekMeals" {
                print("Prepared for segue")
//                let indexPath = tableView.indexPathForSelectedRow
//            let destinationVC = TableViewController()
//                destinationVC.mealReplacing = mealToPassBack
//                destinationVC.mealToReplace = mealPassedIn
//                print("Passed meals back")
        } else if segue.identifier == "segueCancelToWeekMeals" {
//            let destinationVC = TableViewController()
//            destinationVC.mealToReplace.mealReplaceMe = false
            // do nothing
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





