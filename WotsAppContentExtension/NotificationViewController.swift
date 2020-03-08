//
//  NotificationViewController.swift
//  WotsAppContentExtension
//
//  Created by localadmin on 08.03.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    // code 1
    
    func didReceive(_ notification: UNNotification) {
        self.label?.text = "Can we talk"
    }

}
