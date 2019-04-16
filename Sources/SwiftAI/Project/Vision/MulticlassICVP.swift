// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class MultiClassICVP : ImageClassificationVP<[String],PythonObject> {

    public var csvFilePath = ""
    public var threshold = 0.5

    override open func getDatasetBuilder() -> DatasetBuilder<URL, [String]> {
        let datasetBuilder = DatasetBuilder<URL, [String]>()
            .withFilesFromFolders(parentFolder: folder, extensions: extensions, trainFolder: trainFolder,
                                  validFolder: validFolder, testFolder: testFolder)
            .withFileLabelsFromCSV(file: csvFilePath)
            .withClasses(classes)
            .withSample(of: .Train, pct: trainingPct, fixed: fixedSamples)
            .withSample(of: .Valid, pct: validPct, fixed: fixedSamples)
            .withSample(of: .Test, pct: testPct, fixed: fixedSamples)

        if !testHasLabels {
            datasetBuilder.withY([classes[0]], type: .Test)
        }

        return datasetBuilder
    }

    override open func getLossFunc() -> LossFunc {
        return { (input: Tensor, target: Tensor) -> Tensor in
            return torch.nn.functional.binary_cross_entropy_with_logits(input, target)
        }
    }

    override open func getTestModel(forModel model: PythonObject) -> PythonObject {
        let sigmoid = nn.Sigmoid()
        return nn.Sequential(model, sigmoid)
    }

    override open func getCallbacks(forModel model: PythonObject) -> [Callback] {
        var callbacks = super.getCallbacks(forModel: model)

        let prepFunc = { (input: Tensor) -> Tensor in
            return torch.sigmoid(input)
        }
        let multiAccuracy = getAccuracyMulti(prepFunc: prepFunc, threshold: threshold)
        let f2 = getF2(prepFunc: prepFunc, threshold: 0.5)

        callbacks.append(AverageMetric(name: "Train Acc.", fn: multiAccuracy, applicable: .Training))
        callbacks.append(AverageMetric(name: "Val. Acc.", fn: multiAccuracy, applicable: .Validation))
        callbacks.append(AverageMetric(name: "Train F2", fn: f2, applicable: .Training))
        callbacks.append(AverageMetric(name: "Val. F2", fn: f2, applicable: .Validation))

        callbacks.append(MetricsCallback(callbacks: callbacks))
        
        return callbacks
    }

    override public func getTestCallback() -> TestCallback<URL,[String]> {
        return MultiClassificationTestCallback(classes: classes, threshold: threshold)
    }

}
