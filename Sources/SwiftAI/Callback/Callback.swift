// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

public enum CallbackKey {
    case epoch, iteration, numBatch, nEpochs, lastInput, lastTarget, train
    case lastOutput, lastLoss, smoothLoss, lastMetrics
}

public enum CallbackApplicable {
    case Training, Validation, All
}

open class Callback {

    let order: Int
    let applicable: CallbackApplicable

    public init(order: Int = 0, applicable: CallbackApplicable = .All) { 
        self.order = order
        self.applicable = applicable
    }

    open func onTrainBegin(state: [CallbackKey: Any]) { }

    open func onEpochBegin(state: [CallbackKey: Any]) { }

    open func onBatchBegin(state: [CallbackKey: Any]) -> (Tensor, Tensor)? { return nil }

    open func onLossBegin(state: [CallbackKey: Any]) -> Tensor? { return nil }

    open func onBackwardBegin(state: [CallbackKey: Any]) -> Tensor? { return nil }

    open func onBackwardEnd(state: [CallbackKey: Any]) { }

    open func onStepEnd(state: [CallbackKey: Any]) { }

    open func onBatchEnd(state: [CallbackKey: Any]) -> Bool { return false }

    open func onEpochEnd(state: [CallbackKey: Any]) -> Bool { return false }

    open func onTrainEnd(state: [CallbackKey: Any]) { }

}