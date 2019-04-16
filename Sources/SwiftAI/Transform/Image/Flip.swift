// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public enum FlipType {
    case Horizontal, Vertical, HorizontalVertical, Dihedral
}

public class Flip: Transform {

    private let type: FlipType

    public init(type: FlipType, appliesTo: Set<TransformApplicability> = [.X, .Mode(.Train)], 
                percent: Int = 50) {
        self.type = type

        super.init(appliesTo: appliesTo, percent: percent)
    }

    public override func from(_ from: (Any?, Any?)) -> (Any?, Any?) {
        var to: (Any?, Any?) = (nil, nil)

        if let image = from.0 as? Image {
            to.0 = flip(image: image)
        } else if let tensor = from.0 as? PythonObject {
            to.0 = flip(tensor: tensor)
        } else if let bbox = from.0 as? BoundingBox {
            to.0 = bbox.flip(type: type)
        }

        if let image = from.1 as? Image {
            flip(image: image)
        } else if let tensor = from.1 as? PythonObject {
            to.1 = flip(tensor: tensor)
        } else if let bbox = from.1 as? BoundingBox {
            to.1 = bbox.flip(type: type)
        }

        return to
    } 

    private func flip(image: Image) { 
        guard let pilImage = image.pilImage else {
            return
        }

        switch type {
        case .Horizontal: 
            image.pilImage = torchvisionF.hflip(pilImage)
        case .Vertical:
            image.pilImage = torchvisionF.vflip(pilImage)
        case .HorizontalVertical: 
            break
        case .Dihedral: 
            break
        }

        pilImage.close()
    }

    private func flip(tensor: PythonObject) -> PythonObject {    
        switch type {
        case .Horizontal: 
            return torch.flip(tensor, [2])
        case .Vertical: 
            return torch.flip(tensor, [1])
        case .HorizontalVertical: 
            return tensor.flip(tensor, [1,2])
        case .Dihedral: break
        }

        return tensor
    }

}
