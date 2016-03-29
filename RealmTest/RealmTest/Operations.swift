//
//  Operations.swift
//  RealmTest
//
//  Created by Dal Rupnik on 29/03/16.
//  Copyright © 2016 Unified Sense. All rights reserved.
//

import Foundation
import RealmSwift

class CreateOperation : NSOperation {
    // Database reference
    private var realmRef: Realm!
    var realm: Realm {
        get {
            if realmRef == nil {
                realmRef = try! Realm()
                //realmRef.autorefresh = false
            }
            
            realmRef.refresh() // This is the line that triggers the crash, the first time Realm() is created.
            
            return realmRef
        }
        set {
            realmRef = newValue
        }
    }
    
    var reference : ModelReference?
    
    private var className: String
    
    init(className: String) {
        self.className = className
        
        super.init()
    }
    
    override func main() {
        try! realm.write {
            let pk = randomStringWithLength(10)
            
            let object = realm.dynamicCreate(className, value: [ "pk" : pk ])
            
            object.setValue(randomStringWithLength(50), forKey: "data")
            
            realm.add(object)
            
            reference = ModelReference(className: className, pk: pk, related: false)
            
            NSLog("Creating object: [\(className): \(pk)]")
        }
    }
    
}

class RelationOperation: NSOperation {
    
    // Database reference
    private var realmRef: Realm!
    
    var sourceClassName = ""
    var sourceKeyValue = ""
    var sourcePropertyName = ""
    var targetClassName = ""
    var targetKeyValue = ""
    
    var realm: Realm {
        get {
            if realmRef == nil {
                realmRef = try! Realm()
                //realmRef.autorefresh = false
            }
            
            realmRef.refresh() // This is the line that triggers the crash, the first time Realm() is created.
            
            return realmRef
        }
        set {
            realmRef = newValue
        }
    }
    
    override func main () {
        let source = realm.dynamicObjectForPrimaryKey(sourceClassName, key: sourceKeyValue)
        let target = realm.dynamicObjectForPrimaryKey(targetClassName, key: targetKeyValue)
        
        
        if let source = source, target = target {
            if source.objectSchema[self.sourcePropertyName]?.type == .Array {
                try! realm.write {
                    NSLog("Relation LIST src: [%@: %@] target: [%@: %@ - %@]", sourceClassName, sourceKeyValue, targetClassName, targetKeyValue, sourcePropertyName)
                    
                    let list = source.dynamicList(self.sourcePropertyName)
                    
                    if !list.contains(target) {
                        list.append(target)
                    }
                    
                    source[self.sourcePropertyName] = list
                }
            }
            else {
                try! realm.write {
                    NSLog("Relation PROPERTY src: [%@: %@] target: [%@: %@ - %@]", sourceClassName, sourceKeyValue, targetClassName, targetKeyValue, sourcePropertyName)
                    
                    source[self.sourcePropertyName] = target
                }
            }
        }
    }
}

class LongOperation : NSOperation {
    override func main() {
        for i in 1..<100_000 {
            recursive(i)
        }
    }
    
    private func recursive (num: Int) -> Int {
        
        if num > 10_000 {
            return num
        }
        
        return recursive(num + 2)
    }
}