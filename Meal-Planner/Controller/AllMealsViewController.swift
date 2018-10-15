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
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class AllMealsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    var mealArray = [Meal]()
    var mealSortedOrderArray = [Meal]()
    var filteredMealsArray = [Meal]()
    let meal = Meal()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var handle : Any?
    var ref : DatabaseReference!
    var user : User?
    var uid : String?
    var email : String?
    
    //    // Firebase Storage
    //    let storage = Storage.storage()
    //    var imageReference: StorageReference {
    //        return Storage.storage().reference().child("images")
    //    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mealSearchField: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        checkCurrentUser()
        
        tableView.register(UINib(nibName: "mealXib", bundle: nil), forCellReuseIdentifier: "customMealCell")
        tableView.backgroundColor = UIColor.white
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.mealSearchField.delegate = self
        
        filteredMealsArray = mealArray
        sortMeals()
        
//        print("On load, the number of meals in filteredMealsArray is \(filteredMealsArray.count)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //MARK: Google analytics stuff
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.set(kGAIScreenName, value: "All Meals view controller")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
        //End google analytics stuff.
        
        //Firebase auth
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            print("Added auth state change listener.")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkCurrentUser()
        
        // Clear out filteredMealsArray and mealArray so we don't have duplicates
        filteredMealsArray = []
        mealArray = []
        
        retrieveMealsFromFirebase()

        tableView.register(UINib(nibName: "mealXib", bundle: nil), forCellReuseIdentifier: "customMealCell")
        
        mealSearchField.text = ""
        searchBar(mealSearchField, textDidChange: "")
        
        filteredMealsArray = mealArray
        
        sortMeals() // Something on this one gets the "index out of range" error.
        
        print("After viewDidAppear, the number of meals in filteredMealsArray is \(filteredMealsArray.count)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //Firebase auth. Added "as! AuthStateDidChangeListenerHandle" because var handle is of type 'Any?'.
        Auth.auth().removeStateDidChangeListener(handle! as! AuthStateDidChangeListenerHandle)
        print("Removed auth state change listener.")
    }
    
    func checkCurrentUser() {
        if Auth.auth().currentUser != nil {
            self.user = Auth.auth().currentUser
            if let thisUser = user {
                uid = thisUser.uid
                email = thisUser.email
                print("\(uid!) is signed in and their email is \(email!).")
            }
        } else {
            print("Nobody is signed in.")
        }
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
        
        if meal.mealImagePath == "" {
            meal.mealImagePath = nil
        }
        
        // Set meal image
        if meal.mealImagePath != nil {
            let mealImageURL = URL(string: (meal.mealImagePath?.encodeUrl())!)
            if let imageData = try? Data(contentsOf: mealImageURL!) {
                cell.mealImage.contentMode = .scaleAspectFill // not doing anything
                cell.mealImage.image = UIImage(data: imageData)
            } else {
                cell.mealImage.contentMode = .scaleAspectFill //  not doing anything
                cell.mealImage.image = UIImage(named: "mealPlaceholder")
            }
        } else {
            cell.mealImage.contentMode = .scaleAspectFill //  not doing anything
            cell.mealImage.image = UIImage(named: "mealPlaceholder")
        }
        
        if cell.mealDay != nil {
            cell.mealDay.removeFromSuperview()
        }
        
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
        print("For numberOfRowsInSection function, the number of meals in filteredMealsArray is \(filteredMealsArray.count)")
        let count = filteredMealsArray.count
//        let count = mealArray.count
        return count
    }
    
    
    // Override to support editing the table view. Swipe to delete.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            let mealToDelete = self.filteredMealsArray[indexPath.row]
            
            // Use index of row to delete it from table and CoreData
            //            self.context.delete(mealToDelete)
            
            //TODO: Remove meal entry from firebase database
            ref = Database.database().reference()
            func remove(child: String) {
                
                // Test to delete Apollo 13 meal
                let ref = self.ref.child("Meals").child("-LH3FD-q_R9p6OZobfAc")
                
                ref.removeValue { error, _ in
                    
                    print(error ?? "Error removing meal.")
                }
            }
            
            self.filteredMealsArray.remove(at: indexPath.row)
            print("Successfully deleted meal.")
            
            mealArray = filteredMealsArray
            
            // Save data and reload
            //TODO: Save to firebase and reload
//            self.saveMeals()
            
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        print("can move rows")
        return true
    }
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        let itemToMove = filteredMealsArray[fromIndexPath.row]
        filteredMealsArray.remove(at: fromIndexPath.row)
        filteredMealsArray.insert(itemToMove, at: toIndexPath.row)
        mealArray = filteredMealsArray
        
        //TODO: Save to firebase
//        saveMeals()
    }
    @IBAction func startEditing(_ sender: UIBarButtonItem) {
        if self.isEditing == false {
            setEditing(true, animated: true)
        } else {
            setEditing(false, animated: true)
        }
    }
    
    // This method updates filteredData based on the text in the Search Box
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredMealsArray = searchText.isEmpty ? mealArray : mealArray.filter { (item: Meal) -> Bool in
            // If dataItem matches the searchText, return true to include it
            return item.mealName?.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        }
        tableView.reloadData()
    }
    
    //MARK: Function to sort tableview according to mealSortedIndex
    func sortMeals() {
        do {
            print("sortMeals: filteredMealsArray.count is \(filteredMealsArray.count)")
            var lastMealInt : Int = filteredMealsArray.count - 1 // because 0 counts as the first meal.
            mealSortedOrderArray = filteredMealsArray
            while(lastMealInt > -1)
            {
                let mealToCheck : Meal = filteredMealsArray[lastMealInt]
                do {
                    mealSortedOrderArray.remove(at: Int(mealToCheck.mealSortedOrder))
                    mealSortedOrderArray.insert(mealToCheck, at: Int(mealToCheck.mealSortedOrder))
                }
                lastMealInt -= 1
            } // ERROR: Index out of range was being caused by meals that were added with errors. They had the meal sorted order messed up. This is no longer an issue after deleting all meals from Firebase and re-adding them.
            print("No errors while sorting meals.")
            filteredMealsArray = mealSortedOrderArray
            mealSortedOrderArray = [Meal]()
        }
        print("Sorted meals.")
    }
    
    
    //MARK: Tableview delegate methods - select row, segue to meal detail
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
            newMeal.mealLocked = false
            newMeal.mealSortedOrder = Int32(self.mealArray.count)
            
            self.ref = Database.database().reference().child("Meals").child(self.user!.uid) // Does it know there's a user? This crashes the app if nobody is logged in. Currently preventing that by requiring users to be logged in.
            
            let mealFirebaseID = self.ref.childByAutoId() // App crashes if nobody logged in.
            // ref is the variable for DatabaseReference, which has a !
            // It doesn't know what the DatabaseReference is if nobody is logged in.
            
            newMeal.mealFirebaseID = "\(mealFirebaseID)"
            
            // Create dictionary for firebase
            let mealDictionary = ["MealOwner": Auth.auth().currentUser?.email ?? "",
                                  "MealName": newMeal.mealName!,
                                  "MealLocked": newMeal.mealLocked,
                                  "MealSortedOrder": newMeal.mealSortedOrder,
                                  "MealImagePath": newMeal.mealImagePath ?? "",
                                  "MealIsReplacing": newMeal.mealIsReplacing,
                                  "MealRecipeLink": newMeal.mealRecipeLink ?? "http://www.allrecipes.com",
                                  "MealReplaceMe": newMeal.mealReplaceMe,
                                  "MealFirebaseID": mealFirebaseID.key
                                  ] as [String : Any]
            
            
            //Saving new meal to Firebase database
            
            mealFirebaseID.setValue(mealDictionary) {
                (error, reference) in
                if error != nil {
                    print(error!)
                } else {
                    print("Meal saved successfully to Firebase")
                }
            }
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
    
    // Load meals from Firebase database
    // This was causing the app to crash, but I added a var 'ref : DatabaseReference!' to the beginning of the controller.
    func retrieveMealsFromFirebase() {
        if uid != nil {
            ref = Database.database().reference().child("Meals").child(user!.uid)
            ref.observe(.childAdded) { (snapshot : DataSnapshot) in
                let snapshotValue = snapshot.value as! Dictionary<String, Any>
                let mealFromFB = Meal(context: self.context)
                
                mealFromFB.mealImagePath = snapshotValue["MealImagePath"] as? String
                mealFromFB.mealIsReplacing = snapshotValue["MealIsReplacing"] as! Bool
                mealFromFB.mealLocked = snapshotValue["MealLocked"] as! Bool
                mealFromFB.mealName = snapshotValue["MealName"] as? String
                mealFromFB.mealOwner = snapshotValue["MealOwner"] as? String
                mealFromFB.mealRecipeLink = snapshotValue["MealRecipeLink"] as? String
                mealFromFB.mealReplaceMe = snapshotValue["MealReplaceMe"] as! Bool
                mealFromFB.mealSortedOrder = snapshotValue["MealSortedOrder"] as! Int32
                mealFromFB.mealFirebaseID = snapshotValue["MealFirebaseID"] as? String
                
                self.mealArray.append(mealFromFB)
                self.filteredMealsArray = self.mealArray
                
                self.tableView.reloadData()
                print("After retrieveMealsFromFirebase, the number of meals in filtereMealsArray is \(self.filteredMealsArray.count)")
            }
        }
        else {
            print("User ID was nil.")
        }
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
            //TODO: Delete from firebase
            self.context.delete(mealToDelete)
            self.mealArray.remove(at: indexPath!.row)
            print("Successfully deleted meal.")
            
            // Save data and reload
            //TODO: Save to firebase
//            self.saveMeals()
            
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
                destinationVC.cameFromWeekMeals = false
                destinationVC.cameFromAllMeals = true
                print("Prepared for segue")
                let indexPath = tableView.indexPathForSelectedRow
                destinationVC.mealPassedIn = filteredMealsArray[(indexPath?.row)!]
                print("Passed in meal")
                
            }
        }
    }
    
    @IBAction func unwindToAllMeals(segue: UIStoryboardSegue) {
        // nothing here but I think I need this.
    }
    
    
    //MARK: Model manipulation methods
//    func saveMeals(){
//        do {
//            try context.save()
//        } catch {
//            print("Error saving meals. \(error)")
//        }
//        self.tableView.reloadData()
//        print("Meals saved and data reloaded")
//    }
    
//    func loadMeals(with request: NSFetchRequest<Meal> = Meal.fetchRequest()) {
//        do {
//            mealArray = try context.fetch(request)
//        } catch {
//            print("Error loading meals. \(error)")
//        }
//        self.tableView.reloadData()
//        print("Meals loaded")
//    }
    
}




