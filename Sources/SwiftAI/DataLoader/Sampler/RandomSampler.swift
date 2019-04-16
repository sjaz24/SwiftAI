// Copyright (c) 2019 Stephen Johnson. All rights reserved.

class RandomSampler<X,Y>: Sampler<Int> {

    private var dataset: Dataset<X,Y>

    init(dataset: Dataset<X,Y>) {
        self.dataset = dataset
    }

    override func makeIterator() -> Iterator<Int> {
        var indices = [Int]()
        indices.reserveCapacity(dataset.len())
        for index in 0..<dataset.len() {
            indices.append(index)
        }
        indices.shuffle()
        return ArrayIterator(array: indices)
    }

    override func len() -> Int {
        return dataset.len()
    }

}