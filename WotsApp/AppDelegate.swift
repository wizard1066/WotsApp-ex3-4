//
//  AppDelegate.swift
//  WotsApp
//
//  Created by localadmin on 29.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import UIKit
import Combine

var token: String!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    DispatchQueue.main.async {
      self.registerForNotifications()
      self.registerCategories()
    }
    return true
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    UserDefaults.standard.set(false, forKey: "enabled_preference")
  }

  func application(_ application: UIApplication, your  launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
    return true
  }
  
  @objc func defaultsChanged(){
    if UserDefaults.standard.bool(forKey: "enabled_preference") {
      UserDefaults.standard.set(false, forKey: "enabled_preference")
    } else {
      UserDefaults.standard.set(true, forKey: "enabled_preference")
    }
  }
  
  //code 5
  func application( _ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    token = tokenParts.joined()
    print("Device Token: \n\(token)\n")
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("failed error ",error)
  }
  
  // cdoe 5
  
  func application( _ application: UIApplication,
                 didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                 fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    debugPrint("Received: \(userInfo)")
    
    let info = userInfo["aps"] as? [String:Any]
    let device = info!["device"] as? String
    let request = info!["request"] as? String
    
    if request == "grant" {
      DispatchQueue.main.async {
        print("grant ",token)
//        alertPublisher.send(("grant","grant"))
          let secret = UserDefaults.standard.string(forKey: "secret")
        popUpPublisher.send(secret!)
      }
    }
    
    if request == "later" {
      DispatchQueue.main.async {
        print("later ",token)
        alertPublisher.send(("later","later"))
      }
    }
    
    if request == "deny" {
      print("later ",token)
      alertPublisher.send(("deny","deny"))
    }
    
    completionHandler(.newData)
  }

  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }


}

extension AppDelegate: UNUserNotificationCenterDelegate {
  
  // code 1
  func registerForNotifications() {
    let center  = UNUserNotificationCenter.current()
    center.delegate = self
    center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
      //          center.requestAuthorization(options: [.provisional]) { (granted, error) in
      if error == nil{
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      } else {
        print("error ",error)
      }
    }
  }
  
  // code 4
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
  completionHandler([.alert, .badge, .sound])
  }
  
  // code 4
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
     print("reponse ",response.notification.request.content.subtitle)
     
     let action = response.actionIdentifier
     let request = response.notification.request
     let content = request.content.mutableCopy() as! UNMutableNotificationContent
     
     if action == "accept" {
       print("content ",request.content.userInfo)
       let userInfo = request.content.userInfo["aps"]! as! Dictionary<String, Any>
       let device = userInfo["device"] as? String
       let messageID = poster.grantMessage(message: "grant", title: "grant")
       poster.postNotification(type: "background", jsonID: messageID, token: device!)
    }
     if action == "later" {
         let userInfo = request.content.userInfo["aps"]! as! Dictionary<String, Any>
         let device = userInfo["device"] as? String
         let user = userInfo["user"] as? String
         let messageID = poster.laterMessage(message: "later", title: "later")
         poster.postNotification(type: "background", jsonID: messageID, token: device!)
         UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
     }
     if action == "deny" {
         let userInfo = request.content.userInfo["aps"]! as! Dictionary<String, Any>
         let device = userInfo["device"] as? String
         let user = userInfo["user"] as? String
         let messageID = poster.laterMessage(message: "deny", title: "deny")
         poster.postNotification(type: "background", jsonID: messageID, token: device!)
         UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
     }
     
     completionHandler()
   }
   
   func registerCategories() {
     let acceptAction = UNNotificationAction(identifier: "accept", title: "Accept", options: [.foreground])
     let laterAction = UNNotificationAction(identifier: "later", title: "Later", options: [.foreground])
     let denyAction = UNNotificationAction(identifier: "deny", title: "Deny", options: [.destructive])
     let wotsappCategory = UNNotificationCategory(identifier: "wotsapp", actions: [acceptAction,laterAction,denyAction], intentIdentifiers: [], options: [])
   
     UNUserNotificationCenter.current().setNotificationCategories([wotsappCategory])
   }
}

