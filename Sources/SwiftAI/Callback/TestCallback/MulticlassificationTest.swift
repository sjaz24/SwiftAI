// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

open class MultiClassificationTestCallback<X>: TestCallback<X, [String]> {

    public var batchCount = 0
    public let classes: [String]
    public let threshold: Double
    public var count: Int = 0
    public let accuracyFn: (Tensor, Tensor) -> Tensor
    public var accuracyTotal = 0.0
    public var accuracy = 0.0
    public let f2Fn: (Tensor, Tensor) -> Tensor
    public var f2Total = 0.0
    public var f2 = 0.0
    public var results = [(predictions: [String], confidences: [Double], actuals: [String], x: X)]()
     
    private let printer = LinePrinter()
    
    public init(classes: [String], threshold: Double = 0.5) {
        self.classes = classes
        self.threshold = threshold
        accuracyFn = getAccuracyMulti(threshold: threshold)
        f2Fn = getF2(threshold: threshold)
    }

    open override func onTestBegin(size: Int) {
        print("\nTesting...\n")
        count = 0
        accuracyTotal = 0.0
        accuracy = 0.0
        f2Total = 0.0
        f2 = 0.0
        results = [(predictions: [String], confidences: [Double], actuals: [String], x: X)]()
        results.reserveCapacity(size)
        printStats()
    }

    open override func onBatchResults(batch: (([X], [[String]]), PythonObject), output: PythonObject) {
        batchCount += 1

        let batchSize = Int(output.size(0))!
        let trueY = batch.1.tuple2.1
        count += batchSize
        
        let accuracyVal = accuracyFn(output, trueY).item()
        accuracyTotal += Double(batchSize) * Double(accuracyVal)!
        accuracy = accuracyTotal / Double(count)
    
        let f2Val = f2Fn(output, trueY).item()
        f2Total += Double(batchSize) * Double(f2Val)!
        f2 = f2Total / Double(count)

        let output = [[Double]](output.tolist())!
        for (rowIdx, row) in output.enumerated() {
            let x = batch.0.0[rowIdx]
            let y = batch.0.1[rowIdx]
            var predictions = [String]()
            var confidences = [Double]()
            for (colIdx, confidence) in row.enumerated() {
                if confidence > threshold {
                    predictions.append(classes[colIdx])
                    confidences.append(confidence)
                } 
            }
            results.append((predictions, confidences, y, x))
        }

        printStats()
    }

    public func printStats() {
        var str = "| Batch: \(batchCount) | "
        str.append("Accuracy: \(String(format: "%.5f", accuracy)) | ")
        str.append("F2: \(String(format: "%.5f", f2)) |")
        printer.print(str)
    }

    open override func onTestEnd() {
        printer.newLine()
        print("\nResults\n-------")
        for result in results {
            print("Image : \(result.x)")
            print("  Predictions : \(result.predictions)")
            print("  Confidences : \(result.confidences)")
            print("  Targets     : \(result.actuals)")
            print()
        }
        print()
        print("Batches  : \(batchCount)")
        print("Accuracy : \(String(format: "%.5f", accuracy))")
        print("F2       : \(String(format: "%.5f", f2))")
        print()
    }
    
}