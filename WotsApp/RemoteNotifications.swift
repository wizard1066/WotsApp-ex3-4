//
//  RemoteNotifications.swift
//  WotsApp
//
//  Created by localadmin on 29.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import UIKit
import SwiftJWT

class RemoteNotifications: NSObject, URLSessionDelegate {
  // code 6
  private var privateKey = """
    -----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgsnn/44nhBKV+kw4f
    PYfN1IlrpBz1FgsCRG9evGKGTvigCgYIKoZIzj0DAQehRANCAATNJgIesi1GVma1
    f2CaxPL6RKRYCp5QZKBOmrDbtKyrHnF8buqg2Wgb03abbWNzGwQd+Xmylcrca9Iy
    eREihWzh
    -----END PRIVATE KEY-----
    """
//  private var token = "56f9fe2141d0ada7b38f4fea3b622c67f6cdee7df01deb2895f63a3ddd1f360b"
  
  private typealias jsonBlob = [String:Any]
  private var jsonObjects:[jsonBlob] = []
  
  
  override init () {
    jsonObjects.append(["aps":["badge":1,"category":"mycategory","alert":["title":"JSON What","body":"You must be kidding"]]])
    jsonObjects.append(["aps":["content-available":1],"request":"red"])
  }
  
  func saveMessage(message:String, title:String) -> Int {
    jsonObjects.append(["aps":["badge":1,"category":"mycategory","alert":["title":title,"body":message],"mutable-content":true]])
    return(jsonObjects.count - 1)
  }
  
  func requestMessage(message:String, title:String) -> Int {
    jsonObjects.append(["aps":["content-available":1,"category":"mycategory","alert":["title":title,"body":message]]])
    return(jsonObjects.count - 1)
  }
  
  func postNotification(type: String, jsonID: Int, token:String) {
    // code 9
    let valid = JSONSerialization.isValidJSONObject(jsonObjects[jsonID])
    print("valid ",valid)
    if !valid {
      return
    }
    let myHeader = Header(typ: "JWT", kid: "7AZZ3KJ6WD")
    let myClaims = ClaimsStandardJWT(iss: "CWGS87U262", sub: nil, aud: nil, exp: nil, nbf: nil, iat: Date() , jti: nil)
    let myJWT = JWT(header: myHeader, claims: myClaims)
    let privateKeyAsData = privateKey.data(using: .utf8)
    let signer = JWTSigner.es256(privateKey: privateKeyAsData!)
    let jwtEncoder = JWTEncoder(jwtSigner: signer)
    do {
      let jwtString = try jwtEncoder.encodeToString(myJWT)
    } catch {
      print("failed to encode")
    }
    // code 11
    do {
      let jwtString = try jwtEncoder.encodeToString(myJWT)
      let content = "https://api.sandbox.push.apple.com/3/device/" + token
      var loginRequest = URLRequest(url: URL(string: content)!)
      loginRequest.allHTTPHeaderFields = ["apns-topic": "ch.cqd.WotsApp",
                                          "content-type": "application/json",
                                          "apns-priority": "5",
                                          "apns-push-type": type,
                                          "authorization":"bearer " + jwtString]
      // code 12
      let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
      
      loginRequest.httpMethod = "POST"
      
      let data = try? JSONSerialization.data(withJSONObject: jsonObjects[jsonID], options:[])
      
      loginRequest.httpBody = data
      let loginTask = session.dataTask(with: loginRequest) { data, response, error in
        if error != nil {
          print("error ",error)
          return
        }
        let httpResponse = response as! HTTPURLResponse
        if httpResponse.statusCode != 400 {
          print("statusCode ",httpResponse.statusCode)
        }
      }
      loginTask.resume()
      print("apns ",jsonObjects[jsonID])
    } catch {
      print("failed to encode")
    }
  }
}



