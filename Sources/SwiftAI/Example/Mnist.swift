// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class Mnist : SingleClassICVP {

    public override init() {
        super.init()

        folder = "./data/mnist_png"
        trainFolder = "training"
        validFolder = "testing"
        imageType = "L"
        imageSize = (28, 28)
        imageMean = [0.1307]
        imageStd = [0.3081]
        classes = ["0","1","2","3","4","5","6","7","8","9"]
        savedModelPath = "./mnist.pth"

        // redis
        queue = "mnist"
    }

    override open func getTransforms() -> Transforms<URL, String, PythonObject, Int> {
        return super.getTransforms().remove(transformType: Flip.self)
    }

    override open func getModel() -> PythonObject {
        let kernelSize = PythonObject(tupleOf: 2, 2)
        let model = nn.Sequential(
            nn.Conv2d(1, 6, 5),
            nn.ReLU(),
            nn.MaxPool2d(kernelSize),
            nn.Conv2d(6, 16, 5),
            nn.Dropout2d(), nn.ReLU(),
            nn.MaxPool2d(kernelSize),
            sai.Flatten(),
            nn.Linear(256, 120),
            nn.ReLU(),
            nn.Linear(120, 84),
            nn.ReLU(),
            nn.Linear(84, classes.count))

        return model
    }

}