// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class SingleClassICVP : ImageClassificationVP<String,Int> {

    override open func getDatasetBuilder() -> DatasetBuilder<URL, String> {
        let datasetBuilder = DatasetBuilder<URL, String>()
            .withFilesFromFolders(parentFolder: folder, extensions: extensions, trainFolder: trainFolder,
                                  validFolder: validFolder, testFolder: testFolder)
            .withFileLabelsOfParentFolder(includeTest: testHasLabels)
            .withClasses(classes)
            .withSample(of: .Train, pct: trainingPct, fixed: fixedSamples)
            .withSample(of: .Valid, pct: validPct, fixed: fixedSamples)
            .withSample(of: .Test, pct: testPct, fixed: fixedSamples)

        if !testHasLabels {
            datasetBuilder.withY(classes[0], type: .Test)
        }

        return datasetBuilder
    }

    override open func getLossFunc() -> LossFunc {
        return { (input: Tensor, target: Tensor) -> Tensor in
            return nn.functional.cross_entropy(input, target)
        }
    }

    override open func getTestModel(forModel model: PythonObject) -> PythonObject {
        let softmax = nn.Softmax(dim: 1)
        return nn.Sequential(model, softmax)
    }

    override open func getCallbacks(forModel model: PythonObject) -> [Callback] {
        var callbacks = super.getCallbacks(forModel: model)

        let prepFunc = { (input: Tensor) -> Tensor in
            return nn.functional.softmax(input, dim:1)
        }
        let accuracy = getAccuracy(prepFunc: prepFunc)
        callbacks.append(AverageMetric(name: "Train Acc.", fn: accuracy, applicable: .Training))
        callbacks.append(AverageMetric(name: "Val. Acc.", fn: accuracy, applicable: .Validation))

        callbacks.append(MetricsCallback(callbacks: callbacks))

        return callbacks
    }

    override public func getTestCallback() -> TestCallback<URL,String> {
        return SingleClassificationTestCallback(classes: classes)
    }

}
