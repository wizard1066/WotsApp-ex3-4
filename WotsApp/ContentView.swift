//
//  ContentView.swift
//  WotsApp
//
//  Created by localadmin on 29.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import SwiftUI
import Combine

// code 3

let alertPublisher = PassthroughSubject<(String, String), Never>()
let popUpPublisher = PassthroughSubject<String, Never>()
let cestBonPublisher = PassthroughSubject<Void, Never>()

let poster = RemoteNotifications()
let crypto = Crypto()
let cloud = Storage()
//let images = ["mouse","bull","tiger","rabit","dragon","snake","horse","ram","monkey","roster","dog","bull"]
let images = ["mac1","mac2","mac3","mac4","mac5","mac6"]
let testToken = "3b20b37223f18e562def0e262d2ecde1e79d3cd3a6dc945e08253523af026a21"

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
  @State var showAlert2 = false
  @State var index = 0
  @State var image = UIImage(imageLiteralResourceName: "tiny")
  @State var message = ""
  
  @State var sendTo = ""
  @State var address = ""
  @State var publicK:Data!
  @State var privateK:Data!
  
  @State var display3 = false
  @State var showAlert = false
  @State var selected2 = 0
  @State var title = ""
  @State var alertMessage = ""
  @State var disableText = false
  
  @State var nextState = false
  
  @State var doubleToken:String!

  
  
  var body: some View {
    VStack(alignment: .center) {
      // path as you start the app
      Text("WotsApp")
      .onTapGesture {
        if token != nil {
          print("ok")
          cloud.searchPrivate(token)
        } else {
          print("no registration")
        }
      }.onReceive(alertPublisher, perform: { (content ) in
        (self.title,self.alertMessage) = content
        self.showAlert = true
        self.disableText = true
      }).alert(isPresented:$showAlert) {
        Alert(title: Text(self.title), message: Text(self.alertMessage), dismissButton: .default(Text("Ok")))
      }.onReceive(cestBonPublisher, perform: { (_) in
        self.disableText = false
        cloud.updateRex()
      })
      .onReceive(cloud.searchPriPublisher) { (data) in
        if data != nil  {
          self.user = data!
          self.image = UIImage(data: self.user!.image!)!
          self.nickName = self.user!.nickName!
          self.secret = self.user!.secret!
          self.privateK = self.user!.privateK!
          self.publicK = self.user!.publicK!
          crypto.putPublicKey(publicK: self.publicK, keySize: 2048, publicTag: "ch.cqd.WotsApp")
          crypto.putPrivateKey(privateK: self.privateK, keySize: 2048, privateTag: "ch.cqd.WotsApp")
          crypto.savePrivateKey()
          UserDefaults.standard.set(self.secret, forKey: "secret")
          cloud.getPublicDirectory()
        } else {
//          cloud.getPublicDirectory()
          self.display2 = true
        }
      }.onReceive(cloud.gotPublicDirectory) { (success) in
        if success! {
          self.nouvelle.rexes = cloud.users!.rexes
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.display1 = true
          }
        }
      }.onReceive(cloud.searchPri2Publisher) { (data) in
        self.nouvelle.rexes = data!
        self.display3 = true
      }.onAppear {
        let network = Connect.shared
        network.startMonitoring()
        network.netStatusChangeHandler = netMonitoring
        network.didStartMonitoringHandler = netMonitoringStarted
        network.didStopMonitoringHandler = netMonitoringStopped
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
          if !network.isConnected {
            self.alertMessage = "Sorry, no network, no work!"
            self.title = "STOP"
            self.showAlert = true
          }
        }
      }
      
      
      // code for multiple owners one device
      if display3 {
        Spacer()
        Picker(selection: $selected2, label: Text("")) {
          ForEach(0 ..< self.nouvelle.rexes.count) {dix in
            Text(self.nouvelle.rexes[dix].nickName!)
          }
        }.pickerStyle(WheelPickerStyle())
          .padding()
          .onTapGesture {
            cloud.searchPriPublisher.send(self.nouvelle.rexes[self.selected2])
            self.display3 = false
          }
      }
      
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
            self.privateK = crypto.getPrivateKey()
            self.publicK = crypto.getPublicKey()
            self.image = UIImage(named: images[self.index])!
            let imagePNG = self.image.pngData()!
            let newRex = rex(id: nil, token: token, nickName: self.nickName, image: imagePNG, secret: self.secret, publicK: self.publicK, privateK: self.privateK)
            // fuck
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
        }.onAppear(perform: {
          cloud.cloudStatus()
        })
        .onReceive(cloud.cloudPublisher) { ( message ) in
          self.alertMessage = message
          self.title = "iCloud"
          self.showAlert = true
        }
        Spacer()
      }
      
      // path for an existing user
      if self.display1 {
        Text(secret)
        Image(uiImage: image)
          .resizable()
          .frame(width: 128.0, height: 128.0)
        Text("Sender: " + nickName)
        Text("Sending: " + sendTo)
        // code 3
        TextField("Message?", text: $message, onCommit: {
          crypto.putPublicKey(publicK: self.publicK, keySize: 2048, publicTag: "ch.cqd.WotsApp")
          let crypted = crypto.encryptBase64(text: self.message)
          let index = poster.saveMessage(message: crypted, title: self.nickName)
          poster.postNotification(type: "alert", jsonID: index, token: self.address)
        })
        .disabled(disableText)
        .textFieldStyle(RoundedBorderTextFieldStyle())

        Spacer()
        Picker(selection: $selected, label: Text("")) {
          ForEach(0 ..< self.nouvelle.rexes.count) {dix in
            Text(self.nouvelle.rexes[dix].nickName!)
          }
        }.pickerStyle(WheelPickerStyle())
          .padding()
          .onTapGesture {
            self.sendTo = self.nouvelle.rexes[self.selected].nickName!
            self.address = self.nouvelle.rexes[self.selected].token!
            self.publicK = self.nouvelle.rexes[self.selected].publicK
            self.privateK = self.nouvelle.rexes[self.selected].privateK
            self.doubleToken = self.nouvelle.rexes[self.selected].token
            
            cloud.authRequest(auth: "request", name: self.sendTo, device: self.address)
        }.onReceive(popUpPublisher, perform: { ( code ) in
          self.disableText = true
          self.secret = code
          let alertHC = UIHostingController(rootView: PopUp(code: self.$secret, input: ""))
          alertHC.preferredContentSize = CGSize(width: 256, height: 256)
          alertHC.modalPresentationStyle = .formSheet
          
          UIApplication.shared.windows[0].rootViewController?.present(alertHC, animated: true)
        })
        .alert(isPresented:$showAlert2) {
          Alert(title: Text("New User"), message: Text("Saved"), dismissButton: .default(Text("Ok")))
        }
      }
    }
  }
}



#if DEBUG
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
#endif

// code 7

struct PopUp : View {
  @Binding var code: String
  @State var input: String
  @State var status: String = ""
  
  var body : some View {
    VStack {
      Text("and the Code is ...")
      Text("\(self.code)")
      TextField("Code?", text: $input, onEditingChanged: { (editing) in
        if editing {
          self.input = ""
        }
      }, onCommit: {
        if self.code == self.input {
          UIApplication.shared.windows[0].rootViewController?.dismiss(animated: true, completion: {
            cestBonPublisher.send()
          })
        } else {
          self.status = "Sorry Code Incorrect"
        }
      }).frame(width: 128, height: 128, alignment: .center)
      Button(action: {
        UIApplication.shared.windows[0].rootViewController?.dismiss(animated: true, completion: {})
      }) {
        Text("Cancel")
      }
      Button(action: {
        UIApplication.shared.windows[0].rootViewController?.dismiss(animated: true, completion: {})
      }) {
        Text("OK")
      }
      Text(status)
    }
  }
}

func netMonitoring() {
  print("network monitored")
}

func netMonitoringStarted() {
  print("Started monitoring")
}

func netMonitoringStopped() {
  print("Stopped monitoring")
}


func fakeAccounts() {
    let sPrivateKey = crypto.getPrivateKey()
    let sPublicK = crypto.getPublicKey()
    // Star Wars Charater List
    let users = ["Luke","HanSolo","Leia","Rey","Yoda","Obi-Wan","Poe","Qui-Gon","Rose"]
    var index = 0
    for user in users {
      let success = crypto.generateKeyPair(keySize: 2048, privateTag: "ch.cqd.WotsApp", publicTag: "ch.cqd.WotsApp")
      if success {
        let privateK = crypto.getPrivateKey()
        let publicK = crypto.getPublicKey()
        let image = UIImage(named: images[index])!
        let imagePNG = image.pngData()!
        index = index + 1
        let newRex = rex(id: nil, token: token, nickName: user, image: imagePNG, secret: "r2d2", publicK: publicK, privateK: privateK)
        cloud.users!.rexes.append(newRex)
        cloud.saveRex(user: newRex)
      }
      
    }
    crypto.putPublicKey(publicK: sPublicK!, keySize: 2048, publicTag: "ch.cqd.WotsApp")
    crypto.putPrivateKey(privateK: sPrivateKey!, keySize: 2048, privateTag: "ch.cqd.WotsApp")
}


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
