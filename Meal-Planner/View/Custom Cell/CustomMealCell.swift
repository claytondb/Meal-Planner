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
    @IBOutlet weak var mealLockIconBtn: UIButton!
    @IBOutlet weak var mealSwapBtn: UIButton!
    
    var onLockTapped : (() -> Void)? = nil
    var onSwapTapped : (() -> Void)? = nil


    @IBAction func mealLockTapped(_ sender: UIButton) {
        if let onLockTapped = self.onLockTapped {
            onLockTapped()
        }
    }
    
    @IBAction func mealSwapTapped(_ sender: UIButton) {
        if let onSwapTapped = self.onSwapTapped {
            onSwapTapped()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code goes here
        
    }
    
}
