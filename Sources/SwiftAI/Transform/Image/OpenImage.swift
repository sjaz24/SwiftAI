// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class OpenImage: Transform {

    private let type: String?

    public init(type: String? = nil,   
                appliesTo: Set<TransformApplicability> = [.X, .Mode(.Train), .Mode(.Valid), .Mode(.Test)]) {
        self.type = type

        super.init(appliesTo: appliesTo)
    }

    public override func from(_ from: (Any?, Any?)) -> (Any?, Any?) {
        return (transform(from.0), transform(from.1))
    }

    private func transform(_ from: Any?) -> Any? {
        var to: Any? = from

        if let url = to as? URL {
            to = openImage(url)
        } 

        if let image = to as? Image {
            convertImage(image)
        }

        return to   
    }

    private func openImage(_ url: URL) -> Image {
        let image = Image()
        image.url = url
        image.pilImage = PIL.open(url.path)

        return image
    }

    private func convertImage(_ image: Image)  {
        guard let type = type, let pilImage = image.pilImage, String(pilImage.mode) != type else {
            return
        }

        image.pilImage = pilImage.convert(type)
        pilImage.close()
    }

}
