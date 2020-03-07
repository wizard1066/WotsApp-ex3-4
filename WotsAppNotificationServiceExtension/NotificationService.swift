//
//  NotificationService.swift
//  WotsAppNotificationServiceExtension
//
//  Created by localadmin on 03.03.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    private var privateKey : SecKey?

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            
  // code 16
            let defaults = UserDefaults.init(suiteName: "group.ch.cqd.WotsApp")
            let localK = defaults?.object(forKey: "privateK") as? String
          
            putPrivateKey64(privateK: localK!, keySize: 2048, privateTag: "ch.cqd.WotsApp")
            
            bestAttemptContent.title = "\(bestAttemptContent.title) [encrypted]"
            bestAttemptContent.body = decpryptBase64(encrpted: bestAttemptContent.body)!
            contentHandler(bestAttemptContent)
        }
    }
    
    func putPrivateKey64(privateK:String, keySize: UInt, privateTag: String) {
      let secKeyData : NSData = NSData(base64Encoded: privateK, options: .ignoreUnknownCharacters)!
      putPrivateKey(privateK: secKeyData as Data, keySize: keySize, privateTag: privateTag)
    }
    
    func putPrivateKey(privateK:Data, keySize: UInt, privateTag: String) {
    //    let secKeyData : NSData = NSData(base64Encoded: publicK, options: .ignoreUnknownCharacters)!
        let attributes: [String:Any] = [
                    kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
                    kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                    kSecAttrKeySizeInBits as String: keySize,
                    kSecAttrIsPermanent as String: true as AnyObject,
                    kSecAttrApplicationTag as String: privateTag as AnyObject
                    ]
        self.privateKey = SecKeyCreateWithData(privateK as CFData, attributes as CFDictionary, nil)
        print("putprivatekey ",self.privateKey)
      }
  
 
    func decpryptBase64(encrpted: String) -> String? {
       
       let data : NSData = NSData(base64Encoded: encrpted, options: .ignoreUnknownCharacters)!
       let count = data.length / MemoryLayout<UInt8>.size
       var array = [UInt8](repeating: 0, count: count)
       data.getBytes(&array, length:count * MemoryLayout<UInt8>.size)
       
       var plaintextBufferSize = Int(SecKeyGetBlockSize((self.privateKey)!))
       var plaintextBuffer = [UInt8](repeating:0, count:Int(plaintextBufferSize))
       
       let status = SecKeyDecrypt((self.privateKey)!, SecPadding.PKCS1, array, plaintextBufferSize, &plaintextBuffer, &plaintextBufferSize)
       
       if (status != errSecSuccess) {
         print("Failed Decrypt")
         return nil
       }
       return NSString(bytes: &plaintextBuffer, length: plaintextBufferSize, encoding: String.Encoding.utf8.rawValue)! as String
     }

    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
