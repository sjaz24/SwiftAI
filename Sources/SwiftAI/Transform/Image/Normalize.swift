// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class Normalize: Transform {

    private let divisor: Double?
    private let mean: [Double]
    private let std: [Double]

    public init(divisor: Double? = 255.0, mean: [Double], std: [Double],  
                appliesTo: Set<TransformApplicability> = [.X, .Mode(.Train), .Mode(.Valid), .Mode(.Test)]) {
        self.divisor = divisor
        self.mean = mean
        self.std = std

        super.init(appliesTo: appliesTo)
    }

    public override func from(_ from: (Any?, Any?)) -> (Any?, Any?) {
        var to: (Any?, Any?) = (nil, nil)

        if let tensor = from.0 as? PythonObject {
            to.0 = normalize(tensor)
        }  

        if let tensor = from.1 as? PythonObject {
            to.1 = normalize(tensor)
        }

        return to    
    }

    private func normalize(_ tensor: PythonObject) -> PythonObject {
        var tensor = tensor

        if let divisor = self.divisor {
            tensor = tensor / divisor
        }

        let m = torch.tensor(mean.map { return [[$0]]})
        let s = torch.tensor(std.map { return [[$0]]})
        tensor = (tensor - m) / s

        return tensor
    }

}
