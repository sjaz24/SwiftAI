// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public struct BoundingBox {
    let cls: String?
    let top: Double
    let left: Double
    let bottom: Double
    let right: Double
    var imageSize: (width: Double, height: Double)? 
    let normalized: Bool

    public init(cls: String?, top: Double, left: Double, bottom: Double, right: Double, 
                imageSize: (width: Double, height: Double)?, normalized: Bool) {
        self.cls = cls
        (self.top, self.left, self.bottom, self.right) = (top, left, bottom, right)
        self.imageSize = imageSize
        self.normalized = normalized
    }

    public init(cls: String?, top: Double, left: Double, bottom: Double, right: Double) {
        self.init(cls: cls, top: top, left: left, bottom: bottom, right: right, imageSize: nil, normalized: false)
    }

    public init(top: Double, left: Double, bottom: Double, right: Double) {
        self.init(cls: nil, top: top, left: left, bottom: bottom, right: right, imageSize: nil, normalized: false)
    }

    public var width: Double {
        return abs(right - left)
    }

    public var height: Double {
        return abs(bottom - top)
    }

    public var area: Double {
        return width * height
    }

    public func overlap(other: BoundingBox) -> Double {
        let intersection = max(0, min(right, other.right) - max(left, other.left)) * 
                           max(0, min(bottom, other.bottom) - max(top, other.top))
        let union = area + other.area - intersection

        return intersection / union
    }

    public func normalize() -> BoundingBox {
        guard let imageSize = self.imageSize else {
            print("Error: Can't normalize bounding box. No image size specified.")
            return self
        }

        return normalize(imageSize: imageSize)
    }

    public func normalize(imageSize: (width: Double, height: Double)) -> BoundingBox {
        guard !normalized else {
            return self
        }

        guard self.imageSize == nil || (self.imageSize! == imageSize) else {
            print("Error: Can't normalize bounding box. A different image size than the current image size has been specified.")
            return self
        }

        let midpoint = (x: imageSize.width / 2.0, y: imageSize.height / 2.0)
        let top = -1.0 * ((self.top - midpoint.y) / midpoint.y)
        let bottom = -1.0 * ((self.bottom - midpoint.y) / midpoint.y)
        let left = (self.left - midpoint.x) / midpoint.x
        let right = (self.right - midpoint.x) /  midpoint.x

        return BoundingBox(cls: self.cls, top: top, left: left, bottom: bottom, right: right, 
                           imageSize: imageSize, normalized: true)
    }

    public func denormalize(imageSize: (width: Double, height: Double)) -> BoundingBox {
        guard normalized else {
            return self
        }

        let halfHeight = imageSize.height / 2.0
        let halfWidth = imageSize.width / 2.0
        let top = self.top * -halfHeight + halfHeight
        let bottom = self.bottom * -halfHeight + halfHeight
        let left = self.left * halfWidth + halfWidth
        let right = self.right * halfWidth + halfWidth
            
        return BoundingBox(cls: self.cls, top: top, left: left, bottom: bottom, right: right, 
                           imageSize: imageSize, normalized: false)
    }

    public func denormalize() -> BoundingBox {
        guard normalized, let imageSize = imageSize else {
            return self
        }

        return denormalize(imageSize: imageSize)
    }

    public func flip(type: FlipType) -> BoundingBox {
        guard self.normalized else {
            print("Error: At this time \"Flip\" only supports normalized bounding boxes.")
            return self
        }

        var (top, left, bottom, right) = (self.top, self.left, self.bottom, self.right)
        switch type {
        case .Horizontal, .HorizontalVertical:
            left *= -1.0
            right *= -1.0
            if type == .HorizontalVertical {
                fallthrough
            }
        case .Vertical:
            top *= -1.0
            bottom *= -1.0
        case .Dihedral:
            break
        }

        return BoundingBox(cls: self.cls, top: top, left: left, bottom: bottom, right: right, 
                           imageSize: imageSize, normalized: true)
    }

}

