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

struct errorAlert {
  var title: String!
  var message: String!
}

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

class Storage: NSObject {

  let searchPubPublisher = PassthroughSubject<rex?, Never>()
  let fetchPublisher = PassthroughSubject<Bool?, Never>()
  let savePublisher = PassthroughSubject<Int?, Never>()
  let errorPublisher = PassthroughSubject<String, Never>()
  let recordPublisher = PassthroughSubject<rex?,Never>()

  let searchPriPublisher = PassthroughSubject<rex?, Never>()
  let gotPublicDirectory = PassthroughSubject<Bool?, Never>()
  let savedPublisher = PassthroughSubject<Bool?, Never>()
  
  let searchPri2Publisher = PassthroughSubject<[rex]?, Never>()
  let shortProtocol = PassthroughSubject<String, Never>()
  let cloudPublisher = PassthroughSubject<String, Never>()
  let directoryPublisher = PassthroughSubject<Void, Never>()

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
  
  // code 2
  
  func cloudStatus() {
    CKContainer.default().accountStatus { (accountStatus, error) in
      var message : String
      switch accountStatus {
      case .available:
        message = "iCloud will be Used"
      case .noAccount:
        message =  "Sorry you need to login into iCloud"
      case .restricted:
        message = "iCloud access restricted"
      case .couldNotDetermine:
        message = "Unable to determine iCloud status"
      default:
        message =  "new iCloud error?"
      }
      DispatchQueue.main.async { self.cloudPublisher.send(message) }
    }
  }
  
  func searchPublic(_ token:String) {
    let predicate = NSPredicate(format: "token = %@", token)
    let query = CKQuery(recordType: "directory", predicate: predicate)
    publicDB.perform(query,
                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                      guard let _ = self else { return }
                      if let error = error {
//                        DispatchQueue.main.async { self!.errorPublisher.send(error.localizedDescription) }
                        return
                      }
                      guard let results = results else { return }
                      if results.count == 0 {
                        DispatchQueue.main.async { self!.searchPubPublisher.send(nil) }
                      } else {
                        let newRex = rex(id: nil, token: nil, nickName: nil, image: nil, secret: nil, publicK: nil, privateK: nil)
                        DispatchQueue.main.async { self!.searchPubPublisher.send(newRex) }
                      }
    }
  }
  
  func searchPrivate(_ token:String) {
    let escape = UserDefaults.standard.bool(forKey: "enabled_preference")
    if escape {
      DispatchQueue.main.async { self.searchPriPublisher.send(nil) }
      return
    }
    let predicate = NSPredicate(format: "token = %@", token)
    let query = CKQuery(recordType: "directory", predicate: predicate)
    privateDB.perform(query,
                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                      guard let _ = self else { return }
                      if let error = error {
//                        DispatchQueue.main.async { self!.errorPublisher.send(error.localizedDescription) }
                        return
                      }
                      guard let results = results else { return }
                      if results.count == 0 {
                        DispatchQueue.main.async { self!.searchPriPublisher.send(nil) }
                      } else {
                        if results.count == 1 {
                          let newRex = self!.setRecord(record: results.first!)
                          DispatchQueue.main.async { self!.searchPriPublisher.send(newRex) }
                        } else {
                          var newRexes:[rex] = []
                          for result in results {
                            let newRex = self!.setRecord(record: result)
                            newRexes.append(newRex)
                          }
                          DispatchQueue.main.async { self!.searchPri2Publisher.send(newRexes) }
                        }
                      }
    }
  }
  
  func setRecord(record: CKRecord) -> rex {
    
    let name = record.object(forKey: "nickName") as? String
    let secret = record.object(forKey: "secret") as? String
    let publicK = record.object(forKey: "publicK") as? Data
    let privateK = record.object(forKey: "privateK") as? Data
    let token = record.object(forKey: "token") as? String
    let image = record.object(forKey: "image") as? Data
    let newRex = rex(id: record.recordID, token: token, nickName: name, image: image, secret: secret, publicK: publicK, privateK: privateK)
    print("setRex ",name)
    return(newRex)
  }
  
  func getPublicDirectory() {
    let predicate = NSPredicate(value: true)
    let query = CKQuery(recordType: "directory", predicate: predicate)
    publicDB.perform(query,
                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                      guard let _ = self else { return }
                      if let error = error {
//                        DispatchQueue.main.async { self!.errorPublisher.send(error.localizedDescription) }
                        return
                      }
                      guard let results = results else { return }
                      for result in results {
                        let name = result.object(forKey: "nickName") as? String
                        let publicK = result.object(forKey: "publicK") as? Data
                        let DBtoken = result.object(forKey: "token") as? String
                        let recordID = result.recordID
                        if DBtoken != token {
                          let newRex = rex(id: recordID, token: DBtoken, nickName: name, image: nil, secret: nil, publicK: publicK, privateK: nil)
                          self!.users!.rexes.append(newRex)
                        }
                      }
                      DispatchQueue.main.async { self!.gotPublicDirectory.send(true) }
    }
  }
  
  func getPrivateDirectory() {
    let predicate = NSPredicate(value: true)
    let query = CKQuery(recordType: "directory", predicate: predicate)
    privateDB.perform(query,
                     inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                      guard let _ = self else { return }
                      if let error = error {
//                        DispatchQueue.main.async { self!.errorPublisher.send(error.localizedDescription) }
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
  
  // code 3
  
  func getPublicDirectoryV2(cursor: CKQueryOperation.Cursor?) {
    let predicate = NSPredicate(value: true)
    let query = CKQuery(recordType: "directory", predicate: predicate)
    query.sortDescriptors = [NSSortDescriptor(key: "nickName", ascending: true)]
    var queryOp: CKQueryOperation!
    if cursor == nil {
      queryOp = CKQueryOperation(query: query)
    } else {
      queryOp = CKQueryOperation(cursor: cursor!)
    }
    queryOp.recordFetchedBlock = { record in
      let newRex = self.setRecord(record: record)
      self.users!.rexes.append(newRex)
    }
    queryOp.queryCompletionBlock = { cursor, error in
      if cursor != nil {
        self.getPublicDirectoryV2(cursor: cursor)
      }
    }
    publicDB.add(queryOp)
  }
  
  // code 4
  
  var cursor2G: CKQueryOperation.Cursor?
  
  func getPublicDirectoryV3(cursor: CKQueryOperation.Cursor?) {
    let predicate = NSPredicate(value: true)
    let query = CKQuery(recordType: "directory", predicate: predicate)
    query.sortDescriptors = [NSSortDescriptor(key: "nickName", ascending: true)]
    var queryOp: CKQueryOperation!
    queryOp.resultsLimit = 80
    if cursor == nil {
      queryOp = CKQueryOperation(query: query)
    } else {
      queryOp = CKQueryOperation(cursor: cursor!)
    }
    queryOp.recordFetchedBlock = { record in
      let newRex = self.setRecord(record: record)
      self.users!.rexes.append(newRex)
    }
    queryOp.queryCompletionBlock = { cursor, error in
      self.cursor2G = cursor
    }
    publicDB.add(queryOp)
  }
  
  func getPublicDirectoryV3bis() {
    if cursor2G != nil {
      getPublicDirectoryV3(cursor: cursor2G)
    }
  }
  
  func tearDown() {
    self.users!.rexes.removeAll()
  }
  // code 5
  func getPublicDirectoryV4(cursor: CKQueryOperation.Cursor?, begins:String) {
    var newUsers:[rex] = []
    let predicate = NSPredicate(format: "nickName BEGINSWITH %@", begins)
    print("predicate ",predicate)
    let query = CKQuery(recordType: "directory", predicate: predicate)
    query.sortDescriptors = [NSSortDescriptor(key: "nickName", ascending: true)]
    var queryOp: CKQueryOperation!
    
    if cursor == nil {
      queryOp = CKQueryOperation(query: query)
    } else {
      queryOp = CKQueryOperation(cursor: cursor!)
    }
    queryOp.resultsLimit = 80
    queryOp.recordFetchedBlock = { record in
      let newRex = self.setRecord(record: record)
      newUsers.append(newRex)
    }
    queryOp.queryCompletionBlock = { cursor, error in
      self.cursor2G = cursor
      self.users!.rexes = newUsers
      DispatchQueue.main.async { self.directoryPublisher.send() }
    }
    publicDB.add(queryOp)
  }
  
  func getPublicDirectoryV4bis() {
    if cursor2G != nil {
      getPublicDirectoryV3(cursor: cursor2G)
    }
  }
  
  var semaphore = DispatchSemaphore(value: 1)
  
  var ops:Int = 0 {
    didSet {
      if ops == 2 {
        DispatchQueue.main.async { self.savedPublisher.send(true) }
      }
    }
  }
  

  
  func reportError(error: CKError) {
    var error2S:errorAlert = errorAlert(title: "", message: "")
    switch error.code {
      case .alreadyShared:
        error2S = errorAlert(title: "iCloud alreadyShared", message: error.localizedDescription)
        break
      case .assetFileModified:
        error2S = errorAlert(title: "iCloud assetFileModified", message: error.localizedDescription)
        break
      case .assetFileNotFound:
        error2S = errorAlert(title: "iCloud assetFileNotFound", message: error.localizedDescription)
        break
      case .assetNotAvailable:
        error2S = errorAlert(title: "iCloud assetNotAvailable", message: error.localizedDescription)
        break
      case .badContainer:
        error2S = errorAlert(title: "iCloud badContainer", message: error.localizedDescription)
        break
      case .badDatabase:
        error2S = errorAlert(title: "iCloud badDatabase", message: error.localizedDescription)
        break
      case .batchRequestFailed:
        error2S = errorAlert(title: "iCloud batchRequestFailed", message: error.localizedDescription)
        break
      case .changeTokenExpired:
        error2S = errorAlert(title: "iCloud changeTokenExpired", message: error.localizedDescription)
        break
      case .constraintViolation:
        error2S = errorAlert(title: "iCloud constraintViolation", message: error.localizedDescription)
        break
      case .incompatibleVersion:
        error2S = errorAlert(title: "iCloud incompatibleVersion", message: error.localizedDescription)
        break
      case .internalError:
        error2S = errorAlert(title: "iCloud internalError", message: error.localizedDescription)
        break
      case .invalidArguments:
        error2S = errorAlert(title: "iCloud invalidArguments", message: error.localizedDescription)
        break
      case .limitExceeded:
        error2S = errorAlert(title: "iCloud limitExceeded", message: error.localizedDescription)
        break
      case .managedAccountRestricted:
        error2S = errorAlert(title: "iCloud managedAccountRestricted", message: error.localizedDescription)
        break
      case .missingEntitlement:
        error2S = errorAlert(title: "iCloud missingEntitlement", message: error.localizedDescription)
        break
      case .networkFailure:
        error2S = errorAlert(title: "iCloud networkFailure", message: error.localizedDescription)
        break
      case .networkUnavailable:
        error2S = errorAlert(title: "iCloud networkUnavailable", message: error.localizedDescription)
        break
      case .notAuthenticated:
        error2S = errorAlert(title: "iCloud notAuthenticated", message: error.localizedDescription)
        break
      case .operationCancelled:
        error2S = errorAlert(title: "iCloud operationCancelled", message: error.localizedDescription)
        break
      case .partialFailure:
        error2S = errorAlert(title: "iCloud partialFailure", message: error.localizedDescription)
        break
      case .participantMayNeedVerification:
        error2S = errorAlert(title: "iCloud participantMayNeedVerification", message: error.localizedDescription)
        break
      case .permissionFailure:
        error2S = errorAlert(title: "iCloud permissionFailure", message: error.localizedDescription)
        break
      case .quotaExceeded:
        error2S = errorAlert(title: "iCloud quotaExceeded", message: error.localizedDescription)
        break
      case .referenceViolation:
        error2S = errorAlert(title: "iCloud referenceViolation", message: error.localizedDescription)
        break
      case .serverRecordChanged:
        error2S = errorAlert(title: "iCloud serverRecordChanged", message: error.localizedDescription)
        break
      case .serverRejectedRequest:
        error2S = errorAlert(title: "iCloud serverRejectedRequest", message: error.localizedDescription)
        break
      case .serverResponseLost:
        error2S = errorAlert(title: "iCloud serverResponseLost", message: error.localizedDescription)
        break
      case .serviceUnavailable:
        error2S = errorAlert(title: "iCloud serviceUnavailable", message: error.localizedDescription)
        break
      case .tooManyParticipants:
        error2S = errorAlert(title: "iCloud tooManyParticipants", message: error.localizedDescription)
        break
      case .unknownItem:
        error2S = errorAlert(title: "iCloud unknownItem", message: error.localizedDescription)
        break
      case .userDeletedZone:
        error2S = errorAlert(title: "iCloud userDeletedZone", message: error.localizedDescription)
        break
      case .zoneBusy:
        error2S = errorAlert(title: "iCloud zoneBusy", message: error.localizedDescription)
        break
      case .zoneNotFound:
        error2S = errorAlert(title: "iCloud zoneNotFound", message: error.localizedDescription)
        break
      default:
        break
    }
//    DispatchQueue.main.async { self.errorPublisher.send(error2S) }
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
            print("error ",error)
//            DispatchQueue.main.async { self.errorPublisher.send(error?.localizedDescription) }
          } else {
            self.semaphore.wait()
            self.ops = self.ops + 1
            self.semaphore.signal()
          }
        }
        self.publicDB.add(saveRecordsOperation)
      
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
//            DispatchQueue.main.async { self.errorPublisher.send(error?.localizedDescription) }
          } else {
            self.semaphore.wait()
            self.ops = self.ops + 1
            self.semaphore.signal()
          }
        }
        self.privateDB.add(saveRecordsOperation)
    }
    
    
    
    // code 3
    
    func authRequest(auth:String, name: String, device:String) {
        print("***** authRequest ******")
        let predicate = NSPredicate(format: "nickName = %@", name)
        let query = CKQuery(recordType: "directory", predicate: predicate)
          privateDB.perform(query,
                         inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                          guard let _ = self else { return }
                          if let error = error {
                            DispatchQueue.main.async { print("error",error) }
                            return
                          }
                          guard let results = results else { return }
                          for result in results {
                            print("results ",result)
                            let authorized = result.object(forKey: "auth") as? String
                            if authorized == nil || authorized == "" {
                              self!.authRequest2(auth: auth, name: name, device: device, record: result.recordID)
                            } else {
                              DispatchQueue.main.async { self!.shortProtocol.send(token!) }
                            }
                          }
                          if results.count == 0 {
                            print("no name ",name)
                            self!.authRequest2(auth: auth, name: name, device: device, record: nil)
                          }
        }
      }
      
      // code 4
      
      func authRequest2(auth:String, name: String, device:String, record: CKRecord.ID?) {
        // Search the directory
        UserDefaults.standard.set(name, forKey: "name")
        UserDefaults.standard.set(device, forKey: "token")
        if record != nil {
          UserDefaults.standard.set(record?.recordName, forKey: "auth")
        } else {
          UserDefaults.standard.set("nil", forKey: "auth")
        }
        print("****** auth Request 2 *********")
        let predicate = NSPredicate(format: "nickName = %@", name)
        let query = CKQuery(recordType: "directory", predicate: predicate)
        publicDB.perform(query,
                         inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                          guard let _ = self else { return }
                          if let error = error {
                            DispatchQueue.main.async { print("error",error) }
                            return
                          }
                          guard let results = results else { return }
                          for result in results {
                            print("results ",result)
                            let token = result.object(forKey: "token") as? String
                            if token != nil {
                              let messageID = poster.requestMessage(message: "Request", title: name)
                              poster.postNotification(type: "alert", jsonID: messageID, token: device)
                            }
                          }
                          if results.count == 0 {
                            print("no name ",name)
                            
                          }
        }
      }
    
    
    
  func updateRex() {
    let record2D = UserDefaults.standard.string(forKey: "auth")
    var recordID: CKRecord.ID!
    if record2D != "nil" {
      recordID = CKRecord.ID(recordName: record2D!)
      privateDB.fetch(withRecordID: recordID,
                      completionHandler: ({record, error in
                        if let error = error {
//                          DispatchQueue.main.async { self.errorPublisher.send(error.localizedDescription) }
                          return
                        } else {
                          if record != nil {
                            self.updateRex2(record: record!)
                          }
                        }
                      }))
    } else {
      print("no rexex!")
      let name2D = UserDefaults.standard.string(forKey: "name")
      let token2D = UserDefaults.standard.string(forKey: "token")
      let record = CKRecord(recordType: "directory")
      record.setValue(name2D, forKey: "nickName")
      record.setValue(token2D, forKey: "token")
      self.updateRex2(record: record)
    }
  }
  
  func updateRex2(record: CKRecord) {
      record.setValue("cestBon", forKey: "auth")
      let saveRecordsOperation = CKModifyRecordsOperation()
      
      saveRecordsOperation.recordsToSave = [record]
      saveRecordsOperation.savePolicy = .allKeys
      saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords,deletedRecordID, error in
        if error != nil {
//          DispatchQueue.main.async { self.errorPublisher.send(error?.localizedDescription) }
        } else {
          print("updated db")
        }
      }
      self.privateDB.add(saveRecordsOperation)
  }
}

