// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit
import SwiftRedis

fileprivate class RedisDataLoaderIterThread<X,Y,U:PythonConvertible,V:PythonConvertible> : Thread {

    private let iter: RedisDataLoaderIter<X,Y,U,V>
    private let queue: String
    private let redis: Redis
    private let mode: Mode

    private var x: [X]?
    private var y: [Y]?
    private var xTensor: String?
    private var yTensor: String?
    private let xMapper: ((String) -> X)?
    private let yMapper: ((String) -> Y)?

    var stop = false

    init(iter: RedisDataLoaderIter<X,Y,U,V>, queue: String, mode: Mode,
         xMapper: ((String) -> X)? = nil, yMapper: ((String) -> Y)? = nil) {
        self.iter = iter
        self.queue = queue
        self.mode = mode
        self.xMapper = xMapper
        self.yMapper = yMapper

        redis = Redis()
        redis.connect(host: "localhost", port: 6379) { (redisError: NSError?) in
            if let error = redisError {
                print("The following error occurred connecting to Redis: \(error)")
            }
        }
    }

    override func main() {
        print("starting main thread for queue \(queue)")

        let phase: String
        switch mode {
        case .Train:
            phase = "train"
        case .Valid:
            phase = "valid"
        case .Test:
            phase = "test"
        default:
            print("Error: Invalid mode for RedisDataLoaderIterThread \(mode)")
            return
        }
            
        let listPrefix = "\(queue)-\(phase)"
        let xBatchListKey = "\(listPrefix)-x-batch"
        let xBatchListTensorKey = "\(listPrefix)-x-tensor-batch"
        let yBatchListKey = "\(listPrefix)-y-batch"
        let yBatchListTensorKey = "\(listPrefix)-y-tensor-batch"

        redis.rpush("\(queue)-command", values: "begin-\(phase)") { (length: Int?, error: NSError?) in 
            guard error == nil else {
                print(error!)
                return  
            }
        }
                 
        while !stop {
            popJsonBatch(list: xBatchListKey, isX: true)
            if x == nil {
                continue
            }
            popJsonBatch(list: yBatchListKey, isX: false)
            popTensorBatch(list: xBatchListTensorKey, isX: true)
            popTensorBatch(list: yBatchListTensorKey, isX: false)
            iter.batches.append(((x!, y!), (xTensor!, yTensor!)))
            (x, y, xTensor, yTensor) = (nil, nil, nil, nil)
            while iter.batches.count >= 5 && !stop {
                Thread.sleep(forTimeInterval: 5.0)
            }
        }
    }

    private func popJsonBatch(list: String, isX: Bool) {
        redis.blpop(list, timeout: 1) { (value: [RedisString?]?, error: NSError?) in
            guard error == nil else {
                print(error!)
                return
            }
            
            guard let value = value, value.count == 2, let redisString = value[1] else {
                print("no batch found")
                return
            }

            let batch = try! JSONSerialization.jsonObject(with: redisString.asData)
            if isX {
                if let mapper = xMapper, let batch = batch as? [String] {
                    x = batch.map { return mapper($0) }
                } else {
                    x = batch as? [X]
                }
            } else {
                if let mapper = yMapper, let batch = batch as? [String] {
                    y = batch.map { return mapper($0) }
                } else {
                    y = batch as? [Y]
                }
            }
        }
    }

    private func popTensorBatch(list: String, isX: Bool) {
        redis.blpop(list, timeout: 0) { (value: [RedisString?]?, error: NSError?) in
            guard error == nil else {
                print(error!)
                return
            }
            
            guard let value = value, value.count == 2, let redisString = value[1] else {
                print("no batch found for \(list)")
                return
            }

            if isX {
                xTensor = redisString.asString
            } else {
                yTensor = redisString.asString
            }
        }
    }
}

class RedisDataLoaderIter<X,Y,U:PythonConvertible,V:PythonConvertible> : Iterator<(([X],[Y]), PythonObject)> {

    private var thread: RedisDataLoaderIterThread<X,Y,U,V>?
    fileprivate var batches = [(([X],[Y]), (String, String))]()
    private var batchCount = 0

    init(queue: String, mode: Mode, xMapper: ((String) -> X)? = nil, yMapper: ((String) -> Y)? = nil) {
        super.init()
        thread = RedisDataLoaderIterThread(iter: self, queue: queue, mode: mode, xMapper: xMapper, yMapper: yMapper)
        thread?.start()
        Thread.sleep(forTimeInterval: 5.0)
    }

    override func next() -> (([X],[Y]), PythonObject)? {
        if batches.count == 0 {
            thread?.stop = true
            return nil
        }

        let start = NSDate().timeIntervalSince1970

        let batch = batches.removeFirst()
        let xTensor = torch.load(io.BytesIO(Python.bytes.fromhex(batch.1.0)))
        let yTensor = torch.load(io.BytesIO(Python.bytes.fromhex(batch.1.1)))

        batchCount += 1
        let end = NSDate().timeIntervalSince1970 
        print("Total time for batch #\(batchCount) (seconds) = \(end - start)")        

        return (batch.0, PythonObject(tupleOf: xTensor, yTensor))
    }
    


}