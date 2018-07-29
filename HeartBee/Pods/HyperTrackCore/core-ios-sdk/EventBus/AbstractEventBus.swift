//
//  AbstractEventBus.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 01/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public protocol AbstractEventBus: class {
    func addObserver(_ observer: Any, selector aSelector: Selector, name aName: String)
    func post(name aName: String, userInfo aUserInfo: [AnyHashable : Any]?)
    func removeObserver(_ observer: Any)
    func removeObserver(_ observer: Any, name aName: String)
}

public final class EventBusWrapper {
    internal (set) lazy var center: AbstractEventBus = {
        return NotificationCenterEventBus()
    }()
}

public final class NotificationCenterEventBus {
    fileprivate let center: NotificationCenter
    
    init() {
        center = NotificationCenter.default
    }
}

extension NotificationCenterEventBus: AbstractEventBus {
    public func addObserver(_ observer: Any, selector aSelector: Selector, name aName: String) {
        let notificationName = NSNotification.Name(aName)
        DispatchQueue.main.async {
            self.center.removeObserver(observer, name: notificationName, object: nil)
            self.center.addObserver(observer, selector: aSelector, name: notificationName, object: nil)
        }
    }
    
    public func post(name aName: String, userInfo aUserInfo: [AnyHashable : Any]?) {
        DispatchQueue.main.async {
            self.center.post(name: NSNotification.Name(aName), object: nil, userInfo: aUserInfo)
        }
    }
    
    public func removeObserver(_ observer: Any) {
        DispatchQueue.main.async {
            self.center.removeObserver(observer)
        }
    }
    
    public func removeObserver(_ observer: Any, name aName: String) {
        DispatchQueue.main.async {
            self.center.removeObserver(observer, name: NSNotification.Name(aName), object: nil)
        }
    }
}
