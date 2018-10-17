//
//  UserDefaults.swift
//  Pico
//
//  Created by Frank Cheng on 2018/10/17.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

enum UserDefaultKeys : String {
    case shownOnboarding =  "shownOnboarding"
    case rearrangeSelection = "rearrangeSelection"
    
    static func setupUserDefaults() {
        if UserDefaults.standard.object(forKey: UserDefaultKeys.rearrangeSelection.rawValue) == nil {
            UserDefaults.standard.set(true, forKey: UserDefaultKeys.rearrangeSelection.rawValue)
        }
    }
}

