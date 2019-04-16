// Copyright (c) 2019 Stephen Johnson. All rights reserved.

class SequentialSampler<X,Y>: Sampler<Int> {

    private var dataset: Dataset<X,Y>

    init(dataset: Dataset<X,Y>) {
        self.dataset = dataset
    }

    override func makeIterator() -> Iterator<Int> {
        return ArrayIterator(array: [Int](0..<dataset.len()))
    }

    override func len() -> Int {
        return dataset.len()
    }

}