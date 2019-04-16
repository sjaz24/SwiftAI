// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit
import Foundation

fileprivate func lossBatch(model: PythonObject, xb: Tensor, yb: Tensor, lossFunc: LossFunc,
                           opt: PythonObject? = nil, cbHandler: CallbackHandler = CallbackHandler())
                           -> PythonObject {
    var out = model(xb)
    out = cbHandler.onLossBegin(out: out)
    var loss = lossFunc(out, yb)
    if let opt = opt {
        loss = cbHandler.onBackwardBegin(loss: loss)
        loss.backward()
        cbHandler.onBackwardEnd()
        opt.step()
        cbHandler.onStepEnd()
        opt.zero_grad()
    }

    return loss.detach().cpu()
}

public func withTorchNoGrad(_ exec: () -> ()) {
    let prev = torch.is_grad_enabled()
    do {
        torch.set_grad_enabled(false)
        defer {
            torch.set_grad_enabled(prev)
        }
        exec()
    }
}

fileprivate func validate<X,Y,U:PythonConvertible,V:PythonConvertible>(model: PythonObject,
                                                                       dl: DataLoader<X,Y,U,V>,
                                                                       lossFunc: LossFunc,
                                                                       cbHandler: CallbackHandler = CallbackHandler())
                                                                       -> [Tensor] {
    var losses = [Tensor]()
    losses.reserveCapacity(dl.len())

    model.eval()
    withTorchNoGrad {
        for batch in dl.iterator() {
            var (xb, yb) = batch.1.tuple2
            (xb, yb) = cbHandler.onBatchBegin(xb: xb, yb: yb, train: false)

            let loss = lossBatch(model: model, xb: xb, yb: yb, lossFunc: lossFunc, cbHandler: cbHandler)
            losses.append(loss)

            if cbHandler.onBatchEnd(loss: loss) {
                break
            }
        }
    }

    return losses
}

public func fit<X,Y,U:PythonConvertible,V:PythonConvertible>(epochs: Int, model: PythonObject,
                                                             lossFunc: LossFunc, opt: PythonObject,
                                                             dataLoaders: DataLoaderSet<X,Y,U,V>,
                                                             callbacks: [Callback] = [Callback]()) {
    let cbHandler = CallbackHandler(callbacks: callbacks)
    cbHandler.onTrainBegin(epochs: epochs)

    for _ in 1...epochs {
        model.train()
        cbHandler.onEpochBegin()

        if let trainDl = dataLoaders.trainDl {
            for batch in trainDl.iterator() {
                var (xb, yb) = batch.1.tuple2
                (xb, yb) = cbHandler.onBatchBegin(xb: xb, yb: yb)
                let loss = lossBatch(model: model, xb: xb, yb: yb, lossFunc: lossFunc, opt: opt,
                                     cbHandler: cbHandler)
                if cbHandler.onBatchEnd(loss: loss) {
                    return
                }
            }
        }

        var valLoss = [Tensor]()
        if let validDl = dataLoaders.validDl {
            valLoss = validate(model: model, dl: validDl, lossFunc: lossFunc,
                               cbHandler: cbHandler)
        }

        if cbHandler.onEpochEnd(valLoss: valLoss) {
            break
        }
    }

    cbHandler.onTrainEnd()
}

public func predict<X,Y,U:PythonConvertible,V:PythonConvertible>(model: PythonObject,
                                                                 dataLoader: DataLoader<X,Y,U,V>,
                                                                 callback: TestCallback<X,Y>) {
    callback.onTestBegin(size: dataLoader.dataset.len())
    model.eval()
    withTorchNoGrad {
        for batch in dataLoader.iterator() {
            let (xb, _) = batch.1.tuple2
            let out = model(xb)
            callback.onBatchResults(batch: batch, output: out)
        }
    }
    callback.onTestEnd()
}
