// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit
import CSV

public class Planet : MultiClassICVP {

    var testResultsFilePath: String = "./planet-kaggle-submission.csv"

    public override init() {
        super.init()

        folder = "./data/planet"
        csvFilePath = "./data/planet/train_v2.csv"
        threshold = 0.2
        classes = ["agriculture", "artisinal_mine", "bare_ground", "blooming", "blow_down",
                   "clear", "cloudy", "conventional_mine", "cultivation", "habitation", "haze",
                   "partly_cloudy", "primary", "road", "selective_logging", "slash_burn", "water"]
        savedModelPath = "./planet-model.pth"

        // redis
        queue = "planet"
    }

    override open func getDatasetBuilder() -> DatasetBuilder<URL, [String]> {
        return super.getDatasetBuilder()
            .withFixedSplit(from: .Train, to: .Valid, pct: 0.2)
            .without(builderId: "DummyY")
            .withY(["primary", "clear", "agriculture", "road", "water"], type: .Test)
    }

    override public func getTestCallback() -> TestCallback<URL,[String]> {
        return PlanetKaggleCallback(classes: classes, threshold: threshold, testResultsFilePath: testResultsFilePath)
    }
}

fileprivate class PlanetKaggleCallback : MultiClassificationTestCallback<URL> {
    
    let testResultsFilePath: String

    init(classes: [String], threshold: Double = 0.5, testResultsFilePath: String) {
        self.testResultsFilePath = testResultsFilePath

        super.init(classes: classes, threshold: threshold)
    }

    override func onTestEnd() {
        super.onTestEnd()

        let stream = OutputStream(toFileAtPath: testResultsFilePath, append: false)!
        let csv = try! CSVWriter(stream: stream)
        defer {
            csv.stream.close()
        }
        try! csv.write(row: ["image_name", "tags"])

        for result in results {
            let imageName = String(result.x.lastPathComponent.dropLast(4))
            let tags = result.predictions.joined(separator: " ")
            try! csv.write(row: [imageName, tags])
        }

        csv.stream.close()
    }
}

