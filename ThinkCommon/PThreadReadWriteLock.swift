//
//  PThreadReadWriteLock.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/5/9.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import Foundation

/// Abstracts a Read/Write lock
public protocol ReadWriteLock {
    /**
     Executes a given closure with a read lock
     
     - parameter body: The code to execute with a read lock
     
     - returns: The result of the given code
     */
    func withReadLock<T>( _ body: () -> T) -> T
    
    /**
     Executes a given closure with a write lock
     
     - parameter body: The code to execute with a write lock
     
     - returns: The result of the given code
     */
    func withWriteLock<T>( _ body: () -> T) -> T
}

/// An implemenation of ReadWriteLock based on pthread, taken from https://github.com/bignerdranch/Deferred
public class PThreadReadWriteLock: ReadWriteLock {
    
    private var lock: UnsafeMutablePointer<pthread_rwlock_t>
    
    /// Instantiates a new read/write lock
    public init() {
        lock = UnsafeMutablePointer.allocate(capacity: 1)
        let status = pthread_rwlock_init(lock, nil)
        assert(status == 0)
    }
    
    deinit {
        let status = pthread_rwlock_destroy(lock)
        assert(status == 0)
        lock.deallocate()
    }
    
    public func withReadLock<T>( _ body: () -> T) -> T {
        pthread_rwlock_rdlock(lock)
        
        defer {
            pthread_rwlock_unlock(lock)
        }
        
        return body()
    }
    
    public func withWriteLock<T>( _ body: () -> T) -> T {
        pthread_rwlock_wrlock(lock)
        
        defer {
            pthread_rwlock_unlock(lock)
        }
        
        return body()
    }
}
