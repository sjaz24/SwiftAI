// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit
import CSV

open class VisionProject<X,Y,U:PythonConvertible,V:PythonConvertible>: Project {

    public var folder = "."
    public var trainFolder = "train"
    public var validFolder = "valid"
    public var testFolder = "test"
    public var testHasLabels = false
    public var extensions: Set<String>  = ["jpg","png","bmp"]
    public var trainingPct = 1.0
    public var validPct = 1.0
    public var testPct = 1.0
    public var fixedSamples = false
    public var imageType = "RGB"
    public var imageSize = (width: 224, height: 224)
    public var imageMean = [0.485, 0.456, 0.406]
    public var imageStd = [0.229, 0.224, 0.225]
    public var classes = [String]()
    public var frozenBackbone = true
    public var saveModel = true
    public var savedModelPath = "./model.pth"
    public var optimizer = torch.optim.SGD
    public var queue = ""
    public var xPushMapper: ((X) -> String)?
    public var yPushMapper: ((Y) -> String)?
    public var xPopMapper: ((String) -> X)?
    public var yPopMapper: ((String) -> Y)?

    open func getDatasetBuilder() -> DatasetBuilder<X,Y> {
        fatalError("Must override!")
    }

    open func getTransforms() -> Transforms<X,Y,U,V> {
        fatalError("Must override!")
    }

    open func getModel() -> PythonObject {
        fatalError("Must override!")
    }

    open func getModelHead() -> PythonObject {
        fatalError("Must override")
    }

    open func getSavedModel() -> PythonObject {
        let model = getModel()

        if saveModel {
            if FileManager.default.fileExists(atPath: savedModelPath) {
                model.load_state_dict(torch.load(savedModelPath))
            }
        }

        return model
    }

    open func getLossFunc() -> LossFunc {
        fatalError("Must override")
    }

    open func getTestModel(forModel model: PythonObject) -> PythonObject {
        return model
    }

    open func getCallbacks(forModel model: PythonObject) -> [Callback] {
        var callbacks = [Callback]()

        callbacks.append(LossMetric())
        callbacks.append(LossMetric(name: "Val. Loss", applicable: .Validation))
    
        if saveModel {
            callbacks.append(SaveModel(model: model, filePath: savedModelPath))
        }

        return callbacks
    }

    open func getTestCallback() -> TestCallback<X,Y> {
        return TestCallback<X,Y>()
    }

    open func printSummary(dataLoaders: DataLoaderSet<X,Y,U,V>) {
        print()
        print("Learning Rate : \(learningRate)")
        print("Batch Size    : \(batchSize)")
        print("Batches")
        print("- Training    : \(dataLoaders.trainDl?.len() ?? 0)")
        print("- Validation  : \(dataLoaders.validDl?.len() ?? 0)")
        print("- Test        : \(dataLoaders.testDl?.len() ?? 0)")
        print()
    }

    open func learner() -> Learner<X,Y,U,V> {
        let datasetBuilder = getDatasetBuilder()
        let datasets = datasetBuilder.build()
        if classes.count == 0 {
          classes = datasetBuilder.classes!
        }
        let transforms = getTransforms()
        let dataLoaders = DataLoaderSet(datasets: datasets, bs: batchSize, transforms: transforms)
        let model = getSavedModel()
        let lossFunc = getLossFunc()
        let testModel = getTestModel(forModel: model)
        let callbacks = getCallbacks(forModel: model)
        let testCallback = getTestCallback()

        printSummary(dataLoaders: dataLoaders)

        return Learner(dataLoaders: dataLoaders, model: model, lossFunc: lossFunc, optimizer: optimizer,
                       learningRate: learningRate, callbacks: callbacks, testModel: testModel,
                       testCallback: testCallback)
    }

    override open func train(epochs: Int = 1) {
        learner().train(epochs: epochs)
    }

    override open func test(useValidDl: Bool = false) {
        learner().test(useValidDl: useValidDl)
    }

    override open func startRedisLoading() {
        let datasetBuilder = getDatasetBuilder()
        let datasets = datasetBuilder.build()
        if classes.count == 0 {
          classes = datasetBuilder.classes!
        }
        let transforms = getTransforms()
        let dataLoaders = DataLoaderSet(datasets: datasets, bs: batchSize, transforms: transforms)

        printSummary(dataLoaders: dataLoaders)

        let redisDataPusher = RedisDataPusher(queue: queue, dataLoaders: dataLoaders,
                                              xMapper: xPushMapper, yMapper: yPushMapper)
        redisDataPusher.start()
    }

    open func redisLearner(train: Bool = true, valid: Bool = true, test: Bool = true) -> Learner<X,Y,U,V> {
        let dataLoaders = DataLoaderSet<X,Y,U,V>(queue: queue, train: train, valid: valid, test: test,
                                                 xMapper: xPopMapper, yMapper: yPopMapper)
        let model = getSavedModel()
        let lossFunc = getLossFunc()
        let testModel = getTestModel(forModel: model)
        let callbacks = getCallbacks(forModel: model)
        let testCallback = getTestCallback()

        return Learner(dataLoaders: dataLoaders, model: model, lossFunc: lossFunc, optimizer: optimizer,
                       learningRate: learningRate, callbacks: callbacks, testModel: testModel,
                       testCallback: testCallback)
    }

    override open func redisTrain(epochs: Int = 1, train: Bool = true, valid: Bool = true) {
        redisLearner(train: train, valid: valid, test: false).train(epochs: epochs)
    }

    override open func redisTest(useValidDl: Bool = false) {
        redisLearner(test: true).test(useValidDl: useValidDl)
    }

}