//
//  CustomMealCell.swift
//  Meal Planner
//
//  Created by Clayton, David on 3/19/18.
//  Copyright © 2018 Clayton, David. All rights reserved.
//

import UIKit

class CustomMealCell: UITableViewCell {
    
    @IBOutlet weak var mealImage: UIImageView!
    @IBOutlet weak var mealLabel: UILabel!
    @IBOutlet weak var mealDay: UILabel!
    
    var onLockTapped : (() -> Void)? = nil


    @IBAction func mealLockTapped(_ sender: UIButton) {
        if let onLockTapped = self.onLockTapped {
            onLockTapped()
        }
    }
    //this has to be an outlet to access it in TableViewController
//    @IBOutlet weak var lockButtonOutlet: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code goes here
        
        
        
        
    }
    
    
}
