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
let cloud = Storage()

class nouvelleUsers: ObservableObject {
  var rexes:[rex] = []
}

struct ContentView: View {
  @State var user: rex?
  @State var nouvelle = nouvelleUsers()
  @State var selected = 0
  @State var display1 = false
  @State var display2 = false
  @State var nickName = ""
  @State var secret = ""
  @State var showAlert1 = false
  
  var body: some View {
    VStack {
      // path as you start the app
      Text("WotsApp")
      .onTapGesture {
        if token != nil {
          cloud.searchPrivate(token)
        }
      }
      .onReceive(cloud.searchPriPublisher) { (data) in
        if data != nil {
          self.user = data
          cloud.getPublicDirectory()
        } else {
          self.display2 = true
        }
      }.onReceive(cloud.gotPublicDirectory) { (success) in
        if success! {
          self.nouvelle.rexes = cloud.users!.rexes
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.display1 = true
          }
        }
      }
      
      // path for a new user
      if display2 {
        TextField("NickName?", text: $nickName)
          .multilineTextAlignment(.center)
          .textFieldStyle(RoundedBorderTextFieldStyle())
        TextField("Secret?", text: $secret)
          .multilineTextAlignment(.center)
          .textFieldStyle(RoundedBorderTextFieldStyle())
        Button(action: {
          let success = crypto.generateKeyPair(keySize: 2048, privateTag: "ch.cqd.WotsApp", publicTag: "ch.cqd.WotsApp")
          if success {
            let privateK = crypto.getPrivateKey()
            let publicK = crypto.getPublicKey()
            let newRex = rex(id: nil, token: token, nickName: self.nickName, icon: nil, secret: self.secret, publicK: publicK, privateK: privateK)
            cloud.saveRex(user: newRex)
          }
        }) {
          Image(systemName: "icloud.and.arrow.up")
        }.onReceive(cloud.savedPublisher) { ( success ) in
          if success! {
            self.showAlert1 = true
            self.display1 = true
            self.display2 = false
          }
        }.alert(isPresented: $showAlert1) { () -> Alert in
          Alert(title: Text("Saved"), message: Text("Saved"), dismissButton: .default(Text("Ok")))
        }
      }
      
      
      // path for an existing user
      if self.display1 {
        Picker(selection: $selected, label: Text("")) {
          ForEach(0 ..< self.nouvelle.rexes.count) {dix in
            Text(self.nouvelle.rexes[dix].nickName!)
          }
        }.pickerStyle(WheelPickerStyle())
          .padding()
      }
    }
  }
}


//struct ContentView: View {
//  @State var messageTitle: String = ""
//  @State var messageBody: String = ""
//  var body: some View {
//    VStack {
//      Button(action: {
//        let messageNo = poster.saveMessage(message: self.messageBody, title: self.messageTitle)
//        poster.postNotification(type: "alert", jsonID: messageNo, token: token)
//      }) {
//        Text("post foreground")
//      }
//      Button(action: {
//        self.messageBody = crypto.encryptBase64(text: self.messageBody)
//      }) {
//        Text("encrypt")
//      }
//
//      TextField("Title?", text: $messageTitle)
//           .multilineTextAlignment(.center)
//           .textFieldStyle(RoundedBorderTextFieldStyle())
//
//      TextField("Body?", text: $messageBody, onCommit: {
//        let success = crypto.generateKeyPair(keySize: 2048, privateTag: "ch.cqd.WotsApp", publicTag: "ch.cqd.WotsApp")
//        if success {
//          let privateK = crypto.getPrivateKey()
//          let publicK = crypto.getPublicKey()
//          // code
//          let exportedPublicK = crypto.getPublicKey64()
//          crypto.putPublicKey64(publicK: exportedPublicK!, keySize: 2048, publicTag: "ch.cqd.WotsApp")
//          let exportedPrivateK = crypto.getPrivateKey64()
//          crypto.putPrivateKey64(privateK: exportedPrivateK!, keySize: 2048, privateTag: "ch.cqd.WotsApp")
//        }
//      })
//      .multilineTextAlignment(.center)
//      .textFieldStyle(RoundedBorderTextFieldStyle())
//
//      Button(action: {
//        self.messageBody = crypto.decpryptBase64(encrpted: self.messageBody)!
//      }) {
//        Text("decrypt")
//      }
//      Button(action: {
//        poster.postNotification(type: "background", jsonID: 1, token: token)
//      }) {
//        Text("post background")
//      }
//    }
//  }
//}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

extension Binding {
  func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
    return Binding(
      get: { self.wrappedValue },
      set: { selection in
        self.wrappedValue = selection
        handler(selection)
    })
  }
}
