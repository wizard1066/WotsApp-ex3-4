//
//  Storage.swift
//  WotsApp
//
//  Created by localadmin on 04.03.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import UIKit



//
//  Cloud.swift
//  WotsApp
//
//  Created by localadmin on 04.03.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import UIKit
import CloudKit
import Combine

// code 1

struct rex {
  var id: CKRecord.ID?
  var token: String?
  var nickName: String?
  var image: Data?
  var secret: String?
  var privateK: Data?
  var publicK: Data?
  
  init(id: CKRecord.ID?, token: String?, nickName: String?, image: Data?, secret: String?, publicK: Data?, privateK: Data?) {
    self.id = id
    self.token = token
    self.nickName = nickName
    self.image = image
    self.secret = secret
    self.publicK = publicK
    self.privateK = privateK
  }
}

class newUsers {
  var rexes:[rex] = []
}

// code 2

let searchPubPublisher = PassthroughSubject<rex?, Never>()
let fetchPublisher = PassthroughSubject<Bool?, Never>()
let savePublisher = PassthroughSubject<Int?, Never>()
let errorPublisher = PassthroughSubject<String?, Never>()
let recordPublisher = PassthroughSubject<rex?,Never>()


class Storage: NSObject {

  let searchPriPublisher = PassthroughSubject<rex?, Never>()
  let gotPublicDirectory = PassthroughSubject<Bool?, Never>()
  let savedPublisher = PassthroughSubject<Bool?, Never>()

  var publicDB: CKDatabase!
  var privateDB: CKDatabase!
  var sharedDB: CKDatabase!
  var users:newUsers?
  
  override init() {
    super.init()
    publicDB = CKContainer.default().publicCloudDatabase
    privateDB = CKContainer.default().privateCloudDatabase
    sharedDB = CKContainer.default().sharedCloudDatabase
    users = newUsers()
  }

  func searchPublic(_ token:String) {
    let predicate = NSPredicate(format: "token = %@", token)
    let query = CKQuery(recordType: "directory", predicate: predicate)
    publicDB.perform(query,
                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                      guard let _ = self else { return }
                      if let error = error {
                        DispatchQueue.main.async { errorPublisher.send(error.localizedDescription) }
                        return
                      }
                      guard let results = results else { return }
                      if results.count == 0 {
                        DispatchQueue.main.async { searchPubPublisher.send(nil) }
                      } else {
                        let newRex = rex(id: nil, token: nil, nickName: nil, image: nil, secret: nil, publicK: nil, privateK: nil)
                        DispatchQueue.main.async { searchPubPublisher.send(newRex) }
                      }
    }
  }
  
  func searchPrivate(_ token:String) {
    let predicate = NSPredicate(format: "token = %@", token)
    let query = CKQuery(recordType: "directory", predicate: predicate)
    privateDB.perform(query,
                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                      guard let _ = self else { return }
                      if let error = error {
                        DispatchQueue.main.async { errorPublisher.send(error.localizedDescription) }
                        return
                      }
                      guard let results = results else { return }
                      if results.count == 0 {
                        DispatchQueue.main.async { self!.searchPriPublisher.send(nil) }
                      } else {
                        // Assuming we tokens are unique, which I believe they should be
                        let record = results.first!
                        let name = record.object(forKey: "nickName") as? String
                        let secret = record.object(forKey: "secret") as? String
                        let publicK = record.object(forKey: "publicK") as? Data
                        let privateK = record.object(forKey: "privateK") as? Data
                        let token = record.object(forKey: "token") as? String
                        let image = record.object(forKey: "image") as? Data
                        let newRex = rex(id: record.recordID, token: token, nickName: name, image: image, secret: secret, publicK: publicK, privateK: privateK)
                        DispatchQueue.main.async { self!.searchPriPublisher.send(newRex) }
                      }
    }
  }
  
  // code 3
  
  func fetchPublicRecord(_ recordID: CKRecord.ID, token: String) -> Void
  {
    publicDB.fetch(withRecordID: recordID,
                   completionHandler: ({record, error in
                    if let error = error {
                      DispatchQueue.main.async() { errorPublisher.send(error.localizedDescription) }
                      return
                    } else {
                      if record != nil {
                        let name = record!.object(forKey: "nickName") as? String
                        let secret = record!.object(forKey: "secret") as? String
                        let recordID = record!.recordID
                        let newRex = rex(id: recordID, token: nil, nickName: name, image: nil, secret: secret, publicK: nil, privateK: nil)
                        self.users!.rexes.append(newRex)
                        DispatchQueue.main.async() { fetchPublisher.send(true) }
                      } else {
                        DispatchQueue.main.async() { fetchPublisher.send(false) }
                      }
                    }
                   }))
    }
    
    var door1:Bool = false {
      didSet {
        if door2 {
          DispatchQueue.main.async() { self.savedPublisher.send(true) }
        }
      }
    }
    
    var door2:Bool = false {
      didSet {
        if door1 {
          DispatchQueue.main.async() { self.savedPublisher.send(true) }
        }
      }
  }
  
    func saveRex(user: rex) {
      saveToPublic(user: user)
      saveToPrivate(user: user)
    }
    
    func saveToPublic(user: rex) {
      let record = CKRecord(recordType: "directory")
      record.setValue(user.publicK, forKey: "publicK")
      record.setValue(user.nickName, forKey: "nickName")
      record.setValue(user.token, forKey: "token")
      let saveRecordsOperation = CKModifyRecordsOperation()
      saveRecordsOperation.recordsToSave = [record]
      saveRecordsOperation.savePolicy = .allKeys
      saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords,deletedRecordID, error in
        if error != nil {
          DispatchQueue.main.async() { errorPublisher.send(error?.localizedDescription) }
        } else {
          self.door1 = true
        }
      }
      publicDB.add(saveRecordsOperation)
    }
    
    func saveToPrivate(user: rex) {
      let record = CKRecord(recordType: "directory")
      record.setValue(user.publicK, forKey: "publicK")
      record.setValue(user.nickName, forKey: "nickName")
      record.setValue(user.token, forKey: "token")
      record.setValue(user.privateK, forKey: "privateK")
      record.setValue(user.secret, forKey: "secret")
      record.setValue(user.image, forKey: "image")
      let saveRecordsOperation = CKModifyRecordsOperation()
      saveRecordsOperation.recordsToSave = [record]
      saveRecordsOperation.savePolicy = .allKeys
      saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords,deletedRecordID, error in
        if error != nil {
          DispatchQueue.main.async() { errorPublisher.send(error?.localizedDescription) }
        } else {
          self.door2 = true
        }
      }
      privateDB.add(saveRecordsOperation)
    }
    
    func getPublicDirectory() {
      let predicate = NSPredicate(value: true)
      let query = CKQuery(recordType: "directory", predicate: predicate)
      publicDB.perform(query,
                       inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                        guard let _ = self else { return }
                        if let error = error {
                          DispatchQueue.main.async() { errorPublisher.send(error.localizedDescription) }
                          return
                        }
                        guard let results = results else { return }
                        for result in results {
                          let name = result.object(forKey: "nickName") as? String
                          let secret = result.object(forKey: "secret") as? String
                          let publicK = result.object(forKey: "publicK") as? Data
                          let token = result.object(forKey: "token") as? String
                          let recordID = result.recordID
                          let newRex = rex(id: recordID, token: token, nickName: name, image: nil, secret: secret, publicK: publicK, privateK: nil)
                          self!.users!.rexes.append(newRex)
                        }
                        DispatchQueue.main.async() { self!.gotPublicDirectory.send(true) }
      }
    }
    
    func getPrivateDirectory() {
      let predicate = NSPredicate(value: true)
      let query = CKQuery(recordType: "directory", predicate: predicate)
      privateDB.perform(query,
                       inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                        guard let _ = self else { return }
                        if let error = error {
                          DispatchQueue.main.async() { errorPublisher.send(error.localizedDescription) }
                          return
                        }
                        guard let results = results else { return }
                        for result in results {
                          let name = result.object(forKey: "nickName") as? String
                          let secret = result.object(forKey: "secret") as? String
                          let privateK = result.object(forKey: "privateK") as? Data
                          let publicK = result.object(forKey: "publicK") as? Data
                          let token = result.object(forKey: "token") as? String
                          let image = result.object(forKey: "image") as? Data
                          let recordID = result.recordID
                          let newRex = rex(id: recordID, token: token, nickName: name, image: image, secret: secret, publicK: publicK, privateK: privateK)
                          self!.users!.rexes.append(newRex)
                        }
      }
    }
  
}

