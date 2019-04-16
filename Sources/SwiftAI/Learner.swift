// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class Learner<X,Y,U:PythonConvertible,V:PythonConvertible> {
    public var learningRate: Double
    public var dataLoaders: DataLoaderSet<X,Y,U,V>
    public var model: PythonObject
    public var optimizer: PythonObject
    public var lossFunc: LossFunc?
    public var callbacks: [Callback]?
    public var testModel: PythonObject
    public var testCallback: TestCallback<X,Y>?

    public init(dataLoaders: DataLoaderSet<X,Y,U,V>, model: PythonObject, 
                lossFunc: LossFunc?, optimizer: PythonObject, 
                learningRate: Double = 0.01, callbacks: [Callback]? = nil,
                testModel: PythonObject? = nil, testCallback: TestCallback<X,Y>? = nil) {
        self.dataLoaders = dataLoaders
        self.model = model
        self.optimizer = optimizer
        self.lossFunc = lossFunc
        self.learningRate = learningRate
        self.callbacks = callbacks
        self.testModel = testModel ?? model
        self.testCallback = testCallback
    }

    public func train(epochs: Int = 1) {
        let opt = optimizer(model.parameters(), lr: self.learningRate)
        fit(epochs: epochs, model: model, lossFunc: lossFunc!, opt: opt, dataLoaders: dataLoaders,
            callbacks: callbacks ?? [Callback]()) 
    }

    public func test(useValidDl: Bool = false) {
        let dataLoader: DataLoader<X,Y,U,V>
        if useValidDl {
            guard let validDl = dataLoaders.validDl else {
                print("Error: Can not test against validation set. DataLoaderSet does not contain a validation dataloader.")
                return
            }
            dataLoader = validDl
        } else {
            guard let testDl = dataLoaders.testDl else {
                print("Error: Can not test against test set. DataLoaderSet does not contain a test dataloader.")
                return
            }
            dataLoader = testDl
        }

        predict(model: testModel, dataLoader: dataLoader, callback: testCallback ?? TestCallback<X,Y>())
    }

}