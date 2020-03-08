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

  func application(_ application: UIApplication, your  launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    
    return true
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
  
  // code 11
  
  func application( _ application: UIApplication,
                 didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                 fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    debugPrint("Received: \(userInfo)")
    let device = userInfo["device"] as? String
    let request = userInfo["request"] as? String
    
    if request == "grant" {
      DispatchQueue.main.async {
        print("grant ",token)
        grantPublisher.send()
      }
    }
    
    if request == "later" {
      DispatchQueue.main.async {
        print("later ",token)
        laterPublisher.send()
      }
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
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
     print("reponse ",response.notification.request.content.subtitle)
     
     let action = response.actionIdentifier
     let request = response.notification.request
     let content = request.content.mutableCopy() as! UNMutableNotificationContent
     
     if action == "deny" {
       // Block the user/ignore
       completionHandler()
       return
     }
     
     if action == "accept" {
       print("content ",request.content.userInfo)
       let userInfo = request.content.userInfo["aps"]! as! Dictionary<String, Any>
       let device = userInfo["device"] as? String
       let messageID = poster.grantMessage(message: "grant", title: "grant")
       poster.postNotification(type: "alert", jsonID: messageID, token: device!)
    }
     if action == "later" {
         let userInfo = request.content.userInfo["aps"]! as! Dictionary<String, Any>
         let device = userInfo["device"] as? String
         let user = userInfo["user"] as? String
         let messageID = poster.laterMessage(message: "later", title: "later")
         poster.postNotification(type: "alert", jsonID: messageID, token: device!)
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

