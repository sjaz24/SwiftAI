// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

class DataSetDataLoaderIter<X,Y,U:PythonConvertible,V:PythonConvertible> : Iterator<(([X],[Y]), PythonObject)> {

    private let sampleIter: Iterator<[Int]>
    private let dataset: Dataset<X,Y>
    private let mode: Mode
    private let transforms: Transforms<X,Y,U,V>

    init(dataLoader: DataSetDataLoader<X,Y,U,V>, mode: Mode) {
        sampleIter = dataLoader.batchSampler.makeIterator()
        dataset = dataLoader.dataset
        transforms = dataLoader.transforms
        self.mode = mode
    }

    override func next() -> (([X],[Y]), PythonObject)? {
        guard let indices = sampleIter.next() else {
            return nil
        }

        var array = [(X,Y)]()
        array.reserveCapacity(indices.count)
        for index in indices {
            array.append(dataset.getItem(index: index))
        }

        var xs = [X]()
        var ys = [Y]()
        for (x, y) in array {
            xs.append(x)
            ys.append(y)
        }

        let batch = transforms.processBatch(mode: mode, batch: array)
        return ((xs, ys), torchdataloader.default_collate(batch))
    }

}