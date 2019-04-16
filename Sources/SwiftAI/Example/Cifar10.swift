// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation

public class Cifar10 : SingleClassICVP {

    public override init() {
        super.init()

        folder = "./data/cifar10"
        testHasLabels = true
        imageSize = (32, 32)
        classes = ["airplane", "automobile", "bird", "cat", "deer", 
                   "dog", "frog", "horse", "ship", "truck"]
        savedModelPath = "./cifar10.pth"

        // redis
        queue = "cifar10"
    }
    
    override open func getDatasetBuilder() -> DatasetBuilder<URL, String> {
        return super.getDatasetBuilder()
            .withFixedSplit(from: .Train, to: .Valid, pct: 0.2)
    }

}