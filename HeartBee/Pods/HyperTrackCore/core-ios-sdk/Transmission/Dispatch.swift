//
//  Dispatch.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 04/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public protocol AbstractDispatch: class {
    func dispatch()
}

public final class Dispatch {
    fileprivate weak var eventBus: AbstractEventBus?
    fileprivate weak var config: AbstractDispatchConfig?
    fileprivate weak var transmission: AbstractPipeline?
    fileprivate var strategy: AbstractDispatchStrategy?
    fileprivate var context: AbstractDispatchStrategyContext?
    fileprivate var type: Config.Dispatch.DispatchType
    
    public init(eventBus: AbstractEventBus?, config: AbstractDispatchConfig?, context: AbstractDispatchStrategyContext?, transmission: AbstractPipeline?) {
        self.eventBus = eventBus
        self.config = config
        self.context = context
        self.transmission = transmission
        type = config?.dispatch.type ?? .manual
        self.strategy = context?.getDispatchStrategy(self, config: config)
        self.eventBus?.addObserver(self, selector: #selector(heartBeatStatusChanged(_ :)), name: Constant.Notification.HeartbeatService.StatusChangedEvent.name)
        self.eventBus?.addObserver(self, selector: #selector(dispatchTypeChanged(_ :)), name: Constant.Notification.Dispatch.TypeChangedEvent.name)
        self.eventBus?.addObserver(self, selector: #selector(dataAvailable(_ :)), name: Constant.Notification.Database.DataAvailableEvent.name)
        self.eventBus?.addObserver(self, selector: #selector(transmissionDone(_ :)), name: Constant.Notification.Transmission.DataSentEvent.name)
    }
    
    @objc func dispatchTypeChanged(_ notification: Notification) {
        guard let value = notification.userInfo?[Constant.Notification.Dispatch.TypeChangedEvent.key] as? Int, let type = Config.Dispatch.DispatchType(rawValue: value) else { return }
        if type != self.type {
            strategy = context?.getDispatchStrategy(self, config: config)
            self.type = type
        }
    }
    
    @objc func dataAvailable(_ notification: Notification) {
        guard let value = notification.userInfo?[Constant.Notification.Database.DataAvailableEvent.key] as? EventCollectionType, value == .online else { return }
        strategy?.start()
    }
    
    @objc func transmissionDone(_ notification: Notification) {
        strategy?.stop()
    }
    
    @objc func heartBeatStatusChanged(_ notification: Notification) {
        guard let value = notification.userInfo?[Constant.Notification.HeartbeatService.StatusChangedEvent.key] as? HeartbeatService.Status, !value.isConnected else { return }
        strategy?.stop()
    }
}

extension Dispatch: AbstractDispatch {
    public func dispatch() {
        transmission?.execute(completionHandler: nil)
    }
}

public protocol AbstractDispatchStrategy {
    var dispatch: AbstractDispatch? { get }
    func start()
    func stop()
    func updateConfig(_ config: AbstractDispatchConfig?)
}

public protocol AbstractDispatchStrategyContext {
    func getDispatchStrategy(_ dispatch: AbstractDispatch, config: AbstractDispatchConfig?) -> AbstractDispatchStrategy?
}

final class DispatchStrategyContext: AbstractDispatchStrategyContext {
    func getDispatchStrategy(_ dispatch: AbstractDispatch, config: AbstractDispatchConfig?) -> AbstractDispatchStrategy? {
        guard let config = config else { return nil }
        switch config.dispatch.type {
        case .timer:
            return TimerDispatchStrategy(dispatch: dispatch, config: config)
        default:
            return nil
        }
    }
}

final class TimerDispatchStrategy: AbstractDispatchStrategy {
    weak var dispatch: AbstractDispatch?
    var timer: Repeater?
    var debouncer: Debouncer?
    var frequency: Double {
        return config?.dispatch.frequency ?? Constant.Config.Dispatch.frequency
    }
    var debounce: Double {
        return config?.dispatch.debounce ?? Constant.Config.Dispatch.debounce
    }
    var tolerance: Int {
        return config?.dispatch.tolerance ?? Constant.Config.Dispatch.tolerance
    }
    fileprivate weak var config: AbstractDispatchConfig?
    
    init(dispatch: AbstractDispatch?, config: AbstractDispatchConfig?) {
        self.dispatch = dispatch
        self.config = config
        timer = Repeater(interval: Repeater.Interval.seconds(frequency), mode: .infinite, tolerance: .seconds(tolerance), queue: DispatchQueue.global(qos: .background)) { [weak self] _ in
            self?.dispatch?.dispatch()
        }
        debouncer = Debouncer(Repeater.Interval.seconds(debounce), callback: { [weak self] in
            self?.timer?.start()
        })
    }
    
    func start() {
        debouncer?.call()
    }
    
    func stop() {
        timer?.pause()
    }
    
    func updateConfig(_ config: AbstractDispatchConfig?) {
        guard frequency != config?.dispatch.frequency else { return }
        self.config = config
        timer?.reset(Repeater.Interval.seconds(frequency), restart: false)
    }
    
    deinit {
        timer?.removeAllObservers(thenStop: true)
    }
}
