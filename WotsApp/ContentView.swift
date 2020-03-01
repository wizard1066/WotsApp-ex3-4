//
//  ContentView.swift
//  WotsApp
//
//  Created by localadmin on 29.02.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import SwiftUI
// code 3 + code 9
let notify = LocalNotifications()
let remote = RemoteNotifications()
struct ContentView: View {
  var body: some View {
    VStack {
      Button(action: {
        notify.doNotification()
      }) {
        Text("local")
      }
      Button(action: {
        remote.postNotification()
      }) {
        Text("remote")
      }
    }
  }
}
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
