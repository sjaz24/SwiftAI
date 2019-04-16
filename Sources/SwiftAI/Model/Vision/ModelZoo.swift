// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

public enum ModelZooModel {
    case alexnet(_ pretrained: Bool)
    case vgg(_ layers: Int, _ batchnorm: Bool, _ pretrained: Bool)
    case resnet(_ layers: Int, _ pretrained: Bool)
    case squeezenet(_ major: Int, _ minor: Int, _ pretrained: Bool)
    case densenet(_ layers: Int, _ pretrained: Bool)
    case inceptionv3(_ pretrained: Bool)
    case googlenet(_ pretrained: Bool)
}

public func getModelZooModel(_ modelZooModel: ModelZooModel) -> PythonObject {
    let model: PythonObject

    switch (modelZooModel) {
    case .alexnet(let pretrained): 
        model = tvmodels.alexnet(pretrained: pretrained)

    case .resnet(let layers, let pretrained):
        switch layers {
        case 18: model = tvmodels.resnet18(pretrained: pretrained)
        case 34: model = tvmodels.resnet34(pretrained: pretrained)
        case 50: model = tvmodels.resnet50(pretrained: pretrained)
        case 101: model = tvmodels.resnet101(pretrained: pretrained)
        case 152: model = tvmodels.resnet152(pretrained: pretrained)
        default: fatalError("Incorrect layers \(layers) specified for ResNet.")
        }

    case .vgg(let layers, let bn, let pretrained):
        switch bn {
        case false:
            switch layers {
            case 11: model = tvmodels.vgg11(pretrained: pretrained)
            case 13: model = tvmodels.vgg13(pretrained: pretrained)
            case 16: model = tvmodels.vgg16(pretrained: pretrained)
            case 19: model = tvmodels.vgg19(pretrained: pretrained)
            default: fatalError("Incorrect layers \(layers) specified for VGG.")
            }
        case true:
            switch layers {
            case 11: model = tvmodels.vgg11_bn(pretrained: pretrained)
            case 13: model = tvmodels.vgg13_bn(pretrained: pretrained)
            case 16: model = tvmodels.vgg16_bn(pretrained: pretrained)
            case 19: model = tvmodels.vgg19_bn(pretrained: pretrained)
            default: fatalError("Incorrect layers \(layers) specified for VGG.")
            }            
        }

    case .squeezenet(let major, let minor, let pretrained):
        guard major == 1 else {
            fatalError("SqueezeNet major version must be 1. Was \(major).")
        }
        switch minor {
        case 0: model = tvmodels.squeezenet1_0(pretrained: pretrained)
        case 1: model = tvmodels.squeezenet1_1(pretrained: pretrained)
        default: fatalError("SqueezeNet minor version must be 0 or 1. Was \(minor).")
        }
    
    case .densenet(let layers, let pretrained):
        switch layers {
        case 121: model = tvmodels.densenet121(pretrained: pretrained)
        case 161: model = tvmodels.densenet161(pretrained: pretrained)
        case 169: model = tvmodels.densenet169(pretrained: pretrained)
        case 201: model = tvmodels.densenet201(pretrained: pretrained)
        default: fatalError("Incorrect layers \(layers) specified for DenseNet.")
        }

    case .inceptionv3(let pretrained):
        model = tvmodels.inception_v3(pretrained: pretrained)

    case .googlenet(let pretrained):
        model = tvmodels.googlenet(pretrained: pretrained)
    }

    return model
}
