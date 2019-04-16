// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class Image {

    public var loadedFromCache = false
    public var url: URL?
    public var pilImage: PythonObject?

    deinit {
        if let pilImage = pilImage {
            pilImage.close()
        }
    }

}