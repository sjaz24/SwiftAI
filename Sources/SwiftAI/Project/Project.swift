// Copyright (c) 2019 Stephen Johnson. All rights reserved.

open class Project {

    public var batchSize = 32
    public var learningRate = 0.1

    func train(epochs: Int = 1) {
        fatalError("Must override!")
    }

    func test(useValidDl: Bool = false) {
        fatalError("Must override!")
    }

    func startRedisLoading() {
        fatalError("Must override!")
    }
    
    func redisTrain(epochs: Int = 1, train: Bool = true, valid: Bool = true) {
        fatalError("Must override!")
    }

    func redisTest(useValidDl: Bool = false) {
        fatalError("Must override!")
    }

}