// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit
import SwiftRedis

public class CacheImage: Transform {

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
        let to: Any? = from

        if let image = to as? Image {
            cacheImage(image)
        } 

        return to
    }

    private func cacheImage(_ image: Image) {
        guard !image.loadedFromCache,
              let url = image.url, 
              let pilImage = image.pilImage,
              let mode = String(pilImage.mode),
              let width = Int(pilImage.width), 
              let height = Int(pilImage.height),
              let hexBytes = String(pilImage.tobytes().hex()) else {
            return
        }

        let redisString = RedisString("\(mode):\(width):\(height):\(hexBytes)")
        redis.set(url.path, value: redisString) { (result: Bool, error: NSError?) in
            if let error = error {
                print(error)
            } else {
                print("cached image \(url.path)")
            }
        }
    }

}
