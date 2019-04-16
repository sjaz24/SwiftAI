// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

public class DataLoaderSet<X,Y,U:PythonConvertible,V:PythonConvertible> {

    public let trainDl: DataLoader<X,Y,U,V>?
    public let validDl: DataLoader<X,Y,U,V>?
    public let testDl: DataLoader<X,Y,U,V>?

    public init(datasets: (train: Dataset<X,Y>?, valid: Dataset<X,Y>?, test: Dataset<X,Y>?), 
                bs: Int = 64, transforms: Transforms<X,Y,U,V>) {
        if let trainDs = datasets.train {
            trainDl = DataSetDataLoader(dataset: trainDs, mode: .Train, batchSize: bs, shuffle: true, transforms: transforms)
        } else {
            trainDl = nil
        }

        if let validDs = datasets.valid {
            validDl = DataSetDataLoader(dataset: validDs, mode: .Valid, batchSize: bs * 2, shuffle: false, transforms: transforms)
        } else {
            validDl = nil
        }

        if let testDs = datasets.test {
            testDl = DataSetDataLoader(dataset: testDs, mode: .Test, batchSize: bs * 2, shuffle: false, transforms: transforms)
        } else {
            testDl = nil
        }
    }

    public init(queue: String, train: Bool = true, valid: Bool = true, test: Bool = false,
                xMapper: ((String) -> X)? = nil, yMapper: ((String) -> Y)? = nil) {
        if train {
            trainDl = RedisDataLoader(queue: queue,  mode: .Train, xMapper: xMapper, yMapper: yMapper)
        } else {
            trainDl = nil
        }
        
        if valid {
            validDl = RedisDataLoader(queue: queue, mode: .Valid, xMapper: xMapper, yMapper: yMapper)
        } else {
            validDl = nil
        }

        if test {
            testDl = RedisDataLoader(queue: queue, mode: .Test, xMapper: xMapper, yMapper: yMapper)
        } else {
            testDl = nil
        }        
    }

}