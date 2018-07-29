//
//  AtomicValue.swift
//  HyperTrackCore
//
//  Created by Atul Manwar on 05/07/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public class AtomicValue<T> {
    private var _value: T
    private let semaphore: DispatchSemaphore
    
    public var value: T {
        get {
            semaphore.wait()
            let result = _value
            defer {
                semaphore.signal()
            }
            return result
        }
        set (value) {
            semaphore.wait()
            _value = value
            defer {
                semaphore.signal()
            }
        }
    }
    
    public init(value: T) {
        _value = value
        semaphore = DispatchSemaphore(value: 1)
    }
    
    public func update(_ newValue: T) {
        value = newValue
    }
    
}

extension AtomicValue where T == Int {
    public func updateBy(_ newValue: T) {
        value += newValue
    }
}

