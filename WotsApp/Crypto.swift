//
//  crypto.swift
//  WotsApp
//
//  Created by localadmin on 02.03.20.
//  Copyright © 2020 Mark Lucking. All rights reserved.
//

import UIKit
import Cryptor


class Crypto: NSObject {
  // code 1
  private var publicKey : SecKey?
  private var privateKey : SecKey?
  
  // code 1
  
  func savePrivateKey() {
    let localK = getPrivateKey64() as Any
    let defaults = UserDefaults.init(suiteName: "group.ch.cqd.WotsApp")
    defaults?.set(localK, forKey: "privateK")
  }
  
  func generateKeyPair(keySize: UInt, privateTag: String, publicTag: String) -> Bool {
  let publicKeyParameters: [NSString: AnyObject] = [
      kSecAttrIsPermanent: true as AnyObject,
      kSecAttrApplicationTag: publicTag as AnyObject
    ]
    let privateKeyParameters: [NSString: AnyObject] = [
      kSecAttrIsPermanent: true as AnyObject,
      kSecAttrApplicationTag: publicTag as AnyObject
    ]
    let parameters: [String: AnyObject] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
      kSecAttrKeySizeInBits as String: keySize as AnyObject,
      kSecPrivateKeyAttrs as String: privateKeyParameters as AnyObject,
      kSecPublicKeyAttrs as String: publicKeyParameters as AnyObject
    ]
    
    let status : OSStatus = SecKeyGeneratePair(parameters as CFDictionary, &(self.publicKey), &(self.privateKey))
    
    // code 15
    savePrivateKey()
    
    
    return (status == errSecSuccess && self.publicKey != nil && self.privateKey != nil)
  }
  // code 2
  func encrypt(text: String) -> [UInt8] {
    let plainBuffer = [UInt8](text.utf8)
    var cipherBufferSize : Int = Int(SecKeyGetBlockSize((self.publicKey)!))
    var cipherBuffer = [UInt8](repeating:0, count:Int(cipherBufferSize))
    
    // Encrypto  should less than key length
    let status = SecKeyEncrypt((self.publicKey)!, SecPadding.PKCS1, plainBuffer, plainBuffer.count, &cipherBuffer, &cipherBufferSize)
    if (status != errSecSuccess) {
      print("Failed Encryption")
    }
    return cipherBuffer
  }
  // code 3
  func decprypt(encrpted: [UInt8]) -> String? {
    var plaintextBufferSize = Int(SecKeyGetBlockSize((self.privateKey)!))
    var plaintextBuffer = [UInt8](repeating:0, count:Int(plaintextBufferSize))
    
    let status = SecKeyDecrypt((self.privateKey)!, SecPadding.PKCS1, encrpted, plaintextBufferSize, &plaintextBuffer, &plaintextBufferSize)
    
    if (status != errSecSuccess) {
      print("Failed Decrypt")
      return nil
    }
    return NSString(bytes: &plaintextBuffer, length: plaintextBufferSize, encoding: String.Encoding.utf8.rawValue)! as String
  }
  // code 4 + 5
  func encryptBase64(text: String) -> String {
    let plainBuffer = [UInt8](text.utf8)
    var cipherBufferSize : Int = Int(SecKeyGetBlockSize((self.publicKey)!))
    var cipherBuffer = [UInt8](repeating:0, count:Int(cipherBufferSize))
    
    // Encrypto  should less than key length
    let status = SecKeyEncrypt((self.publicKey)!, SecPadding.PKCS1, plainBuffer, plainBuffer.count, &cipherBuffer, &cipherBufferSize)
    if (status != errSecSuccess) {
      print("Failed Encryption")
    }
    
    let mudata = NSData(bytes: &cipherBuffer, length: cipherBufferSize)
    return mudata.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
  }
  // code 5
  func decpryptBase64(encrpted: String) -> String? {
    
    let data : NSData = NSData(base64Encoded: encrpted, options: .ignoreUnknownCharacters)!
    let count = data.length / MemoryLayout<UInt8>.size
    var array = [UInt8](repeating: 0, count: count)
    data.getBytes(&array, length:count * MemoryLayout<UInt8>.size)
    
    var plaintextBufferSize = Int(SecKeyGetBlockSize((self.privateKey)!))
    var plaintextBuffer = [UInt8](repeating:0, count:Int(plaintextBufferSize))
    
    let status = SecKeyDecrypt((self.privateKey)!, SecPadding.PKCS1, array, plaintextBufferSize, &plaintextBuffer, &plaintextBufferSize)
    
    if (status != errSecSuccess) {
      print("Failed Decrypt")
      return nil
    }
    return NSString(bytes: &plaintextBuffer, length: plaintextBufferSize, encoding: String.Encoding.utf8.rawValue)! as String
  }
  // code 7
  func getPublicKey() -> Data? {
    var error: UnsafeMutablePointer<Unmanaged<CFError>?>?
    let publicK = SecKeyCopyExternalRepresentation(self.publicKey!, error) as? Data
    print("getPublicKey ",self.publicKey.debugDescription)
    return publicK! as Data
  }
  
  func getPrivateKey() -> Data? {
    var error: UnsafeMutablePointer<Unmanaged<CFError>?>?
    let privateK = SecKeyCopyExternalRepresentation(self.privateKey!, error)
    print("getPrivateKey ",self.privateKey.debugDescription)
    return privateK! as Data
  }
  
  // code 9
  func getPublicKey64() -> String? {
    var error: UnsafeMutablePointer<Unmanaged<CFError>?>?
    let publicK = SecKeyCopyExternalRepresentation(self.publicKey!, error) as Data?
    let exportedPublicK = publicK?.base64EncodedString()
    print("exported PublicK ",exportedPublicK!)
    return exportedPublicK! as String
  }
  
  func getPrivateKey64() -> String? {
     var error: UnsafeMutablePointer<Unmanaged<CFError>?>?
     let privateK = SecKeyCopyExternalRepresentation(self.privateKey!, error) as Data?
     let exportedPrivateK = privateK?.base64EncodedString()
     print("exported PrivateK ",exportedPrivateK)
     return exportedPrivateK! as String
   }
  
  func putPublicKey64(publicK:String, keySize: UInt, publicTag: String) {
    let secKeyData : NSData = NSData(base64Encoded: publicK, options: .ignoreUnknownCharacters)!
    putPublicKey(publicK: secKeyData as Data, keySize: keySize, publicTag: publicTag)
  }
  
  func putPrivateKey64(privateK:String, keySize: UInt, privateTag: String) {
    let secKeyData : NSData = NSData(base64Encoded: privateK, options: .ignoreUnknownCharacters)!
    putPrivateKey(privateK: secKeyData as Data, keySize: keySize, privateTag: privateTag)
  }
  
  // code 8
  
  func putPublicKey(publicK:Data, keySize: UInt, publicTag: String) {
    //    let secKeyData : NSData = NSData(base64Encoded: publicK, options: .ignoreUnknownCharacters)!
    let attributes: [String:Any] = [
      kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
      kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
      kSecAttrKeySizeInBits as String: keySize,
      kSecAttrIsPermanent as String: true as AnyObject,
      kSecAttrApplicationTag as String: publicTag as AnyObject
    ]
    self.publicKey = SecKeyCreateWithData(publicK as CFData, attributes as CFDictionary, nil)
    print("putpublickey ",self.publicKey)
  }
  
  func putPrivateKey(privateK:Data, keySize: UInt, privateTag: String) {
    //    let secKeyData : NSData = NSData(base64Encoded: publicK, options: .ignoreUnknownCharacters)!
    let attributes: [String:Any] = [
      kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
      kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
      kSecAttrKeySizeInBits as String: keySize,
      kSecAttrIsPermanent as String: true as AnyObject,
      kSecAttrApplicationTag as String: privateTag as AnyObject
    ]
    self.privateKey = SecKeyCreateWithData(privateK as CFData, attributes as CFDictionary, nil)
    print("putprivatekey ",self.privateKey)
  }
  
  // code 1
  
func md5hash(qbfString: String) {
//  let qbfString = "The quick brown fox jumps over the lazy dog."

  let md5 = Digest(using: .md5)
  md5.update(string: qbfString)
  let digest = md5.final()
  
  
  var md5String = ""
  for byte in digest {
    md5String += String(format:"%02x", UInt8(byte))
  }
  print("digest ",digest, md5String)

  // NSData using optional chaining...
//  let qbfData = CryptoUtils.data(from: qbfBytes)
//  let digest = Digest(using: .md5).update(data: qbfData)?.final()
}

func redact(_ pin:String )-> String {
    let show = Int.random(in: 0 ..< pin.count )
    var hidden:String = ""
    var dix = 0
    for letter in pin.enumerated() {
      if dix == show {
        hidden = hidden + String(letter.element)
        dix += 1
      } else {
        hidden = hidden + "*"
        dix += 1
      }
    }
    return hidden
  }

  func genCode(codes:[String]?) -> String? {
    if codes == nil {
      let random1 = Int.random(in: 4096 ..< 65535)
      let random2 = Int.random(in: 4096 ..< 65535)
      let digit = String(format:"%02X-%02X", random1,random2)
      return digit
    } else {
      var nix = 0
      var bin = Array(repeating: Array(repeating: "", count: 21), count: 16)
      
      for word in codes! {
        var dix = 0
        for letter in word.enumerated() {
          bin[nix][dix] = String(letter.element)
          dix+=1
        }
        nix += 1
      }
      
      nix = 0
      repeat {
        var digits2D = ""
        for dix in 0 ... codes!.count {
          print("fooBar dix \(dix) nix \(nix) digits2D \(digits2D)")
          if bin[dix][nix].isEmpty {
            let digits3D = crypto.dnagen(digit: digits2D)!
            digits2D = digits2D + digits3D
            bin[dix][nix] = digits3D
          } else {
            digits2D = digits2D + bin[dix][nix]
          }
        }
        nix += 1
      } while nix < 8
      
      for rex in 0 ... codes!.count {
      var sex:[String] = []
      for dix in 0 ... 7 {
          sex.append(bin[rex][dix])
          switch dix {
              case 3:sex.append("-")
              default:break
          }
      }
      if rex == codes!.count {
        return(sex.joined())
      }
      }
    }
    return nil
  }

func dnagen(digit:String?) -> String? {
        let fullSet:Set = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
        let digits = Array(digit!).map { String($0) }
        var subSet = fullSet.subtracting(digits)
        if subSet.isEmpty {
          return digits.first
        }
        let sex = Int.random(in: 0 ..< subSet.count)
        let dix = subSet.index(subSet.startIndex, offsetBy: sex)
        let newDigit = subSet.remove(at: dix)
        return newDigit
        
  }
  
  
  
//  func md5Hash(str: String) -> String {
//      if let strData = str.data(using: String.Encoding.utf8) {
//          /// #define CC_MD5_DIGEST_LENGTH    16          /* digest length in bytes */
//          /// Creates an array of unsigned 8 bit integers that contains 16 zeros
//          var digest = [UInt8](repeating: 0, count:Int(CC_MD5_DIGEST_LENGTH))
//
//          /// CC_MD5 performs digest calculation and places the result in the caller-supplied buffer for digest (md)
//          /// Calls the given closure with a pointer to the underlying unsafe bytes of the strData’s contiguous storage.
//          strData.withUnsafeBytes {
//              // CommonCrypto
//              // extern unsigned char *CC_MD5(const void *data, CC_LONG len, unsigned char *md) --|
//              // OpenSSL                                                                          |
//              // unsigned char *MD5(const unsigned char *d, size_t n, unsigned char *md)        <-|
//              CC_MD5($0.baseAddress, UInt32(strData.count), &digest)
//          }
//
//
//          var md5String = ""
//          /// Unpack each byte in the digest array and add them to the md5String
//          for byte in digest {
//              md5String += String(format:"%02x", UInt8(byte))
//          }
//
//          // MD5 hash check (This is just done for example)
//          if md5String.uppercased() == "8D84E6C45CE9044CAE90C064997ACFF1" {
//              print("Matching MD5 hash: 8D84E6C45CE9044CAE90C064997ACFF1")
//          } else {
//              print("MD5 hash does not match: \(md5String)")
//          }
//          return md5String
//
//      }
//      return ""
//  }
//
//  }
  
  
}

