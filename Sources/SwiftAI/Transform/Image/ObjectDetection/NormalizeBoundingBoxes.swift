// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class NormalizeBoundingBoxes: Transform {

    public init(appliesTo: Set<TransformApplicability> = [.X, .Y, .Mode(.Train), .Mode(.Valid), .Mode(.Test)]) {
        super.init(appliesTo: appliesTo, percent: 100)
    }

    public override func from(_ from: (Any?, Any?)) -> (Any?, Any?) {
        var to: (Any?, Any?) = (nil, nil)

        if let image = from.0 as? Image, let pilImage = image.pilImage {
            to.0 = image
            let imageSize = (Double((pilImage.size)[0])!, Double((pilImage.size)[1])!)
            if let bboxes = from.1 as? [BoundingBox] {
                var normBBoxes = [BoundingBox]()
                for bbox in bboxes {
                    normBBoxes.append(bbox.normalize(imageSize: imageSize))
                }
                to.1 = normBBoxes
            } else if let bbox = from.1 as? BoundingBox {
                to.1 = bbox.normalize(imageSize: imageSize)
            }
        }

        //print(to)

        return to    
    }

}
