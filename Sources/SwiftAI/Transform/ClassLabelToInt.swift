// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class ClassLabelToInt: Transform {

    private let classes: [String]

    public init(classes: [String], 
                appliesTo: Set<TransformApplicability> = [.Y, .Mode(.Train), .Mode(.Valid), .Mode(.Test)]) {
        self.classes = classes

        super.init(appliesTo: appliesTo)
    }

    public override func from(_ from: (Any?, Any?)) -> (Any?, Any?) {
        var to: (Any?, Any?) = (nil, nil)

        if let label = from.0 as? String {
            to.0 = encode(label)
        } else if let labels = from.0 as? [String] {
            to.0 = encode(labels)
        }

        if let label = from.1 as? String {
            to.1 = encode(label)
        } else if let labels = from.1 as? [String] {
            to.1 = encode(labels)
        }

        return to    
    }

    private func encode(_ label: String) -> Int {
        return classes.firstIndex(of: label)!
    }

    private func encode(_ labels: [String]) -> PythonObject {
        var encoding = [Int](repeating: 0, count: classes.count)
        for (index, cls) in classes.enumerated() {
            if (labels.contains(cls)) {
                encoding[index] = 1
            }
        }

        return torch.FloatTensor(encoding)
    }

}
