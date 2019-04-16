// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit
import SwiftRedis

public class GetCachedImage: Transform {

    private let redis: Redis = Redis()

    public init(appliesTo: Set<TransformApplicability> = [.X, .Mode(.Train), .Mode(.Valid), .Mode(.Test)]) {
        super.init(appliesTo: appliesTo)
        initRedis()
    }

    private func initRedis() {
        redis.connect(host: "localhost", port: 6379) { (redisError: NSError?) in
            if let error = redisError {
                print("The following error occurred connecting to Redis: \(error)")
            }
        }
    }

    public override func from(_ from: (Any?, Any?)) -> (Any?, Any?) {
        return (transform(from.0), transform(from.1))
    }

    private func transform(_ from: Any?) -> Any? {
        var to: Any? = from

        if let url = to as? URL {
            to = getImage(url) ?? to
        } 

        return to
    }

    private func getImage(_ url: URL) -> Image? {
        var image: Image!

        redis.get(url.path) { (redisString: RedisString?, error: NSError?) in
            guard error == nil else {
                print(error!)
                return
            }

            guard let string = redisString?.asString else {
                return
            }

            let splits = string.split(separator: ":", maxSplits: 3)
            if splits.count == 4, 
               let width = Int(String(splits[1])),
               let height: Int = Int(String(splits[2])) {

                let mode: String = String(splits[0])
                let hexBytes: String = String(splits[3])

                image = Image()
                image.url = url
                image.loadedFromCache = true
                image.pilImage = PIL.frombytes(mode, PythonObject(tupleOf: width, height), 
                                               Python.bytes.fromhex(hexBytes))
            }
        }

        return image
    }

}
