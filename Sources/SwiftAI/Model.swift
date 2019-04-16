// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

public func conv2dBlock(inChannels: Int, outChannels: Int, kernelSize: Int, stride: Int, 
                        padding: Int? = nil, batchNorm: Bool = true) -> PythonObject {
    let padding = padding ?? kernelSize / 2 / stride
    let conv = nn.Conv2d(inChannels, outChannels, kernelSize, stride, padding: padding, bias: false)
    let relu = nn.LeakyReLU(0.2, inplace: true)
    let sequential: PythonObject
    if batchNorm {
        sequential = nn.Sequential(conv, relu, nn.BatchNorm2d(outChannels))
    } else {
        sequential = nn.Sequential(conv, relu)
    }

    return sequential
}   

public func ganDiscriminator(imageSize: Int, inChannels: Int, numFeatures: Int = 64, 
                              numExtraLayers: Int = 0) -> PythonObject {
    
    assert(imageSize % 16 == 0, "imageSize must be a multiple of 16")

    let layers = nn.Sequential()
    let initialConv = conv2dBlock(inChannels: inChannels, outChannels: numFeatures, kernelSize: 4, 
                                  stride: 2, batchNorm: false)
    layers.add_module("Initial Conv Block", initialConv)

    for layerNum in 0..<numExtraLayers {
        print("adding extra layer \(layerNum)")
        let conv = conv2dBlock(inChannels: numFeatures, outChannels: numFeatures, kernelSize: 3, stride: 1)
        let layerName = "Extra Layer \(layerNum+1)" // note: would do this in line below but causes compiler issue
        layers.add_module(layerName, conv)
    }

    var csize = imageSize / 2
    var cfeatures = numFeatures
    var layerNum = 1
    while csize > 4 {
        let conv = conv2dBlock(inChannels: cfeatures, outChannels: cfeatures * 2, kernelSize: 4, stride: 2)
        let layerName = "Pyramid Layer \(layerNum)" // note: would do this in line below but causes compiler issue
        layers.add_module(layerName, conv)
        cfeatures *= 2; csize /= 2; layerNum += 1
    }

    let finalConv = nn.Conv2d(cfeatures, 1, 4, padding: 0, bias: false)
    layers.add_module("Final Conv", finalConv)

    return layers
}

public func deconv2dBlock(inChannels: Int, outChannels: Int, kernelSize: Int, stride: Int, 
                          padding: Int, batchNorm: Bool = true) -> PythonObject {
    let conv = nn.ConvTranspose2d(inChannels, outChannels, kernelSize, stride, padding: padding, bias: false)
    let relu = nn.ReLU(inplace: true)
    let sequential: PythonObject
    if batchNorm {
        sequential = nn.Sequential(conv, relu, nn.BatchNorm2d(outChannels))
    } else {
        sequential = nn.Sequential(conv, relu)
    }

    return sequential
}

public func ganGenerator(imageSize: Int, numChannels: Int, noiseSize: Int = 100, numFeatures: Int = 64,
                         numExtraLayers: Int = 0) -> PythonObject {
    
    assert(imageSize % 16 == 0, "imageSize must be a multiple of 16")

    let layers = nn.Sequential()

    var currentSize = 4
    var currentFeatures = numFeatures / 2
    while currentSize < imageSize {
        currentSize *= 2; currentFeatures *= 2
    }
    let deconvBlock = deconv2dBlock(inChannels: noiseSize, outChannels: currentFeatures, 
                                           kernelSize: 4, stride: 1, padding: 0)
    layers.add_module("Initial Deconv Block", deconvBlock)

    var layerNum = 1
    currentSize = 4
    while currentSize < imageSize / 2 {
        let deconvBlock = deconv2dBlock(inChannels: currentFeatures, outChannels: currentFeatures / 2, 
                                           kernelSize: 4, stride: 2, padding: 1)
        let layerName = "Deconv Layer \(layerNum)"
        layers.add_module(layerName, deconvBlock)
        currentFeatures /= 2; currentSize *= 2; layerNum += 1
    }

    for layerNum in 0..<numExtraLayers {
        let deconvBlock = deconv2dBlock(inChannels: currentFeatures, outChannels: currentFeatures, 
                                           kernelSize: 3, stride: 1, padding: 1)
        let layerName = "Extra Layer \(layerNum+1)" // note: would do this in line below but causes compiler issue
        layers.add_module(layerName, deconvBlock)        
    }

    let finalDeconv = nn.ConvTranspose2d(currentFeatures, numChannels, kernel_size: 4, stride: 2, 
                                         padding: 1, bias: false)
    layers.add_module("Final Deconv", finalDeconv)     
    layers.add_module("tanh", nn.Tanh())

    return layers
}