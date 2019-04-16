// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit
import SwiftRedis

public class RedisDataPusher<X,Y,U:PythonConvertible,V:PythonConvertible> {

    private let queue: String
    private let redis: Redis
    private let dataLoaders: DataLoaderSet<X,Y,U,V>
    private let xMapper: ((X) -> String)?
    private let yMapper: ((Y) -> String)?
    private let maxListLength: Int
    private var pusherThread: PusherThread<X,Y,U,V>?
    private var quit = false

    public init(queue: String, dataLoaders: DataLoaderSet<X,Y,U,V>, 
                xMapper: ((X) -> String)? = nil, yMapper: ((Y) -> String)? = nil,
                maxListLength: Int = 5) {
        self.queue = queue
        self.dataLoaders = dataLoaders
        self.xMapper = xMapper
        self.yMapper = yMapper
        self.maxListLength = maxListLength

        redis = Redis()
        redis.connect(host: "localhost", port: 6379) { (redisError: NSError?) in
            if let error = redisError {
                print("The following error occurred connecting to Redis: \(error)")
            }
        }
    }

    public func start() {

        repeat {
            print("waiting for blpop")
            redis.blpop("\(queue)-command", timeout: 0) { (value: [RedisString?]?, error: NSError?) in
                guard error == nil else {
                    print(error!)
                    return
                }
                guard let value = value, value.count == 2, let command = value[1]?.asString else {
                    print("Error: No or invalid command found")
                    return
                }
                switch command {
                case "end":
                    end()
                case var cmd where cmd.hasPrefix("begin-"):
                    cmd.removeFirst(6)
                    begin(phase: cmd)
                case "quit":
                    end()
                    quit = true
                default:
                    print("Error: Invalid command: \(command)")
                }
            }
            print("done waiting for blpop")
        } while !quit
    }


    private func end() {
        guard let pusherThread = pusherThread else {
            return
        }

        pusherThread.stop = true
        while pusherThread.isExecuting {
            Thread.sleep(forTimeInterval: 0.1)
        }

        self.pusherThread = nil
    }

    private func begin(phase: String) {
        guard phase == "train" ||
              (phase == "valid" && dataLoaders.validDl != nil) || 
              (phase == "test" && dataLoaders.testDl != nil) else {
            print("Error: Can not begin phase. No dataloader for phase or invalid phase specified: \(phase)")
            return
        }

        end()

        let iterator: IteratorSequence<Iterator<(([X],[Y]), PythonObject)>>
        switch phase {
        case "train":
            iterator = dataLoaders.trainDl!.iterator()
        case "valid":
            iterator = dataLoaders.validDl!.iterator()
        case "test":
            iterator = dataLoaders.testDl!.iterator()
        default:
            fatalError("We should never get here.")
        }

        let list = "\(queue)-\(phase)"
        pusherThread = PusherThread(list: list, iterator: iterator, 
                                    xMapper: xMapper, yMapper: yMapper, maxListLength: maxListLength)
        pusherThread?.start()
    }

}

fileprivate class PusherThread<X,Y,U:PythonConvertible,V:PythonConvertible> : Thread {

    private let redis: Redis
    private let xBatchListKey: String
    private let xBatchListTensorKey: String
    private let yBatchListKey: String
    private let yBatchListTensorKey: String
    private var iterator: IteratorSequence<Iterator<(([X],[Y]), PythonObject)>>
    private let xMapper: ((X) -> String)?
    private let yMapper: ((Y) -> String)?
    private let maxListLength: Int

    var stop = false
    
    init(list: String, iterator: IteratorSequence<Iterator<(([X],[Y]), PythonObject)>>,
         xMapper: ((X) -> String)?, yMapper: ((Y) -> String)?, maxListLength: Int) {
        xBatchListKey = "\(list)-x-batch"
        xBatchListTensorKey = "\(list)-x-tensor-batch"
        yBatchListKey = "\(list)-y-batch"
        yBatchListTensorKey = "\(list)-y-tensor-batch"
        self.iterator = iterator
        self.xMapper = xMapper
        self.yMapper = yMapper
        self.maxListLength = maxListLength
        
        redis = Redis()
        redis.connect(host: "localhost", port: 6379) { (redisError: NSError?) in
            if let error = redisError {
                print("The following error occurred connecting to Redis: \(error)")
            }
        }
    }

#if os(Linux)
    private func autoreleasepool(_ arp: () -> Void) {
        arp()
    }
#endif

    override func main() {
        deleteLists()

        var batchFound: Bool = false
        repeat { 
            autoreleasepool {
                var listLength = 0
                repeat {
                    redis.llen(xBatchListKey) { (length: Int?, error: NSError?) in 
                        guard error == nil else {
                            print(error!)
                            return  
                        } 

                        listLength = length!
                        if listLength >= maxListLength {
                            print("Max list length reached...waiting")
                            Thread.sleep(forTimeInterval: 5.0)
                        }
                    }
                } while !stop && listLength >= maxListLength

                batchFound = pushNext()
            }
        } while !stop && batchFound
    }

    private func deleteLists() {
        redis.del(xBatchListKey, yBatchListKey, xBatchListTensorKey, yBatchListTensorKey) { 
            (count: Int?, error: NSError?) in 
                if let error = error {
                    print(error)
                }             
        }
    }

    private func pushNext() -> Bool {
        let start = NSDate().timeIntervalSince1970 
        guard let batch = iterator.next() else {
            return false
        }
        let end = NSDate().timeIntervalSince1970 
        print("Time for next batch = \(end - start)")        

        var jsonObject: Any = batch.0.0
        if let mapper = xMapper {
            jsonObject = batch.0.0.map { return mapper($0) }
        } 
        pushJson(list: xBatchListKey, jsonObject: jsonObject)

        jsonObject = batch.0.1
        if let mapper = yMapper {
            jsonObject = batch.0.1.map { return mapper($0) }
        }
        pushJson(list: yBatchListKey, jsonObject: jsonObject)

        pushTensor(list: xBatchListTensorKey, tensor: batch.1[0])
        pushTensor(list: yBatchListTensorKey, tensor: batch.1[1])

        return true
    }

    private func pushJson(list: String, jsonObject: Any) {
        let json = RedisString(try! JSONSerialization.data(withJSONObject: jsonObject))
        redis.rpush(list, values: json) { (length: Int?, error: NSError?) in
            guard error == nil else {
                print(error!)
                return  
            } 
            print("\(list) length is \(length!)")
        }
    }

    private func pushTensor(list: String, tensor: PythonObject) {
        let buffer = io.BytesIO()
        defer {
            buffer.close()
        }
        torch.save(tensor, buffer)
        let hexBytes = String(buffer.getvalue().hex())! 
        redis.rpush(list, values: hexBytes) { (length: Int?, error: NSError?) in
            guard error == nil else {
                print(error!)
                return  
            } 
            print("\(list) length is \(length!)")
        }
    }

}