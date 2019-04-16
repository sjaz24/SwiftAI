// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

public class EncodeBoundingBox: Transform {

    private let classes: [String]

    public init(classes: [String], 
                appliesTo: Set<TransformApplicability> = [.Y, .Mode(.Train), .Mode(.Valid), .Mode(.Test)]) {
        self.classes = classes
        
        super.init(appliesTo: appliesTo)
    }

    public override func from(_ from: (Any?, Any?)) -> (Any?, Any?) {
        var to: (Any?, Any?) = (nil, nil)

        if let bbox = from.0 as? BoundingBox {
            to.0 = transform(bbox: bbox)
        }

        if let bbox = from.1 as? BoundingBox  {
            to.1 = transform(bbox: bbox)
        }

        return to    
    }

    private func transform(bbox: BoundingBox) -> PythonObject {
        var result = coordinates(of: bbox)
        result.append(Double(classes.firstIndex(of: bbox.cls!)!))
        return torch.FloatTensor(result)
    }

    private func coordinates(of bbox: BoundingBox) -> [Double] {
        return [bbox.top, bbox.left, bbox.bottom, bbox.right]
    }

    private func encode(cls: String) -> [Double] {
        var encoding = [Double](repeating: 0.0, count: classes.count)
        encoding[classes.firstIndex(of: cls)!] = 1.0
        return encoding
    }

}
