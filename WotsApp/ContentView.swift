//
//  ContentView.swift
//  WotsApp
//
//  Created by localadmin on 29.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import SwiftUI
// code 7

let poster = RemoteNotifications()
let crypto = Crypto()
let cloud = Storage()
let images = ["mouse","bull","tiger","rabit","dragon","snake","horse","ram","monkey","roster","dog","bull"]

class nouvelleUsers: ObservableObject {
  var rexes:[rex] = []
}

// code 8

struct ContentView: View {
  @State var user: rex?
  @State var nouvelle = nouvelleUsers()
  @State var selected = 0
  @State var display1 = false
  @State var display2 = false
  @State var nickName = ""
  @State var secret = ""
  @State var showAlert2 = false
  @State var index = 0
  @State var image = UIImage(imageLiteralResourceName: "dog")
  @State var message = ""
  
  // code 9
  
  var body: some View {
    VStack(alignment: .center) {
      // path as you start the app
      Text("WotsApp")
      .onTapGesture {
        if token != nil {
          cloud.searchPrivate(token)
        }
      }
      .onReceive(cloud.searchPriPublisher) { (data) in
        if data != nil {
          self.user = data!
          self.image = UIImage(data: self.user!.image!)!
          self.nickName = self.user!.nickName!
          self.secret = self.user!.secret!
          crypto.putPublicKey(publicK: self.user!.publicK!, keySize: 2048, publicTag: "ch.cqd.WotsApp")
          crypto.putPrivateKey(privateK: self.user!.privateK!, keySize: 2048, privateTag: "ch.cqd.WotsApp")
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
      
      // code 10
      // path for a new user
      if display2 {
        Spacer()
        
        TextField("NickName?", text: $nickName)
          .multilineTextAlignment(.center)
          .textFieldStyle(RoundedBorderTextFieldStyle())
        TextField("Secret?", text: $secret)
          .multilineTextAlignment(.center)
          .textFieldStyle(RoundedBorderTextFieldStyle())
        Image(images[index])
          .resizable()
          .frame(width: 128.0, height: 128.0)
          .onTapGesture {
          self.index = (self.index + 1) % images.count
        }.animation(.default)
        Text("Tap image to change it").font(.system(size: 12))
        Spacer()
        Spacer()
        Button(action: {
          let success = crypto.generateKeyPair(keySize: 2048, privateTag: "ch.cqd.WotsApp", publicTag: "ch.cqd.WotsApp")
          if success {
            let privateK = crypto.getPrivateKey()
            let publicK = crypto.getPublicKey()
            self.image = UIImage(named: images[self.index])!
            let imagePNG = self.image.pngData()!
            let newRex = rex(id: nil, token: token, nickName: self.nickName, image: imagePNG, secret: self.secret, publicK: publicK, privateK: privateK)
            
            cloud.saveRex(user: newRex)
          }
        }) {
          Image(systemName: "icloud.and.arrow.up")
          .resizable()
          .frame(width: 48.0, height: 48.0)
        }.onReceive(cloud.savedPublisher) { ( success ) in
          if success! {
            self.showAlert2 = true
            self.display2 = false
            self.display1 = true
          }
        }
        Spacer()
      }
      
      // code 11
      // path for an existing user
      if self.display1 {
        Text(nickName)
        Image(uiImage: image)
          .resizable()
          .frame(width: 128.0, height: 128.0)
        Text(secret)
        TextField("Message?", text: $message)
        .multilineTextAlignment(.center)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        Spacer()
        Picker(selection: $selected, label: Text("")) {
          ForEach(0 ..< self.nouvelle.rexes.count) {dix in
            Text(self.nouvelle.rexes[dix].nickName!)
          }
        }.pickerStyle(WheelPickerStyle())
          .padding()
          .alert(isPresented:$showAlert2) {
            Alert(title: Text("New User"), message: Text("Saved"), dismissButton: .default(Text("Ok")))
          }
          
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
#if DEBUG
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
#endif


//extension Binding {
//  func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
//    return Binding(
//      get: { self.wrappedValue },
//      set: { selection in
//        self.wrappedValue = selection
//        handler(selection)
//    })
//  }
//}
