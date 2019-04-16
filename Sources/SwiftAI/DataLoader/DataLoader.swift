// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

public enum Mode {
    case Train, Valid, Test, Show
}

public class DataLoader<X,Y,U:PythonConvertible,V:PythonConvertible> {

    public func iterator(mode: Mode? = nil) -> IteratorSequence<Iterator<(([X],[Y]), PythonObject)>> {
        fatalError("Must override")
    }

    public func len() -> Int {
        fatalError("Must override")
    }

    public var dataset: Dataset<X,Y> {
        fatalError("Must override")        
    }
}

public class DataSetDataLoader<X,Y,U:PythonConvertible,V:PythonConvertible> : DataLoader<X,Y,U,V> {

    private let _dataset: Dataset<X,Y>
    public let mode: Mode
    public let batchSize: Int
    public let dropLast: Bool
    public let transforms: Transforms<X,Y,U,V>

    let batchSampler: BatchSampler<Int>
    
    private let sampler: Sampler<Int>

    public override var dataset: Dataset<X,Y> {
        return _dataset
    }

    public init(dataset: Dataset<X,Y>, mode: Mode, batchSize: Int = 1, shuffle: Bool = false, 
                dropLast: Bool = false, transforms: Transforms<X,Y,U,V>) {
        self._dataset = dataset
        self.mode = mode
        self.batchSize = batchSize
        self.dropLast = dropLast
        self.transforms = transforms

        if shuffle {
            self.sampler = RandomSampler(dataset: dataset)
        } else {
            self.sampler = SequentialSampler(dataset: dataset)
        }
        self.batchSampler = BatchSampler(sampler: self.sampler, batchSize: batchSize, dropLast: dropLast)
    }

    override public func iterator(mode: Mode? = nil) -> IteratorSequence<Iterator<(([X],[Y]), PythonObject)>> {
        return IteratorSequence(DataSetDataLoaderIter(dataLoader: self, mode: mode ?? self.mode))
    }

    override public func len() -> Int {
        return batchSampler.len()
    }
    
}



