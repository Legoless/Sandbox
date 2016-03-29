//
//  ViewController.swift
//  RealmTest
//
//  Created by Dal Rupnik on 14/03/16.
//  Copyright © 2016 Unified Sense. All rights reserved.
//

import RealmSwift
import UIKit

class ViewController: UIViewController {
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    let objectsToTrackCount = 500
    
    var objects : [DynamicObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), Int64(Double(NSEC_PER_SEC) * 0.5))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.fetchModel()
        }
    }
    
    func fetchModel () {
        NSLog("Fetching models...")
        
        let realm = try! Realm()
        realm.refresh()
        
        for _ in 0..<randomInt(20) {
        
            let randomReference = delegate.references[randomInt(delegate.references.count)]
        
            if let object = realm.dynamicObjectForPrimaryKey(randomReference.className, key: randomReference.pk) {
                NSLog("Fetched model: [%@ : %@] Count: %d", randomReference.className, randomReference.pk, objects.count)
                
                if objects.count < objectsToTrackCount {
                    objects.append(object)
                }
            }
        }
        
        if objects.count >= 50 {
            for object in objects {
                object.realm?.refresh()
                NSLog("Object: %@", object)
                //sleep(1)
            }
        }
        
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), Int64(Double(NSEC_PER_SEC) * 0.5))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.fetchModel()
        }
    }

}

