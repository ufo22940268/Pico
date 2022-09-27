//
//  OnboardingViewController.swift
//  Pico
//
//  Created by Frank Cheng on 2018/9/27.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class OnboardingViewController: UIViewController {
    
    @IBAction func onNext(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.shownOnboarding.rawValue)
        let initVC = Storyboards.Main.instance.instantiateInitialViewController()!
        present(initVC, animated: true, completion: nil)
    }
    
}
