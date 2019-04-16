// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

open class LargestBoundingBoxTestCallback: TestCallback<URL, BoundingBox> {

    public let classes: [String]
    public let imageSize: (width: Double, height: Double)

    public var batchCount = 0
    public var count = 0
    public var correct = 0
    public var accuracy = 0.0
    public var totalOverlap = 0.0
    public var avgOverlap = 0.0
    public var results = [(image: URL, prediction: BoundingBox, confidence: Double, overlap: Double, target: BoundingBox)]()

    private let printer = LinePrinter()
    
    public init(classes: [String], imageSize: (width: Int, height: Int)) {
        self.classes = classes
        self.imageSize = (Double(imageSize.width), Double(imageSize.height))
    }

    open override func onTestBegin(size: Int) {
        print("\nTesting...\n")
        batchCount = 0
        printStats()
    }

    open override func onBatchResults(batch: (([URL], [BoundingBox]), PythonObject), output: PythonObject) {
        batchCount += 1

        let split = torch.split(output, [4, self.classes.count], dim: 1)
        let coordPreds = split[0]
        let classPreds = nn.functional.softmax(split[1], dim: 1)
        let (max, maxIdx) = torch.max(classPreds, dim: 1).tuple2
        let maxs = [Double](max.tolist())!
        let preds = [Int](maxIdx.tolist())!

        count += preds.count

        for (index, pred) in preds.enumerated() {
            let confidence = maxs[index]
            let image = batch.0.0[index]

            let coords = coordPreds[index]
            var (top, left, bottom, right) = (Double(coords[0])!, Double(coords[1])!, Double(coords[2])!, Double(coords[3])!)
            let predBbox = BoundingBox(cls: classes[pred], top: top, left: left, bottom: bottom, right: right, 
                                   imageSize: imageSize, normalized: true).denormalize()

            let target = batch.1[1][index]
            (top, left, bottom, right) = (Double(target[0])!, Double(target[1])!, Double(target[2])!, Double(target[3])!)
            let classIndex = Int(target[4])!    
            let targetBbox = BoundingBox(cls: classes[classIndex], top: top, left: left, bottom: bottom, right: right, 
                                         imageSize: imageSize, normalized: true).denormalize()

            if pred == classIndex {
                correct += 1
            }
            accuracy = Double(correct) / Double(count)

            let overlap = predBbox.overlap(other: targetBbox)
            totalOverlap += overlap
            avgOverlap = totalOverlap / Double(count)

            results.append((image: image, prediction: predBbox, confidence: confidence, overlap: overlap, target: targetBbox))
        }

        printStats()
    }

    private func printStats() {
        var str = "| Batch: \(batchCount) | "
        str.append("Accuracy: \(String(format: "%.5f", accuracy)) | ")
        str.append("IoU: \(String(format: "%.5f", avgOverlap)) |")
        printer.print(str)
    }

    private func string(_ bbox: BoundingBox) -> String {
        return "\(bbox.cls!) (\(bbox.top), \(bbox.left), \(bbox.bottom), \(bbox.right))"
    }

    open override func onTestEnd() {
        results.sort { $0.overlap > $1.overlap }

        printer.newLine()
        print("\nResults\n-------")
        for result in results {
            print("Image : \(result.image)")
            print("  Confidence : \(result.confidence)")
            print("  IoU        : \(result.overlap)")
            print("  Prediction : \(string(result.prediction))")
            print("  Target     : \(string(result.target))")
            print()
        }
        print("Accuracy : \(accuracy)")
        print("IoU      : \(avgOverlap)")
        print()
    }

}
