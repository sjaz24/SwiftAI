// Copyright (c) 2019 Stephen Johnson. All rights reserved.

public protocol Metric {
    var name: String { get }
    var value: Double { get }
}

public class MetricsCallback: Callback {

    let metrics: [Metric]
    private let printer = LinePrinter()

    public init(callbacks: [Callback]) {
        var metrics = [Metric]()
        for callback in callbacks where callback is Metric {
            metrics.append(callback as! Metric)
        }
        self.metrics = metrics

        super.init(order: Int.max, applicable: .All)
    }

    override public func onEpochBegin(state: [CallbackKey: Any]) {
        printer.newLine()
    }

    override public func onBatchEnd(state: [CallbackKey: Any]) -> Bool {
        var str = "| Epoch: \(state[.epoch] as! Int + 1) | "
        str.append("Batch: \(state[.numBatch] as! Int) | ")
        for metric in metrics {
            str.append("\(metric.name): \(String(format: "%.5f", metric.value)) | ")
        }
        printer.print(str)

        return false
    }

}