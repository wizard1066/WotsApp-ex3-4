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
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgFJ6qOEwGZxp1xJLA
    WVQn3eg+zFXIJ6dLVRefI6bpiQagCgYIKoZIzj0DAQehRANCAASqAfPb9jA+h3Kp
    pd5ZC7ydB78t1MsX7rQw0xX0MUrWUOAeO5c7S3INa/tbXxdhtF8hgG0KydvGGjdo
    Q1hW/WrX
    -----END PRIVATE KEY-----
    """
  private var token = "56f9fe2141d0ada7b38f4fea3b622c67f6cdee7df01deb2895f63a3ddd1f360b"
  
  private var jsonObject: [String: Any] = ["aps":["badge":2,"category":"mycategory","alert":["title":"JSON What","body":"You must be kidding"]]]
  
  func postNotification() {
    // code 9
    let valid = JSONSerialization.isValidJSONObject(jsonObject)
    print("valid ",valid)
    if !valid {
      return
    }
    let myHeader = Header(typ: "JWT", kid: "63A6PR238W")
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
                                          "apns-priority": "10",
                                          "apns-push-type": "alert",
                                          "authorization":"bearer " + jwtString]
      // code 12
      let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
      
      loginRequest.httpMethod = "POST"
      
      let data = try? JSONSerialization.data(withJSONObject: jsonObject, options:[])
      
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
      print("apns ",jsonObject)
    } catch {
      print("failed to encode")
    }
  }
}


