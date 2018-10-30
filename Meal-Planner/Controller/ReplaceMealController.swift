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
    var ref : DatabaseReference!
    var user : User?
    var uid : String?
    var email : String?
    
    // Firebase Storage
    let storage = Storage.storage()
    var imagesFolderReference: StorageReference {
        return Storage.storage().reference().child("images")
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mealSearchField: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkCurrentUser()
        
        tableView.register(UINib(nibName: "mealXib", bundle: nil), forCellReuseIdentifier: "customMealCell")
        tableView.backgroundColor = UIColor.white
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.mealSearchField.delegate = self
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
        
        // Clear out filteredMealsArray and mealArray so we don't have duplicates
        filteredMealsArray = []
        mealArray = []
        
        checkCurrentUser()
        retrieveMealsFromFirebase()
        
        mealSearchField.text = ""
        searchBar(mealSearchField, textDidChange: "")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.register(UINib(nibName: "mealXib", bundle: nil), forCellReuseIdentifier: "customMealCell")
        
        sortMeals()
        tableView.reloadData()
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
        if meal.mealImagePath == nil {
            cell.mealImage.image = UIImage(named: "mealPlaceholder")
        } else if meal.mealImagePath == "" {
            cell.mealImage.image = UIImage(named: "mealPlaceholder")
        } else {
            // FirebaseUI method
            let imgReference = storage.reference().child("images/\(meal.mealImagePath!).jpg")
            print("Image reference is \(imgReference)")
            let thisImageView = cell.mealImage
            thisImageView?.sd_setImage(with: imgReference, placeholderImage: #imageLiteral(resourceName: "mealPlaceholder"))
            
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
        let count = filteredMealsArray.count
        return count
    }
    
    //MARK: Tableview delegate methods - select row and it will segue back to week view and pass in the selection.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mealToPassBack = filteredMealsArray[indexPath.row]
        print("mealToPassBack is \(mealToPassBack.mealName!)")
        
        swapSortingOrders()
        
        saveMealsToFirebase()
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
            mealArray = filteredMealsArray
            mealSortedOrderArray = [Meal]()
        }
        print("Sorted meals.")
    }
    
    //MARK: Load meals from Firebase database
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
                
                self.filteredMealsArray.append(mealFromFB)
                
                self.tableView.reloadData()
            }
        }
        else {
            print("User ID was nil.")
        }
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
    
    //MARK: Save to Firebase function
    func saveMealsToFirebase() {
        if uid != nil {
            self.ref = Database.database().reference().child("Meals").child(self.user!.uid)
            
            do {
                var lastMealInt : Int = mealArray.count - 1
                lastMealInt = mealArray.count - 1
                //                mealSortedOrderArray = mealArray
                while(lastMealInt > -1)
                {
                    let mealToCheck : Meal = mealArray[lastMealInt]
                    do {
                        // do stuff to that meal
                        // Create dictionary for that meal
                        let mealDictionary = ["MealOwner": Auth.auth().currentUser?.email ?? "",
                                              "MealName": mealToCheck.mealName!,
                                              "MealLocked": mealToCheck.mealLocked,
                                              "MealSortedOrder": mealToCheck.mealSortedOrder,
                                              "MealImagePath": mealToCheck.mealImagePath ?? "",
                                              "MealIsReplacing": mealToCheck.mealIsReplacing,
                                              "MealRecipeLink": mealToCheck.mealRecipeLink ?? "http://www.allrecipes.com",
                                              "MealReplaceMe": mealToCheck.mealReplaceMe,
                                              "MealFirebaseID": mealToCheck.mealFirebaseID!
                            ] as [String : Any]
                        
                        let mealFirebaseIDDataRef = mealToCheck.mealFirebaseID
                        
                        self.ref.child(mealFirebaseIDDataRef!).setValue(mealDictionary) {
                            (error, reference) in
                            if error != nil {
                                print(error!)
                            } else {
                                print("Meal saved successfully to Firebase")
                            }
                        }
                    }
                    lastMealInt -= 1
                }
                //                self.tableView.reloadData()
            }
        }
    }
    
    
}





