//
//  AppDelegate.swift
//  RealmTest
//
//  Created by Dal Rupnik on 14/03/16.
//  Copyright © 2016 Unified Sense. All rights reserved.
//

import UIKit
import RealmSwift

func randomStringWithLength (len : Int) -> String {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    let randomString : NSMutableString = NSMutableString(capacity: len)
    
    for (var i=0; i < len; i++){
        let length = UInt32 (letters.length)
        let rand = arc4random_uniform(length)
        randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
    }
    
    return randomString as String
}

class ModelA: Object {
    dynamic var pk : String?
    dynamic var data : String?
    
    let objects = List<ModelB>()
    
    override class func primaryKey() -> String? {
        return "pk"
    }
}

class ModelB: Object {
    dynamic var pk : String?
    dynamic var data : String?
    override class func primaryKey() -> String? {
        return "pk"
    }
}

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
    
    var pkA : String?
    var pkB : String?
    var pkBB : String?
    
    override func main() {
        try! realm.write {
            let objectA = ModelA()
            let objectB = ModelB()
            let objectBB = ModelB()
            
            pkA = randomStringWithLength(10)
            pkB = randomStringWithLength(10)
            pkBB =  randomStringWithLength(10)
            
            objectA.pk = pkA
            objectB.pk = pkB
            objectBB.pk = pkBB
            
            objectA.data = randomStringWithLength(50)
            objectB.data = randomStringWithLength(50)
            objectBB.data = randomStringWithLength(50)
            
            realm.add(objectA)
            realm.add(objectB)
            realm.add(objectBB)
            
            NSLog("Writing objects")
        }
    }

}

class RelationOperation: NSOperation {
    
    // Database reference
    private var realmRef: Realm!
    
    var sourceClassName = ModelA.className()
    var sourceKeyValue = ""
    var targetClassName = ModelB.className()
    var targetKeyValue = ""
    var targetKeyValue2 = ""
    
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
        let target2 =  realm.dynamicObjectForPrimaryKey(targetClassName, key: targetKeyValue2)
        NSLog("src: %@, target: %@", String(source), String(target))
        
        if let source = source, target = target, target2 = target2 {
            try! realm.write {
                let list = source.dynamicList("objects")
                list.append(target)
                list.append(target2)
                
                NSLog("Writing relation")
                
                source["objects"] = list
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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var operations = [RelationOperation]()
    var queue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 8
        queue.qualityOfService = .UserInitiated
        return queue
    }()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        do {
            try NSFileManager.defaultManager().removeItemAtPath(Realm.Configuration.defaultConfiguration.path!)
        } catch {}
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            self.testRealm()
        }
        
        return true
    }
    
    func testRealm() {
        /*do {
            try NSFileManager.defaultManager().removeItemAtPath(Realm.Configuration.defaultConfiguration.path!)
        } catch {}*/
        
        //while (true) {
        for _ in 0..<arc4random_uniform(1000) {
            //let rand = arc4random_uniform(3)
            
            let createOperation = CreateOperation()
            createOperation.completionBlock = {
                let relationOperation = RelationOperation()
                relationOperation.sourceKeyValue = createOperation.pkA!
                relationOperation.targetKeyValue = createOperation.pkB!
                relationOperation.targetKeyValue2 = createOperation.pkBB!
                
                relationOperation.addDependency(createOperation)
                self.queue.addOperation(relationOperation)
            }
            
            queue.addOperation(createOperation)
        }
        
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), Int64(Double(NSEC_PER_SEC) * 0.5))
        dispatch_after(time, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            self.testRealm()
        }
        
        /*
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 4 * Int64(NSEC_PER_SEC))
        dispatch_after(time, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            self.testRealm()
        }*/
    }
}

