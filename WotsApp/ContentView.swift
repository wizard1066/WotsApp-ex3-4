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
  @State var alpha: Double = 65
  @State var alphaToShow: String = "A"
  @State var display4 = true
  @State var showConfirm = false
  @State var privateLink = ""
  @State var publicLink = ""
  
  @State var group = ""
  @State var showPopover = false
  @State var recipients:[tags] = []
  @State var code:String = ""
  
  
  
  var body: some View {
    VStack(alignment: .center) {
      // path as you start the app
      Text("WotsApp")
      .onTapGesture {
        if token != nil {
          print("ok")
          cloud.showBlocked()
          cloud.searchPrivate(token)
//          fakeAccounts()
//          crypto.md5hash(qbfString: "The quick brown fox jumps over the lazy dog.")
        } else {
          print("no registration")
        }
      }.onReceive(cloud.errorPublisher, perform: { ( error ) in
        self.title = ((error as? errorAlert)?.title)!
        self.alertMessage = ((error as? errorAlert)?.message)!
        self.showAlert = true
      })
      .onReceive(alertPublisher, perform: { (content ) in
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
//          crypto.md5hash(qbfString: "The quick brown fox jumps over the lazy dog.")
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
//        let newCode = crypto.genCode(codes: ["F5D7CB9E","D3026DE8","4641FA46"])
//        print("newCode ",newCode)
        

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
          } else {
            cloud.cloudStatus()
//            cloud.cleanUp()
          }
        }
      }.onReceive(cloud.cloudPublisher) { ( message ) in
        self.alertMessage = message
        self.title = "iCloud"
        self.showAlert = true
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
        
        TextField("NickName?", text: $nickName, onCommit: {
          self.secret = crypto.genCode(codes: nil)!
        })
          .multilineTextAlignment(.center)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .disabled(nickName.count > 15)
          
        TextField("Group?", text: $group, onEditingChanged: {_ in
          if self.group.first == "a" {
            self.group = "b"
          }
        }, onCommit: {
          print("group ",self.group)
        })
          .multilineTextAlignment(.center)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .disabled(group.count > 15)
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
      
      // path for an existing user
      if self.display1 {
        Text(secret)
        Image(uiImage: image)
          .resizable()
          .frame(width: 128.0, height: 128.0)
          .allowsHitTesting(true)
          .onLongPressGesture {
          cloud.searchNReturn(token,action:"return")
        }.onReceive(cloud.returnRecordPublisher) { ( link ) in
                  self.showConfirm = true
                  (self.privateLink,self.publicLink) = link
                }.alert(isPresented:$showConfirm) {
            Alert(title: Text("Are you sure you want to delete this?"), message: Text("There is no undo"), primaryButton: .destructive(Text("Delete")) {
              cloud.deleteRecord(self.privateLink,db: "private")
              cloud.deleteRecord(self.publicLink,db: "public")
              self.display1 = false
            }, secondaryButton: .cancel() {
              self.display1 = true
            })
        }
        
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
        if display4 {
          Picker(selection: $selected, label: Text("")) {
            ForEach(0 ..< self.nouvelle.rexes.count) {dix in
              Text(self.nouvelle.rexes[dix].nickName!)
            }
          }.pickerStyle(WheelPickerStyle())
            .padding()
            .onTapGesture {
              if self.nouvelle.rexes.count > 0 {
                self.sendTo = self.nouvelle.rexes[self.selected].nickName!
                self.secret = self.nouvelle.rexes[self.selected].secret!
                cloud.getMatchingPublicNames(nil, nickName: self.nouvelle.rexes[self.selected].nickName!)
              }
          }.onReceive(cloud.matchesPublisher) { ( pins ) in
                        self.recipients = pins!
                        self.showPopover = true
                    }.popover(
                        isPresented: self.$showPopover,
                        arrowEdge: .bottom
                    ) { Text("Popover " + self.sendTo)
                      TextField("Code?", text: self.$code, onCommit: {
                        self.code = crypto.md5hash(qbfString: self.code)
                        print("Code ",self.secret,self.code)
//                        if self.secret == self.code {
                          let answer = self.recipients.filter { $0.kp == self.code }
                          if answer.first != nil {
                            print("answer ",answer.first!.token!)
                            self.disableText = false
                            self.address = answer.first!.token!
                            self.publicK = answer.first!.pk!
                            cloud.searchNUpdate(answer.first!.token!, nickName: self.sendTo)
                          } else {
                            self.alertMessage = "Wrong Code!"
                          }
                      })
                        .multilineTextAlignment(.center)
                        .textFieldStyle(RoundedBorderTextFieldStyle()
                        )
                      Text(self.alertMessage)
                      Divider()
                      Button(action: {
                        UIApplication.shared.windows[0].rootViewController?.dismiss(animated: true, completion: {})
                        self.showPopover = false
                      }) {
                        Text("Dismiss")
                      }
                    }
          
          
          
          .onReceive(popUpPublisher, perform: { ( code ) in
            self.disableText = true
            self.secret = code
            let alertHC = UIHostingController(rootView: PopUp(code: self.$secret, input: ""))
            alertHC.preferredContentSize = CGSize(width: 256, height: 256)
            alertHC.modalPresentationStyle = .formSheet
            
            UIApplication.shared.windows[0].rootViewController?.present(alertHC, animated: true)
          })
            .alert(isPresented:$showAlert2) {
              Alert(title: Text("New User"), message: Text("Saved"), dismissButton: .default(Text("Ok")))
          }.onReceive(cloud.shortProtocol) { ( _ ) in
            self.disableText = false
            
          }
          // code 6
          
          Slider(value: $alpha, in: 65...90,step: 1,onEditingChanged: { data in
            self.alphaToShow = String(Character(UnicodeScalar(Int(self.alpha))!))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
              cloud.getPublicDirectoryV4(nil, begins: self.alphaToShow)
            }
          }).padding()
          Text(alphaToShow).onReceive(cloud.directoryPublisher) { (_) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              self.display4 = false
              self.nouvelle.rexes = cloud.users!.rexes
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.display4 = true
              }
            }
          }
          Spacer()
        }
      }
    }
  }
}

private func alert() {
    let alert = UIAlertController(title: "Code Match", message: "Give me his shared PIN", preferredStyle: .alert)
    alert.addTextField() { textField in
        textField.placeholder = "Enter some text"
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
    showAlert(alert: alert)
}

func showAlert(alert: UIAlertController) {
    if let controller = topMostViewController() {
        controller.present(alert, animated: true)
    }
}

private func topMostViewController() -> UIViewController? {
    guard let rootController = keyWindow()?.rootViewController else {
        return nil
    }
    return rootController
}

private func keyWindow() -> UIWindow? {
    return UIApplication.shared.connectedScenes
    .filter {$0.activationState == .foregroundActive}
    .compactMap {$0 as? UIWindowScene}
    .first?.windows.filter {$0.isKeyWindow}.first
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
      Divider()
      Text("Press RETURN to CONTINUE")
      Spacer()
      Button(action: {
        UIApplication.shared.windows[0].rootViewController?.dismiss(animated: true, completion: {})
      }) {
        Text("Cancel")
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

//extension Character {
//    var isAscii: Bool {
//        return unicodeScalars.allSatisfy { $0.isASCII }
//    }
//    var ascii: UInt32? {
//        return isAscii ? unicodeScalars.first?.value : nil
//    }
//}

func fakeAccounts() {
//    let sPrivateKey = crypto.getPrivateKey()
//    let sPublicK = crypto.getPublicKey()
    // Star Wars Charater List
    let users = ["Andy","Alex","Baz","Brian","Cat","Carol","Dick","Dan","Ed","Earl","Fred","Frank","Gavin","Grant","Henry","Hudson","India","Irene","Jack","Jude","Kelvin","Kez","Lois","Leo","Max","Mark","Nick","Noah","Pete","Piere","Quint","Roman","Ryder","Steve","Sid","Tony","Taz","Uma","Victor","Valeria","Warren","Walter","Xena","Yosef","Zoey","Zack","Zeke","Zara"]
    var index = 0
    for user in users {
      let success = crypto.generateKeyPair(keySize: 2048, privateTag: "ch.cqd.WotsApp", publicTag: "ch.cqd.WotsApp")
      if success {
        let privateK = crypto.getPrivateKey()
        let publicK = crypto.getPublicKey()
        let image = UIImage(named: images[0])!
        let imagePNG = image.pngData()!
        let newRex = rex(id: nil, token: token, nickName: user, image: imagePNG, secret: "1234", publicK: publicK, privateK: privateK)
        cloud.users!.rexes.append(newRex)
        cloud.saveToPublic(user: newRex)
        print("user ",user)
        sleep(1)
      }
    }
//    crypto.putPublicKey(publicK: sPublicK!, keySize: 2048, publicTag: "ch.cqd.WotsApp")
//    crypto.putPrivateKey(privateK: sPrivateKey!, keySize: 2048, privateTag: "ch.cqd.WotsApp")
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

//          crypto.genCode(codes: nil)
//        var nix = 0
//        var bin = Array(repeating: Array(repeating: "", count: 21), count: 16)
//
//        let word = "F5D7CB9E"
//        var dix = 0
//        for letter in word.enumerated() {
//          bin[0][dix] = String(letter.element)
//          dix+=1
//        }
//
//        let word2 = "8A4188CB"
//        var dix2 = 0
//        for letter in word2.enumerated() {
//          bin[1][dix2] = String(letter.element)
//          dix2+=1
//        }
//
//
//        repeat {
//        var digits2D = ""
//        for dix in 0 ... 15 {
//          print("fooBar dix \(dix) nix \(nix) digits2D \(digits2D)")
//          let digits3D = crypto.dnagen(digit: digits2D)!
//          if bin[dix][nix].isEmpty {
//            digits2D = digits2D + digits3D
//            bin[dix][nix] = digits3D
//          } else {
//            digits2D = digits2D + bin[dix][nix]
//          }
//        }
//        nix += 1
//        } while nix < 8
//
//        for rex in 0 ... 15 {
//        var sex:[String] = []
//        for dix in 0 ... 20 {
//            sex.append(bin[rex][dix])
//            switch dix {
//                case 3:sex.append("-")
//                case 7:sex.append(" ")
//                case 11:sex.append("-")
//                default:break
//            }
//        }
//        print(sex.joined())
//        }
//          .simultaneousGesture(LongPressGesture()
//            .onEnded({bool in
//                if bool {
//                  print("Long!")
//                }
//                })
//                )
          
//        TextField("Secret?", text: $secret)
//          .multilineTextAlignment(.center)
//          .textFieldStyle(RoundedBorderTextFieldStyle())
//          .disabled(secret.count > 15)
