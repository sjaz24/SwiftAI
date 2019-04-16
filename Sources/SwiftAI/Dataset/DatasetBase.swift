// Copyright (c) 2019 Stephen Johnson. All rights reserved.

open class DatasetBase<X,Y> : Dataset<X,Y> {

    public let x: [X] 
    public let y: [Y]
    public let folder: String?
    public var classes: [String]?

    public init(x: [X], y: [Y], folder: String? = nil, classes: [String]? = nil) {
        self.x = x
        self.y = y
        self.folder = folder
        self.classes = classes

        super.init()
    }

    open override func getItem(index: Int) -> (X,Y) {
        return (x[index], y[index])
    }

    open override func len() -> Int {
        return x.count
    }

}


