//
//  Filter.swift
//  CoreImageTest
//
//  Created by Jia Jing on 6/26/15.
//  Copyright © 2015 Jia Jing. All rights reserved.
//

import Foundation
import CoreImage
import Swift


protocol Filter {
    func filter(filter : ConcreteFilter) -> ConcreteFilter
}


protocol FilterGroup : Filter {
    func subFilters() -> [Filter]
}

extension FilterGroup {
    func filter(filter: ConcreteFilter) -> ConcreteFilter {
        let sf = subFilters();
        guard sf.count > 0 else { return filter }
        guard sf.first is ConcreteFilter else { return filter }
        guard sf.count > 1 else { return sf.first!.filter(filter) }
        return sf[1..<sf.count].reduce(sf.first as! ConcreteFilter){ $1.filter($0) }.filter(filter)
    }
}

protocol ConcreteFilter : Filter {
    func reify() -> CIImage
}

protocol SourceFilter : ConcreteFilter {
    
}

extension  SourceFilter {
    func filter(filter : ConcreteFilter) -> ConcreteFilter {
        return self
    }
}

protocol Updatable {
    func update()
}

protocol Timed : Updatable {
    func setTimeProvider(timeProvider : TimeProvider)
}

protocol TimeProvider {
    func provideTime() -> Double
}

protocol Syncable : Updatable{
    func getSynced() -> Synced
    func notifyUpdated()
}

extension Syncable {
    func notifyUpdated() {
        getSynced().notifyUpdated()
    }
}

struct Synced : Hashable {
    let identifier : String
    var syncedUpon : SynchronizedUpon?{
        willSet(newSyncedUpon){
            if let oldSyncedUpon = syncedUpon where newSyncedUpon !== syncedUpon { oldSyncedUpon.unregisterSynced(self) }
            if let newSyncedUpon = newSyncedUpon { newSyncedUpon.registerSynced(self) }
        }
    }
    var hashValue : Int{
        return identifier.hashValue
    }
    func notifyUpdated() -> Bool{
        return syncedUpon?.notifyUpdated(self) ?? false
    }
}

func ==(lhs : Synced, rhs : Synced) -> Bool{
    return lhs.identifier == rhs.identifier
}

class SynchronizedUpon{
    let onSynchronized : (Void -> Void)?
    var isSynchronized = [Synced : Bool]()
    
    init(onSynchronized : (Void -> Void)?){
        self.onSynchronized = onSynchronized
    }
    
    func manageSyncable(syncable : Syncable) {
        registerSynced(syncable.getSynced())
    }
    
    func registerSynced(synced : Synced) {
        isSynchronized.updateValue(isSynchronized[synced] ?? false, forKey: synced)
    }
    
    func unregisterSynced(synced : Synced){
        guard isSynchronized.removeValueForKey(synced) != nil else { return }
        isSynced()
    }
    
    func notifyUpdated(synced : Synced) -> Bool{
        guard isSynchronized[synced] != nil else { return false }
        isSynchronized.updateValue(true, forKey: synced)
        return isSynced()
    }
    
    func isSynced() -> Bool{
        guard isSynchronized.reduce(true, combine : {$0 && $1.1}) else { return false }
        for key in isSynchronized.keys { isSynchronized[key] = false }
        onSynchronized?()
        return true
    }
}