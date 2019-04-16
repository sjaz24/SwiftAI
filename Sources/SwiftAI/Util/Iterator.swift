// Copyright (c) 2019 Stephen Johnson. All rights reserved.

public class Iterator<T>: IteratorProtocol {
    public typealias Element = T

    public func next() -> T? {
        fatalError("Must override")
    }
}