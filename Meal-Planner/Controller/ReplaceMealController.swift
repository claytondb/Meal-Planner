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
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

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
    var handle : Any?
//    var ref : DatabaseReference!
//    let userID = Auth.auth().currentUser?.uid
    
    //    // Firebase Storage
    //    let storage = Storage.storage()
    //    var imageReference: StorageReference {
    //        return Storage.storage().reference().child("images")
    //    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mealSearchField: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadMeals()
        sortMeals()
        
        tableView.register(UINib(nibName: "mealXib", bundle: nil), forCellReuseIdentifier: "customMealCell")
        print("Loaded custom mealXib")
        
        tableView.backgroundColor = UIColor.white
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.mealSearchField.delegate = self
        filteredMealsArray = mealArray
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //MARK: Google analytics stuff
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.set(kGAIScreenName, value: "Replace Meal view controller")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
        //End google analytics stuff.
        
        //Firebase auth
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            print("Added auth state change listener.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //Firebase auth. Added "as! AuthStateDidChangeListenerHandle" because var handle is of type 'Any?'.
        Auth.auth().removeStateDidChangeListener(handle! as! AuthStateDidChangeListenerHandle)
        print("Removed auth state change listener.")
    }
    
    //MARK: Tableview datasource methods
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
        
        return cell
    }
    
    // Method 2
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = filteredMealsArray.count
        return count
    }
    
    //MARK: Tableview delegate methods - select row and it will segue back to week view and pass in the selection.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mealToPassBack = filteredMealsArray[indexPath.row]
        print("mealToPassBack is \(mealToPassBack.mealName!)")
        
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
            // do nothing
        } else if segue.identifier == "segueCancelToWeekMeals" {
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





