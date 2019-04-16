// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class PilToTensor: Transform {

    public init(appliesTo: Set<TransformApplicability> = [.X, .Mode(.Train), .Mode(.Valid), .Mode(.Test)]) {
        super.init(appliesTo: appliesTo, percent: 100)
    }

    public override func from(_ from: (Any?, Any?)) -> (Any?, Any?) {
        var to: (Any?, Any?) = (nil, nil)

        if let image = from.0 as? Image {
            to.0 = toTensor(image)
        }

        if let image = from.1 as? Image {
            to.1 = toTensor(image)
        }

        return to    
    }

    private func toTensor(_ image: Image) -> Tensor {
        guard let pilImage = image.pilImage else {
            fatalError("No PIL Image found.")
        }

        let tensor = torchvisionF.to_tensor(pilImage)
        pilImage.close()

        return tensor
    }
}
