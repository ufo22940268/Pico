//
//  SettingViewController.swift
//  Pico
//
//  Created by Frank Cheng on 2018/10/7.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class SettingViewController: UITableViewController {

    let emailIndex = IndexPath(row: 0, section: 1)
    let appstoreIndex = IndexPath(row: 1, section: 1)
    let weiboIndex = IndexPath(row: 2, section: 1)

    let rearrangeIndex = IndexPath(row: 0, section: 0)
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var rearrangeSelectionCell: UITableViewCell!
    
    override func viewDidLoad() {
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        versionLabel.text = "\(versionNumber) Build \(buildNumber)"
        
        let rearrangeSwitchView = UISwitch()
        rearrangeSwitchView.isOn = UserDefaults.standard.bool(forKey: UserDefaultKeys.rearrangeSelection.rawValue)
        rearrangeSelectionCell.accessoryView = rearrangeSwitchView
        rearrangeSwitchView.addTarget(self, action: #selector(onRearrangeSwitcherChanges(sender:)), for: .valueChanged)
    }
    
    
    @objc func onRearrangeSwitcherChanges(sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: UserDefaultKeys.rearrangeSelection.rawValue)
    }
    
    fileprivate func open(url: String) {
        let weiboUrl = URL(string: url)!
        if UIApplication.shared.canOpenURL(weiboUrl) {
            UIApplication.shared.open(weiboUrl, options: [:], completionHandler: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case emailIndex:
            let emailVC = MFMailComposeViewController()
            emailVC.mailComposeDelegate = self
            emailVC.setToRecipients(["ufo22940268@gmail.com"])
            present(emailVC, animated: true, completion: nil)
            break
        case appstoreIndex:
            open(url: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=1409391165")
        case weiboIndex:
            open(url: "sinaweibo://userinfo?uid=1064211884")
        default:
            break
        }
    }
}

extension SettingViewController : MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}
