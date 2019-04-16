// Copyright (c) 2019 Stephen Johnson. All rights reserved.

class BatchSampler<T>: Sampler<[T]> {
    
    private let sampler: Sampler<T>
    private let batchSize: Int
    private let dropLast: Bool

    init(sampler: Sampler<T>, batchSize: Int, dropLast: Bool) {
        self.sampler = sampler
        self.batchSize = batchSize
        self.dropLast = dropLast
    }

    override func makeIterator() -> Iterator<[T]> {
        return BatchIterator(sampler: sampler, batchSize: batchSize, dropLast: dropLast)
    }

    override func len() -> Int {
        if self.dropLast {
            return self.sampler.len() / self.batchSize
        } else {
            return (self.sampler.len() + self.batchSize - 1) / self.batchSize
        }
    }
    
}
