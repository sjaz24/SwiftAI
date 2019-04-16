// Copyright (c) 2019 Stephen Johnson. All rights reserved.

open class Dataset<X,Y> {

    public init() {}
    
    open func len() -> Int {
        fatalError("Must override")
    }

    open func getItem(index: Int) -> (X,Y) {
        fatalError("Must override")
    }

    public func concat(other: Dataset<X,Y>) -> Dataset<X,Y> {
        fatalError("TODO")
    }

}
