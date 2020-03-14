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
  let returnRecordPublisher = PassthroughSubject<(String,String),Never>()

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
//    let escape = UserDefaults.standard.bool(forKey: "enabled_preference")
//    if escape {
//      DispatchQueue.main.async { self.searchPriPublisher.send(nil) }
//      return
//    }
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
                            if (newRex != nil) { newRexes.append(newRex!) }
                          }
                          DispatchQueue.main.async { self!.searchPri2Publisher.send(newRexes) }
                        }
                      }
    }
  }
  
  // code 4
  
  func searchNReturn(_ token:String, action: String) {
  let predicate = NSPredicate(format: "token = %@", token)
      let query = CKQuery(recordType: "directory", predicate: predicate)
      privateDB.perform(query,
                       inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
                        guard let _ = self else { return }
                        if let error = error {
                          DispatchQueue.main.async { self!.errorPublisher.send(error.localizedDescription) }
                          return
                        }
                        guard let results = results else { return }
                        if results.count == 1 {
                          if action == "return" {
                            let link = results.first?.object(forKey:"linked") as? String
                            DispatchQueue.main.async { self!.returnRecordPublisher.send(((results.first?.recordID.recordName)!,link!)) }
                          }
                          if action == "block" {
                            self!.updateRex3(record: results.first!)
                          }
                        }
                        }
                        
    
  }
  
  func deleteRecords(_ recordIDs:[CKRecord.ID]) {
    let deleteRecordsOperation = CKModifyRecordsOperation()
    deleteRecordsOperation.recordsToSave = []
    deleteRecordsOperation.recordIDsToDelete = recordIDs
    deleteRecordsOperation.modifyRecordsCompletionBlock = { savedRecords,deletedRecordID, error in
      if error != nil {
        print("error ",error)
        //          DispatchQueue.main.async { self.errorPublisher.send(error?.localizedDescription) }
      } else {
        print("updated db")
      }
    }
    self.publicDB.add(deleteRecordsOperation)
  }
  
  func deleteRecord(_ recordID:String, db:String) {
    let record2D = CKRecord.ID(recordName: recordID)
    let deleteRecordsOperation = CKModifyRecordsOperation()
    deleteRecordsOperation.recordsToSave = []
    deleteRecordsOperation.recordIDsToDelete = [record2D]
    deleteRecordsOperation.modifyRecordsCompletionBlock = { savedRecords,deletedRecordID, error in
      if error != nil {
        DispatchQueue.main.async { self.errorPublisher.send(error!.localizedDescription) }
      } else {
        print("updated db")
      }
    }
    if db == "private" {
      self.privateDB.add(deleteRecordsOperation)
    } else {
      self.publicDB.add(deleteRecordsOperation)
    }
  }
  
  // code 8
  
  func setRecord(record: CKRecord) -> rex? {
    
    let name = record.object(forKey: "nickName") as? String
    let secret = record.object(forKey: "secret") as? String
    let publicK = record.object(forKey: "publicK") as? Data
    let privateK = record.object(forKey: "privateK") as? Data
    let device = record.object(forKey: "token") as? String
    let image = record.object(forKey: "image") as? Data
    let newRex = rex(id: record.recordID, token: device, nickName: name, image: image, secret: secret, publicK: publicK, privateK: privateK)
    print("setRex ",name)
    
    if device == token! {
      return(newRex)
    }
    
    
    let defaults = UserDefaults.init(suiteName: "group.ch.cqd.WotsApp")
    let tokensBlocked = defaults?.array(forKey: "block")
    
//    if tokensBlocked != nil {
//      let escape = (tokensBlocked as! [String]).contains(token!)
//      if escape {
//        print("no way, Jose!!")
//        return(nil)
//      }
//    }
    if tokenIsBlocked(token: device!) {
      return(nil)
    }
    

    if tokenIsBlocked(token: token!) {
      return(nil)
    }
    
    
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
                        
                        if DBtoken != token && !self!.tokenIsBlocked(token: DBtoken!) {
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
    var newUsers:[rex] = []
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
      if newRex != nil { newUsers.append(newRex!) }
    }
    queryOp.queryCompletionBlock = { cursor, error in
      if cursor != nil {
        self.getPublicDirectoryV2(cursor: cursor)
      }
    }
    publicDB.add(queryOp)
  }
  
 

  // code 5
  func getPublicDirectoryV4(cursor: CKQueryOperation.Cursor?, begins:String?) {
  var newUsers:[rex] = []
    var predicate:NSPredicate!
    if begins != nil {
      predicate = NSPredicate(format: "nickName BEGINSWITH %@", begins!)
    } else {
      predicate = NSPredicate(value: true)
    }
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
      if newRex != nil { newUsers.append(newRex!) }
    }
    queryOp.queryCompletionBlock = { cursor, error in
      if cursor != nil {
        self.getPublicDirectoryV4(cursor: cursor, begins: begins)
      } else {
        self.users!.rexes = newUsers
        // ********** code to cleanup **********
//        for record in cloud.users!.rexes {
//          self.deleteID.append(record.id!)
//        }
//        self.deleteRecords(self.deleteID)
        // ********** end cleanup code **********
        DispatchQueue.main.async { self.directoryPublisher.send() }
      }
    }
    publicDB.add(queryOp)
  }
  
//  func getPublicDirectoryV4bis(begins: String) {
//    if cursor2G != nil {
//      getPublicDirectoryV4(cursor: cursor2G, begins: begins)
//    }
//  }
  
  var semaphore = DispatchSemaphore(value: 1)
  
  var ops:Int = 0 {
    didSet {
      if ops == 2 {
        DispatchQueue.main.async { self.savedPublisher.send(true) }
      }
    }
  }
  
  var deleteID:[CKRecord.ID] = []
  
  func cleanUp() {
    getPublicDirectoryV4(cursor: nil, begins: nil)
  }
  
  func ckErrors(error: CKError) {
    switch error.code {
      case .alreadyShared: break
      case .assetFileModified: break
      case .assetFileNotFound: break
      case .assetNotAvailable: break
      case .badContainer: break
      case .badDatabase: break
      case .batchRequestFailed: break
      case .changeTokenExpired: break
      case .constraintViolation: break
      case .incompatibleVersion: break
      case .internalError: break
      case .invalidArguments: break
      case .limitExceeded: break
      case .managedAccountRestricted: break
      case .missingEntitlement: break
      case .networkFailure: break
      case .networkUnavailable: break
      case .notAuthenticated: break
      case .operationCancelled: break
      case .partialFailure: break
      case .participantMayNeedVerification: break
      case .permissionFailure: break
      case .quotaExceeded: break
      case .referenceViolation: break
      case .serverRecordChanged: break
      case .serverRejectedRequest: break
      case .serverResponseLost: break
      case .serviceUnavailable: break
      case .tooManyParticipants: break
      case .unknownItem: break
      case .userDeletedZone: break
      case .zoneBusy: break
      case .zoneNotFound: break
      default:
        break
    }
//    DispatchQueue.main.async { self.errorPublisher.send(error2S) }
  }
  
  
  
  func saveRex(user: rex) {
    saveToPublic(user: user)
    saveToPrivate(user: user)
  }
  
  // code 9
    
    func saveToPublic(user: rex) {
        self.semaphore.wait()
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
            
            self.ops = self.ops + 1
            self.xlink = savedRecords!.first?.recordID.recordName
            self.semaphore.signal()
          }
        }
        self.publicDB.add(saveRecordsOperation)
      
    }
    
    private var xlink: String!
    
    func saveToPrivate(user: rex) {
        self.semaphore.wait()
        let record = CKRecord(recordType: "directory")
        record.setValue(user.publicK, forKey: "publicK")
        record.setValue(user.nickName, forKey: "nickName")
        record.setValue(user.token, forKey: "token")
        record.setValue(user.privateK, forKey: "privateK")
        record.setValue(user.secret, forKey: "secret")
        record.setValue(user.image, forKey: "image")
        record.setValue(xlink, forKey: "linked")
        let saveRecordsOperation = CKModifyRecordsOperation()
        
        saveRecordsOperation.recordsToSave = [record]
        saveRecordsOperation.savePolicy = .allKeys
        saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords,deletedRecordID, error in
          if error != nil {
//            DispatchQueue.main.async { self.errorPublisher.send(error?.localizedDescription) }
          } else {
            
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
          DispatchQueue.main.async { self.errorPublisher.send(error!.localizedDescription) }
        } else {
          print("updated db")
        }
      }
      self.privateDB.add(saveRecordsOperation)
  }
  
  // code 5
  
  func updateRex3(record: CKRecord) {
        record.setValue("oui", forKey: "block")
        let saveRecordsOperation = CKModifyRecordsOperation()
        
        saveRecordsOperation.recordsToSave = [record]
        saveRecordsOperation.savePolicy = .allKeys
        saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords,deletedRecordID, error in
          if error != nil {
            DispatchQueue.main.async { self.errorPublisher.send(error!.localizedDescription) }
          } else {
            let tokenToBlock = record.object(forKey:"token") as? String
            self.saveBlockedTokenToSharedmemory(token2B: tokenToBlock!)
            print("updated db")
          }
        }
        self.privateDB.add(saveRecordsOperation)
    }
    
    func saveBlockedTokenToSharedmemory(token2B: String) {
      let defaults = UserDefaults.init(suiteName: "group.ch.cqd.WotsApp")
      let tokensBlocked = defaults?.array(forKey: "block")
      if var tokensBlocked = tokensBlocked as? [String] {
        tokensBlocked.append(token2B)
        defaults?.set(tokensBlocked, forKey: "block")
      } else {
        defaults?.set([token2B], forKey: "block")
      }
    }
    
    func tokenIsBlocked(token: String) -> Bool {
      let defaults = UserDefaults.init(suiteName: "group.ch.cqd.WotsApp")
      let tokensBlocked = defaults?.array(forKey: "block")
      
      if tokensBlocked != nil {
        let escape = (tokensBlocked as! [String]).contains(token)
        if escape {
          print("no way, Jose!!")
          return(true)
        }
      }
      return false
  }
  
  func showBlocked() {
    let defaults = UserDefaults.init(suiteName: "group.ch.cqd.WotsApp")
    let tokensBlocked = defaults?.array(forKey: "block")
    
    if tokensBlocked != nil {
      for token in tokensBlocked! {
        print("blocked ",token)
      }
    }
  }
}

