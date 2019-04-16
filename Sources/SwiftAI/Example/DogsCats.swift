// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import CSV

public class DogsCats : SingleClassICVP {

    public var testResultsFilePath = "./dogs-vs-cats-redux-kaggle-submission.csv"

    public override init() {
        super.init()

        folder = "./data/dogscats"
        classes = ["cat","dog"]
        savedModelPath = "./dogs-cats-model.pth"

        // redis
        queue = "dogscats"
    }

    override open func getDatasetBuilder() -> DatasetBuilder<URL, String> {
        let datasetBuilder = super.getDatasetBuilder()
        let at = datasetBuilder.indexOf(builderId: "FileLabelsOfParentFolder")

        return datasetBuilder.without(builderId: "FileLabelsOfParentFolder")
            .withFileLabelsFromFilename(at: at) { String($0.prefix { $0 != "." }) }
            .withFixedSplit(from: .Train, to: .Valid, pct: 0.2)
    }

    override public func getTestCallback() -> TestCallback<URL,String> {
        return DogsCatsReduxKaggleCallback(classes: classes, testResultsFilePath: testResultsFilePath)
    }

}

fileprivate class DogsCatsReduxKaggleCallback : SingleClassificationTestCallback<URL> {
    
    let testResultsFilePath: String

    init(classes: [String], testResultsFilePath: String) {
        self.testResultsFilePath = testResultsFilePath
        super.init(classes: classes)

    }

    override func onTestEnd() {
        super.onTestEnd()

        let stream = OutputStream(toFileAtPath: testResultsFilePath, append: false)!
        let csv = try! CSVWriter(stream: stream)
        defer {
            csv.stream.close()
        }
        try! csv.write(row: ["id", "label"])

        for result in results {
            let id = String(result.x.lastPathComponent.dropLast(4))

            var confidence = result.confidence
            if result.prediction.idx == 0 {
                confidence = 1.0 - result.confidence
            }
            try! csv.write(row: [id, String(confidence)])
        }

        csv.stream.close()
    }
}

