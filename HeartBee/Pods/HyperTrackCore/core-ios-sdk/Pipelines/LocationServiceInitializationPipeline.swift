//
//  LocationServiceInitializationPipeline.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 12/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public protocol AbstractLocationServiceInitializationPipeline: AbstractPipeline {
}

public final class LocationServiceInitializationPipeline {
    fileprivate weak var config: AbstractLocationConfig?
    fileprivate let stepOne: AbstractPipelineStep<Void, Bool>
    weak var serviceManager: AbstractServiceManager?
    public var context: Int {
        return Constant.Context.location
    }
    public var isExecuting: Bool = false
    
    public init(config: AbstractLocationConfig?, serviceManager: AbstractServiceManager?) {
        self.config = config
        self.serviceManager = serviceManager
        stepOne = LocationPermissionStep(serviceManager: serviceManager)
    }
}

extension LocationServiceInitializationPipeline: AbstractLocationServiceInitializationPipeline {
    public func execute(completionHandler: ((CoreError?) -> Void)?) {
        setState(.executing)
        stepOne.execute(input: ())
            .continueWith { [weak self] (task) in
                if task.result == true {
                    self?.setState(.success)
                }
                DispatchQueue.main.async {
                    completionHandler?(task.error as? CoreError ?? nil)
                    guard let error = task.error else { return }
                    self?.setState(.failure(error))
                }
            }
    }
}
