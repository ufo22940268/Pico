//
//  Storyboards.swift
//  Pico
//
//  Created by Frank Cheng on 2018/9/27.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit


enum Storyboards : String {
 
    case Onboarding = "Onboarding"
    case Main = "Main"
    
    var instance: UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: nil)
    }
}

