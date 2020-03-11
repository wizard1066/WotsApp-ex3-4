//
//  Connect.swift
//  WotsApp
//
//  Created by localadmin on 11.03.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import UIKit
import Network

class Connect: NSObject {
  static var shared = Connect()
  
  private override init(){}
  
  var monitor: NWPathMonitor?
  var isMonitoring = false
  
  var didStartMonitoringHandler: (() -> Void)?
  var didStopMonitoringHandler: (() -> Void)?
  var netStatusChangeHandler: (() -> Void)?
  
  func startMonitoring() {
    guard !isMonitoring else { return }
      monitor = NWPathMonitor()
      let queue = DispatchQueue(label: "NetStatus_Monitor")
      monitor?.start(queue: queue)
      monitor?.pathUpdateHandler = { _ in
          self.netStatusChangeHandler?()
      }
      isMonitoring = true
      didStartMonitoringHandler?()
    }
  
  var isConnected: Bool {
    return monitor!.currentPath.status == .satisfied
  }
}
