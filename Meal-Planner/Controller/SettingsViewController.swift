//
//  SettingsViewController.swift
//  Meal Planner
//
//  Created by Clayton, David on 3/28/18.
//  Copyright © 2018 Clayton, David. All rights reserved.
//

import UIKit
import Foundation
import CoreData

//@objc(SettingsViewController)  // match the ObjC symbol name inside Storyboard
class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var settingsArray = [Setting]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        
        self.tableView.backgroundColor = UIColor.white
        
        //TODO: Register your mealXib.xib file here:
        tableView.register(UINib(nibName: "mealXib", bundle: nil), forCellReuseIdentifier: "customMealCell")
        
        loadSettings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //MARK: Google analytics stuff
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.set(kGAIScreenName, value: "Settings view controller")
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
        //End google analytics stuff.
    }
    
    //MARK: Tableview datasource methods
    // Create the two datasource methods that specify 1. what the cells should display, and 2. how many rows we want in the tableview.
    // Method 1
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let settingsItem = settingsArray[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        
        cell.textLabel?.text = settingsItem.settingName
        
        return cell
    }
    
    
    // Method 2
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsArray.count
    }
    
    
    
    
    
    //MARK: Model manipulation methods
    func saveSettings(){
        do {
            try context.save()
        } catch {
            print("Error saving settings. \(error)")
        }
        self.tableView.reloadData()
        print("Settings saved and data reloaded")
    }
    
    func loadSettings(with request: NSFetchRequest<Setting> = Setting.fetchRequest()) {
        do {
            settingsArray = try context.fetch(request)
        } catch {
            print("Error loading meals. \(error)")
        }
        self.tableView.reloadData()
        print("Settings loaded")
    }
    
}




