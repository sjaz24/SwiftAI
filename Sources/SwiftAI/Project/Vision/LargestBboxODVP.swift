// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class LargestBBoxODVP: ObjectDetectionVP<BoundingBox> {

    public override init() {
        super.init()

        largestBBoxOnly = true
    }

    override open func getTransforms() -> Transforms<URL,BoundingBox,PythonObject,PythonObject> {
        return super.getTransforms().append(EncodeBoundingBox(classes: classes))
    }

    override open func getModelHead() -> PythonObject {
        let fc = nn.Sequential(nn.ReLU(),
                               nn.BatchNorm1d(25088),
                               nn.Dropout(0.5),
                               nn.Linear(25088, 256),
                               nn.ReLU(),
                               nn.BatchNorm1d(256),
                               nn.Dropout(0.5),
                               nn.Linear(256, 4 + classes.count))

        return fc
    }

    override open func getLossFunc() -> LossFunc {
        return { (input: Tensor, target: Tensor) -> Tensor in
            let targetSplit = torch.split(target, [4, 1], dim: 1)
            let inputSplit = torch.split(input, [4, self.classes.count], dim: 1)

            let l1 = nn.functional.l1_loss(inputSplit[0], targetSplit[0])
            let crossEntropy = nn.functional.cross_entropy(inputSplit[1], targetSplit[1].view(-1).long())
            
            return l1 + crossEntropy
        }
    }

    override open func getCallbacks(forModel model: PythonObject) -> [Callback] {
        var callbacks = super.getCallbacks(forModel: model)

        let accuracyPrepFunc = { (input: Tensor) -> Tensor in
            return nn.functional.softmax(input, dim:1)
        }
        let labelAccuracy = getLargestBBoxLabelAccuracy(prepFunc: accuracyPrepFunc, numClasses: classes.count)
        callbacks.append(AverageMetric(name: "Train Acc.", fn: labelAccuracy, applicable: .Training))
        callbacks.append(AverageMetric(name: "Val. Acc.", fn: labelAccuracy, applicable: .Validation))

        let bboxOverlap = getLargestBBoxOverlap(numClasses: classes.count, imageSize: imageSize) 
        callbacks.append(AverageMetric(name: "Train IoU", fn: bboxOverlap, applicable: .Training))
        callbacks.append(AverageMetric(name: "Val. IoU", fn: bboxOverlap, applicable: .Validation))

        callbacks.append(MetricsCallback(callbacks: callbacks))
        
        return callbacks
    }

    override public func getTestCallback() -> TestCallback<URL,BoundingBox> {
        return LargestBoundingBoxTestCallback(classes: classes, imageSize: imageSize)
    }
}