// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

class CallbackHandler {

    private var callbacks: [Callback]
    private var state: [CallbackKey: Any]
    private let beta: Double
    private let smoothener: SmoothenValue

    init(callbacks: [Callback] = [Callback](), beta: Double = 0.98) {
        self.callbacks = callbacks.sorted { $0.order > $1.order }
        self.beta = beta
        state = CallbackHandler.getInitState()
        smoothener = SmoothenValue(beta: self.beta)
    }

    private class func getInitState() -> [CallbackKey: Any] {
        return [.epoch: 0, .iteration: 0, .numBatch: 0]
    }

    private func isApplicable(cb: Callback, train: Bool) -> Bool {
        if cb.applicable == .All || 
           (train && cb.applicable == .Training) ||
           (!train && cb.applicable == .Validation) {
            return true
        }

        return false
    }
    
    private func forEachBatchCb(_ exec: (Callback) -> () ) {
        let train = state[.train] as! Bool
        for cb in callbacks where isApplicable(cb: cb, train: train) {
            exec(cb)
        }
    }

    private func forEachCb(_ exec: (Callback) -> () ) {
        for cb in callbacks {
            exec(cb)
        }
    }

    func onTrainBegin(epochs: Int) {
        state = CallbackHandler.getInitState()
        state[.nEpochs] = epochs
        forEachCb { $0.onTrainBegin(state: state) }
    }
    
    func onEpochBegin() {
        state[.numBatch] = 0
        forEachCb { $0.onEpochBegin(state: state) }
    }

    func onBatchBegin(xb: Tensor, yb: Tensor, train: Bool = true) -> (Tensor, Tensor) {
        state[.lastInput] = xb
        state[.lastTarget] = yb
        state[.train] = train
        forEachBatchCb { 
            if let (xb, yb) = $0.onBatchBegin(state: state) {
                state[.lastInput] = xb
                state[.lastTarget] = yb
            }
        }

        return (state[.lastInput] as! Tensor, state[.lastTarget] as! Tensor)
    }
    
    func onLossBegin(out: Tensor) -> Tensor {
        state[.lastOutput] = out
        forEachBatchCb {
            if let out = $0.onLossBegin(state: state) {              
                state[.lastOutput] = out
            }
        }
        return state[.lastOutput] as! Tensor
    }

    func onBackwardBegin(loss: Tensor) -> Tensor {
        smoothener.addValue(Double(loss.detach())!)
        state[.lastLoss] = loss
        state[.smoothLoss] = smoothener.smooth
        forEachBatchCb { 
            if let loss = $0.onBackwardBegin(state: state) {
                state[.lastLoss] = loss
            }
        }

        return state[.lastLoss] as! Tensor
    }

    func onBackwardEnd() {
        forEachBatchCb { $0.onBackwardEnd(state: state) }
    }

    func onStepEnd() {
        forEachBatchCb { $0.onStepEnd(state: state) }
    }

    func onBatchEnd(loss: Tensor) -> Bool {
        state[.lastLoss] = loss
        var stop = false
        forEachBatchCb {
            if $0.onBatchEnd(state: state) {
                stop = true
            }
        }

        state[.iteration] = state[.iteration] as! Int + 1
        state[.numBatch] = state[.numBatch] as! Int + 1

        return stop
    }

    func onEpochEnd(valLoss: [Tensor]) -> Bool {
        state[.lastMetrics] = valLoss
        state[.epoch] = state[.epoch] as! Int + 1
        var stop = false
        forEachCb {
            if $0.onEpochEnd(state: state) {
                stop = true
            }
        }

        return stop
    }

    func onTrainEnd() {
        forEachCb { $0.onTrainEnd(state: state) }
    }

}