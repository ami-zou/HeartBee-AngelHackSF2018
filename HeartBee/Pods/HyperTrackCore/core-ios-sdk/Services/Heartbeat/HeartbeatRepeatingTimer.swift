//
//  HeartbeatRepeatingTimer.swift
//  HyperTrackCore
//
//  Created by Ashish Asawa on 20/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

final class HeartbeatRepeatingTimer {
    var timeInterval: TimeInterval
    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }
    private lazy var timer: DispatchSourceTimer = {
        let timerSource = DispatchSource.makeTimerSource()
        timerSource.schedule(deadline: .now(), repeating: self.timeInterval)
        timerSource.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return timerSource
    }()
    var eventHandler: (() -> Void)?
    private enum State {
        case suspended
        case resumed
    }
    private var state: State = .suspended
    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }
    
    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
    func reset(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
        timer.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        resume()
    }
}

