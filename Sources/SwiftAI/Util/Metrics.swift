// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

public func getAccuracy(prepFunc: ((Tensor) -> Tensor)? = nil) -> (Tensor, Tensor) -> Tensor {
    return { (input: Tensor, targs: Tensor) -> Tensor in
        var input = input
        if let prepFunc = prepFunc {
          input = prepFunc(input)
        }

        let n = targs.size(0)
        input = torch.argmax(input, dim: 1)
        input = input.view(n, -1) // for some reason chaining this to above expression causes compiler issue
        let targs = targs.view(n, -1)
        let accuracy = torch.eq(input, targs).float().mean()

        return accuracy
    }
}

public func getAccuracyMulti(prepFunc: ((Tensor) -> Tensor)? = nil, threshold: Double = 0.5) -> (Tensor, Tensor) -> Tensor {
    return { (input: Tensor, targs: Tensor) -> Tensor in
        var input = input
        if let prepFunc = prepFunc {
          input = prepFunc(input)
        }

        let preds = input > threshold
        let accuracy = torch.eq(preds, targs.byte()).float().mean()

        return accuracy
    }
}

public func getF2(prepFunc: ((Tensor) -> Tensor)? = nil, threshold: Double = 0.5, 
                  beta: Double = 2.0, eps: Double = 1e-9) -> (Tensor, Tensor) -> Tensor {
    return { (input: Tensor, targs: Tensor) -> Tensor in
        var input = input
        if let prepFunc = prepFunc {
          input = prepFunc(input)
        }

        let yPred = (input > threshold).float()
        let yTrue = targs.float()
        let tp = torch.sum(yPred * yTrue, 1)
        let pred = torch.sum(yPred, 1)
        let tru = torch.sum(yTrue, 1)

        let beta2 = beta**2
        let onePlusBeta2 = 1.0 + beta2
        let prec = tp / (pred + eps)
        let rec =  tp / (tru + eps)
        let res = (prec * rec) / ((rec + (prec * beta2)) + eps) * onePlusBeta2

        let fbeta = torch.mean(res)
        return fbeta
    }
}

public func getLargestBBoxLabelAccuracy(prepFunc: ((Tensor) -> Tensor)? = nil,
                                        numClasses: Int) -> ((Tensor, Tensor) -> Tensor) {
    return { (input: Tensor, targs: Tensor) -> Tensor in
        var input = torch.split(input, [4,numClasses], dim: 1)[1]
        if let prepFunc = prepFunc {
          input = prepFunc(input)
        }
        input = torch.argmax(input, dim: 1)

        var targs = torch.split(targs, [4,1], dim: 1)[1]
        targs = targs.view(-1).long()
        
        return torch.eq(input, targs).float().mean()
    }
}

public func getLargestBBoxOverlap(prepFunc: ((Tensor) -> Tensor)? = nil, numClasses: Int, 
                                  imageSize: (width: Int, height: Int)) -> ((Tensor, Tensor) -> Tensor) {    
    return { (input: Tensor, targs: Tensor) -> Tensor in
        let imageSize = (width: Double(imageSize.width), height: Double(imageSize.height))
        let (top, left, bottom, right) = (0, 1, 2, 3)
        var input = torch.split(input, [4,numClasses], dim: 1)[0]
        if let prepFunc = prepFunc {
            input = prepFunc(input)
        }
        var targs = torch.split(targs, [4,1], dim: 1)[0]
        let count = Int(input.size()[0])!
        var totalOverlap = 0.0

        func boundingBox(_ coords: PythonObject) -> BoundingBox {
            let top = Double(coords[top])!
            let left = Double(coords[left])!
            let bottom = Double(coords[bottom])!
            let right = Double(coords[right])!
            let bbox = BoundingBox(cls: "", top: top, left: left, bottom: bottom, right: right, 
                               imageSize: imageSize, normalized: true)
            
            return bbox.denormalize()
        }

        for index in 0..<count {
            let inputBox = boundingBox(input[index])
            let targetBox = boundingBox(targs[index])
            let overlap = inputBox.overlap(other: targetBox)
            totalOverlap += overlap
        }
        
        let averageOverlap = totalOverlap / Double(count)

        return torch.FloatTensor([averageOverlap])
    }
}