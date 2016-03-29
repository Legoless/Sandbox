//
//  AppDelegate.swift
//  RealmTest
//
//  Created by Dal Rupnik on 14/03/16.
//  Copyright © 2016 Unified Sense. All rights reserved.
//

import UIKit
import RealmSwift

class ModelA: Object {
    dynamic var pk : String?
    dynamic var data : String?
    
    let objectsB = List<ModelB>()
    let objectsC = List<ModelC>()
    let objectsD = List<ModelD>()
    
    override class func primaryKey() -> String? {
        return "pk"
    }
}

class ModelB: Object {
    dynamic var pk : String?
    dynamic var data : String?
    
    dynamic var parent: ModelA?
    
    let objectsE = List<ModelE>()
    
    override class func primaryKey() -> String? {
        return "pk"
    }
}

class ModelC: Object {
    dynamic var pk : String?
    dynamic var data : String?
    override class func primaryKey() -> String? {
        return "pk"
    }
}

class ModelD: Object {
    dynamic var pk : String?
    dynamic var data : String?
    dynamic var objectC : ModelC?
    
    override class func primaryKey() -> String? {
        return "pk"
    }
}

class ModelE: Object {
    dynamic var pk : String?
    dynamic var data : String?
    override class func primaryKey() -> String? {
        return "pk"
    }
}

///
/// Object mapping for temporary generation
///
let classes = [ "ModelA", "ModelB", "ModelC", "ModelD", "ModelE" ]
let relations = [ "ModelA" : [ [ "objectsB" : "ModelB" ], [ "objectsC" : "ModelC"], ["objectsD" : "ModelD"] ], "ModelB" : [ ["objectsE" : "ModelE"], ["parent" : "ModelA"] ], "ModelD" : [ ["objectC" : "ModelC"] ] ]


struct ModelReference {
    var className : String
    var pk : String
    var related : Bool
}

func relationForReference (reference: ModelReference, references: [ModelReference]) -> RelationOperation? {
    let relation = RelationOperation()
    relation.sourceClassName = reference.className
    relation.sourceKeyValue = reference.pk
    
    //
    // Pick a random relation for the current source
    //
    
    if let possibleRelations = relations[relation.sourceClassName] where possibleRelations.count > 0 && references.count > 0 {
        let randomRelation = possibleRelations[randomInt(possibleRelations.count)]
        
        relation.sourcePropertyName = randomRelation.keys.first!
        
        // Search for an object that matches the relation
        
        let objects = references.filter { $0.className == randomRelation.values.first! }
        
        if objects.count > 0 {
            let randomReference = objects[randomInt(objects.count)]
            relation.targetClassName = randomReference.className
            relation.targetKeyValue = randomReference.pk
            
            return relation
        }
    }
    
    return nil
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
    
    var references : [ModelReference] = []

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        do {
            try NSFileManager.defaultManager().removeItemAtPath(Realm.Configuration.defaultConfiguration.path!)
        } catch {}
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            self.testRealm(1000)
        }
        
        return true
    }
    
    func testRealm(number: Int) {
        /*do {
            try NSFileManager.defaultManager().removeItemAtPath(Realm.Configuration.defaultConfiguration.path!)
        } catch {}*/
        
        for _ in 0 ..< arc4random_uniform(UInt32(number)) {
            let rand = Int(arc4random_uniform(UInt32(classes.count)))
            
            let createOperation = CreateOperation(className: classes[rand])
            createOperation.completionBlock = {
                self.references.append(createOperation.reference!)
            }
            
            queue.addOperation(createOperation)
        }
        
        // Pick a random object from pool and generate a relation

        var counter = 0
        let count = Int(arc4random_uniform(UInt32(number)))
        
        let nonrelatedReferences = references.filter { $0.related == false }
        
        while counter < min(count, nonrelatedReferences.count) {
            var nonrelatedReference = nonrelatedReferences[counter]
            
            if let relationOperation = relationForReference(nonrelatedReference, references: references) {
                relationOperation.completionBlock = {
                    nonrelatedReference.related = true
                }
                
                self.queue.addOperation(relationOperation)
            }
            
            counter += 1
        }
        
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), Int64(Double(NSEC_PER_SEC) * 0.5))
        dispatch_after(time, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            self.testRealm(number)
        }
        
        /*
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 4 * Int64(NSEC_PER_SEC))
        dispatch_after(time, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            self.testRealm()
        }*/
    }
}

