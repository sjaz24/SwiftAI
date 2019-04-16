// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

open class SingleClassificationTestCallback<X>: TestCallback<X, String> {

    public let classes: [String]

    public var results = [(prediction: (idx: Int, cls: String), confidence: Double, actual: String, x: X)]()
    public var batchCount = 0
    public var count = 0
    public var correct = 0
    public var accuracy = 0.0

    private let printer = LinePrinter()

    public init(classes: [String]) {
        self.classes = classes
    }

    open override func onTestBegin(size: Int) {
        print("\nTesting...\n")
        batchCount = 0
        count = 0
        correct = 0
        results.removeAll()
        if size > 0 {
            results.reserveCapacity(size)
        }
        printStats()
    }

    open override func onBatchResults(batch: (([X], [String]), PythonObject), output: PythonObject) {
        batchCount += 1

        let (max, maxIdx) = torch.max(output, dim: 1).tuple2
        let preds = [Int](maxIdx.tolist())!
        count += preds.count
        for (index, pred) in preds.enumerated() {
            let x = batch.0.0[index]
            let y = batch.0.1[index]
            if (classes[pred] == y) {
                correct += 1
            }
            results.append(((pred, classes[pred]), Double(max[index]) ?? Double.nan, y, x))
        }

        accuracy = Double(correct) / Double(count)
        printStats()
    }

    private func printStats() {
        let str = "| Batch: \(batchCount) | Accuracy: \(String(format: "%.5f", accuracy)) |"
        printer.print(str)
    }

    open override func onTestEnd() {
        results.sort { $0.confidence > $1.confidence }

        printer.newLine()
        print("\nResults\n-------")
        for result in results {
            print("Image : \(result.x)")
            print("  Prediction : \(result.prediction.cls)")
            print("  Confidence : \(result.confidence)")
            print("  Target     : \(result.actual)")
            print()
        }
        print()
        print("Batches  : \(batchCount)")
        print("Accuracy : \(String(format: "%.5f", accuracy))")
        print()
    }

}
