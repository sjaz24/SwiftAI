// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class ObjectDetectionVP<Y>: VisionProject<URL,Y,PythonObject,PythonObject> {

    public var modelZooModel = ModelZooModel.resnet(34, true)
    public var trainCocoJson = ""
    public var validCocoJson = ""
    public var testCocoJson = ""
    public var largestBBoxOnly = false

    override open func getDatasetBuilder() -> DatasetBuilder<URL, Y> {
      let datasetBuilder = DatasetBuilder<URL, Y>()
          .withCocoJson(builderId: "TrainCocoJson", atPath: "\(folder)/\(trainCocoJson)", imagesFolder: "\(folder)/\(trainFolder)",
                        largestBBoxOnly: largestBBoxOnly)
          .withCocoJson(builderId: "ValidCocoJson", atPath: "\(folder)/\(validCocoJson)", imagesFolder: "\(folder)/\(validFolder)", type: .Valid,
                        largestBBoxOnly: largestBBoxOnly)
          .withCocoJson(builderId: "TestCocoJson", atPath: "\(folder)/\(testCocoJson)", imagesFolder: "\(folder)/\(testFolder)", type: .Test,
                        largestBBoxOnly: largestBBoxOnly)
          .withSample(of: .Train, pct: trainingPct, fixed: fixedSamples)
          .withSample(of: .Valid, pct: validPct, fixed: fixedSamples)
          .withSample(of: .Test, pct: testPct, fixed: fixedSamples)

        return datasetBuilder
    }

    override open func getTransforms() -> Transforms<URL,Y,PythonObject,PythonObject> {
        return Transforms<URL, Y, PythonObject, PythonObject>([
          OpenImage(type: imageType),
          NormalizeBoundingBoxes(),
          ResizeImage(size: imageSize),
          PilToTensor(),
          Flip(type: .Horizontal),
          Normalize(divisor: nil, mean: imageMean, std: imageStd)
        ])
    }

    override open func getModel() -> PythonObject {

        let zooModel = getModelZooModel(modelZooModel)
        zooModel.avgpool = sai.Flatten()

        if frozenBackbone {
            freeze(model: zooModel)
        }

        zooModel.fc = getModelHead()

        return zooModel
    }

}