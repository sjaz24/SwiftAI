// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class ImageClassificationVP<Y,V:PythonConvertible> : VisionProject<URL,Y,PythonObject,V> {

    public var modelZooModel = ModelZooModel.resnet(34, true)

    public override init() {
        super.init()

        xPushMapper = { $0.absoluteString }
        xPopMapper = { URL(fileURLWithPath: $0) }
    }

    override open func getTransforms() -> Transforms<URL,Y,PythonObject,V> {
        return Transforms<URL,Y,PythonObject,V>([
            OpenImage(type: imageType),
            ResizeImage(size: imageSize),
            PilToTensor(),
            Normalize(divisor: nil, mean: imageMean, std: imageStd),
            Flip(type: .Horizontal),
            ClassLabelToInt(classes: classes)
        ])
    }

    override open func getModel() -> PythonObject {

        let zooModel = getModelZooModel(modelZooModel)
        zooModel.avgpool = nn.AdaptiveAvgPool2d(PythonObject(tupleOf: 1, 1))

        if frozenBackbone {
            freeze(model: zooModel)
        }

        let head = getModelHead()
        let model = torch.nn.Sequential(zooModel, head)

        return model
    }

    override open func getModelHead() -> PythonObject {
        let fc = nn.Sequential(nn.ReLU(),
                               nn.BatchNorm1d(1000),
                               nn.Dropout(0.5),
                               nn.Linear(1000, 256),
                               nn.ReLU(),
                               nn.BatchNorm1d(256),
                               nn.Dropout(0.5),
                               nn.Linear(256, classes.count))

        return fc
    }

}
