//
//  ContentView.swift
//  WotsApp
//
//  Created by localadmin on 29.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import SwiftUI
// code 6

let poster = RemoteNotifications()
let crypto = Crypto()

struct ContentView: View {
  @State var messageTitle: String = ""
  @State var messageBody: String = ""
  var body: some View {
    VStack {
      Button(action: {
        let messageNo = poster.saveMessage(message: self.messageBody, title: self.messageTitle)
        poster.postNotification(type: "alert", jsonID: messageNo, token: token)
      }) {
        Text("post foreground")
      }
      Button(action: {
        self.messageBody = crypto.encryptBase64(text: self.messageBody)
      }) {
        Text("encrypt")
      }
      
      TextField("Title?", text: $messageTitle)
           .multilineTextAlignment(.center)
           .textFieldStyle(RoundedBorderTextFieldStyle())
      
      TextField("Body?", text: $messageBody, onCommit: {
        let success = crypto.generateKeyPair(keySize: 2048, privateTag: "ch.cqd.WotsApp", publicTag: "ch.cqd.WotsApp")
        if success {
          let privateK = crypto.getPrivateKey()
          let publicK = crypto.getPublicKey()
          // code
          let exportedPublicK = crypto.getPublicKey64()
          crypto.putPublicKey64(publicK: exportedPublicK!, keySize: 2048, publicTag: "ch.cqd.WotsApp")
          let exportedPrivateK = crypto.getPrivateKey64()
          crypto.putPrivateKey64(privateK: exportedPrivateK!, keySize: 2048, privateTag: "ch.cqd.WotsApp")
        }
      })
      .multilineTextAlignment(.center)
      .textFieldStyle(RoundedBorderTextFieldStyle())
      
      Button(action: {
        self.messageBody = crypto.decpryptBase64(encrpted: self.messageBody)!
      }) {
        Text("decrypt")
      }
      Button(action: {
        poster.postNotification(type: "background", jsonID: 1, token: token)
      }) {
        Text("post background")
      }
    }
  }
}
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

