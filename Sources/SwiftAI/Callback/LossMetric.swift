// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

public class LossMetric: Callback, Metric {

    public let name: String
    public var count = 0
    public var total = 0.0
    public var value = 0.0

    public init(name: String = "Train Loss", order: Int = 0, applicable: CallbackApplicable = .Training) {
        self.name = name

        super.init(order: order, applicable: applicable)
    }

    override public func onEpochBegin(state: [CallbackKey: Any]) {
        (count, total, value) = (0, 0.0, 0.0)
    }

    override public func onBatchEnd(state: [CallbackKey: Any]) -> Bool {
        let lastOutput = (state[.lastOutput] as! Tensor).detach()
        let lastOutputSize = Int(lastOutput.size(0))!
        let lastLoss = state[.lastLoss]

        count += lastOutputSize
        total += Double(lastOutputSize) * Double(lastLoss as! PythonObject)!
        value = total / Double(count)
        
        return false
    }

}