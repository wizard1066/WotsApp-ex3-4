//
//  Cloud.swift
//  WotsApp
//
//  Created by localadmin on 04.03.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import UIKit
import CloudKit

// code 1

struct rex {
  var id: CKRecord.ID?
  var token: String?
  var nickName: String?
  var icon: Image?
  var secret: String?
  var privateK: Data?
  var publicK: Data?
}

class newUsers: ObservableObject {
  var rexes:[rex] = []
}

// code 2

let searchPublisher = PassthroughSubject<CKRecord.ID?, Never>()
let fetchPublisher = PassthroughSubject<Bool?, Never>()

class Cloud: NSObject {

  var publicDB:CKDatabase!
  var privateDB: CKDatabase!

  func search(_ token:String) {
    print("searching ",name)
    var predicate = NSPredicate(format: "token = %@", name)
    var query = CKQuery(recordType: "directory", predicate: predicate)
    publicDB.perform(query,
                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                      guard let _ = self else { return }
                      if let error = error {
                        DispatchQueue.main.async { print(error.localizedDescription) }
                        return
                      }
                      guard let results = results else { return }
                      if results.count == 0 {
                        DispatchQueue.main.async { searchPublisher.send(nil) }
                      } else {
                        DispatchQueue.main.async { searchPublisher.send(results.first.ID) }
                      }
    }
  
  // code 3
  
    func fetchRecord(_ recordID: CKRecord.ID, token: String) -> Void
    {
      publicDB.fetch(withRecordID: recordID,
                     completionHandler: ({record, error in
                      if let error = error {
                        DispatchQueue.main.async() { print(error.localizedDescription) }
                        return
                      } else {
                        if record != nil {
                          let name = result.object(forKey: "name") as? String
                          let secret = result.object(forKey: "secret") as? String
                          let recordID = result.recordID
                          let newRex = rex(id: recordID, name: name, secret: secret, token: token)
                          rexes.append(newRex)
                          DispatchQueue.main.async() { fetchPublisher.send(record.first.ID) }
                        }
                      }
                     }))
    }
  
}
