// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class DummyRedisDataset<X,Y>: Dataset<X,Y> {
    
    open override func len() -> Int {
        // TODO !!!
        return 0
    }

    open override func getItem(index: Int) -> (X,Y) {
        fatalError("Data being loaded via Redis. Can't access the dataset directly.")
    }

    public override func concat(other: Dataset<X,Y>) -> Dataset<X,Y> {
        fatalError("Data being loaded via Redis. This operation is not supported.")
    }

}

public class RedisDataLoader<X,Y,U:PythonConvertible,V:PythonConvertible> : DataLoader<X,Y,U,V> {

    let queue: String
    let mode: Mode
    let xMapper: ((String) -> X)?
    let yMapper: ((String) -> Y)?

    public override var dataset: Dataset<X,Y> {
        return DummyRedisDataset<X,Y>()
    }

    public init(queue: String, mode: Mode, xMapper: ((String) -> X)? = nil, 
                yMapper: ((String) -> Y)? = nil) {
        self.queue = queue
        self.mode = mode
        self.xMapper = xMapper
        self.yMapper = yMapper
    }

    override public func iterator(mode: Mode? = nil) -> IteratorSequence<Iterator<(([X],[Y]), PythonObject)>> {
        return IteratorSequence(RedisDataLoaderIter<X,Y,U,V>(queue: queue, mode: self.mode, 
                                                             xMapper: xMapper, yMapper: yMapper))
    }

    override public func len() -> Int {
        // TODO !!!
        return 0
    }
    
}