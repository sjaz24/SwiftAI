// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

public class AverageMetric: Callback, Metric {

    public let name: String
    public let fn: (Tensor, Tensor) -> Tensor
    public var count = 0
    public var total = 0.0
    public var value = 0.0

    public init(name: String, fn: @escaping (Tensor, Tensor) -> Tensor, 
                order: Int = 0, applicable: CallbackApplicable = .Validation) {
        (self.name, self.fn) = (name, fn)

        super.init(order: order, applicable: applicable)
    }

    override public func onEpochBegin(state: [CallbackKey: Any]) {
        (count, total, value) = (0, 0.0, 0.0)
    }

    override public func onBatchEnd(state: [CallbackKey: Any]) -> Bool {
        let lastTarget = (state[.lastTarget] as! Tensor).detach()
        let lastOutput = (state[.lastOutput] as! Tensor).detach()
        let lastTargetSize = Int(lastTarget.size(0))!
        let fnValue = fn(lastOutput, lastTarget).item()

        count += lastTargetSize
        total += Double(lastTargetSize) * Double(fnValue)!
        value = total / Double(count)
        
        return false
    }

}