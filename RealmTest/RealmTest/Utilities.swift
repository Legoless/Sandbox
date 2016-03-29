//
//  Utilities.swift
//  RealmTest
//
//  Created by Dal Rupnik on 29/03/16.
//  Copyright © 2016 Unified Sense. All rights reserved.
//

import Foundation

func randomStringWithLength (len : Int) -> String {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    let randomString : NSMutableString = NSMutableString(capacity: len)
    
    for _ in 0 ..< len {
        let length = UInt32 (letters.length)
        let rand = arc4random_uniform(length)
        randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
    }
    
    return randomString as String
}

func randomInt(max: Int) -> Int {
    return Int(arc4random_uniform(UInt32(max)))
}