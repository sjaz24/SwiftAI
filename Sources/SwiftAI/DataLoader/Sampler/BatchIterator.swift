// Copyright (c) 2019 Stephen Johnson. All rights reserved.

class BatchIterator<T>: Iterator<[T]> {
    
    private let iterator: Iterator<T>
    private let batchSize: Int
    private let dropLast: Bool

    init(sampler: Sampler<T>, batchSize: Int, dropLast: Bool) {
        self.iterator = sampler.makeIterator()
        self.batchSize = batchSize
        self.dropLast = dropLast
    }

    override func next() -> [T]? {
        var batch = [T]()
        batch.reserveCapacity(batchSize)
        for _ in 1...batchSize {
            guard let index = iterator.next() else {
                return !dropLast && batch.count > 0 ? batch : nil
            }
            batch.append(index)
        }
        return batch
    }
    
}