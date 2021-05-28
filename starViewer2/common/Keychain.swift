//
//  import Keychain.swift
//  starViewer2
//
//  Created by 남상훈 on 2021/05/30.
//

import Foundation
class Keychain: NSObject {
    
    //====================
    // keychain에 데이터 저장하는 함수
    @objc class func save(key: String, data: String) -> OSStatus {
        guard let dataFromString = data.data(using: .utf8, allowLossyConversion: false) else {
            return noErr
        }
        
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String   : dataFromString ] as [String : Any]
        
        SecItemDelete(query as CFDictionary)
        
        return SecItemAdd(query as CFDictionary, nil)
    }

    //====================
    // keychain에서 데이터 로딩하는 함수
    @objc class func load(_ key: String) -> String? {
        let updatequery = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key
        ] as CFDictionary

        let newAttributes = [
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ] as CFDictionary

        SecItemUpdate(updatequery as CFDictionary, newAttributes as CFDictionary)
        
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]
        
        var dataTypeRef: CFTypeRef?
        
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr,
            let retrievedData = dataTypeRef as? Data {
                return String(data: retrievedData, encoding: .utf8)
        } else {
            checkError(status)
            return nil
        }
    }
    
    //====================
    // keychain 에러표시 함수
    fileprivate static func checkError(_ status: OSStatus) {
        if status != errSecSuccess {
            if #available(iOS 11.3, *),
                let err = SecCopyErrorMessageString(status, nil) {
                print("Operation failed: \(err)")
            } else {
                print("Operation failed: \(status). Check the error message through https://osstatus.com.")
            }
        }
    }
}

