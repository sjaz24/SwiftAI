// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class ResizeImage: Transform {

    private let size: (width: Int, height: Int)

    public init(size: (width: Int, height: Int),
                appliesTo: Set<TransformApplicability> = [.X, .Mode(.Train), .Mode(.Valid), .Mode(.Test)], 
                percent: Int = 100) {
        self.size = size

        super.init(appliesTo: appliesTo, percent: percent)
    }

    public convenience init(size: Int, 
                            appliesTo: Set<TransformApplicability> = [.X, .Mode(.Train), .Mode(.Valid), .Mode(.Test)], 
                            percent: Int = 100) {
        self.init(size: (size, size), appliesTo: appliesTo, percent: percent)      
    }

    public override func from(_ from: (Any?, Any?)) -> (Any?, Any?) {
        return (transform(from.0), transform(from.1))
    }

    private func transform(_ from: Any?) -> Any? {
        let to: Any? = from

        if let image = to as? Image {
            resize(image)
        } 

        return to
    }

    private func resize(_ image: Image) {
        guard let pilImage = image.pilImage else {
            return
        }

        // pytorch width/height reversed
        image.pilImage = torchvisionF.resize(pilImage, [size.height, size.width], 2)
        pilImage.close()
    }

}
