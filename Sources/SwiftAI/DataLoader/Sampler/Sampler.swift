// Copyright (c) 2019 Stephen Johnson. All rights reserved.

class Sampler<T> {

    func makeIterator() -> Iterator<T> {
        fatalError("Must override")
    }

    func len() -> Int {
        fatalError("Must override")
    }
}



