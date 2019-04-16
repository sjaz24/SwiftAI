// Copyright (c) 2019 Stephen Johnson. All rights reserved.

infix operator ** : Exponentiation

precedencegroup Exponentiation { higherThan: MultiplicationPrecedence }

public func ** (left: Double, right: Int) -> Double {
    assert(right >= 1)
    
    var val = left
    for _ in 1..<right {
        val *= left
    }

    return val
}

public func * (left: Tensor, right: Double) -> Tensor {
    return torch.mul(left, right)
}

public func * (left: Double, right: Tensor) -> Tensor {
    return torch.mul(left, right)
}

public func * (left: Tensor, right: Int) -> Tensor {
    return torch.mul(left, right)
}

public func * (left: Int, right: Tensor) -> Tensor {
    return torch.mul(left, right)
}

public func / (left: Tensor, right: Double) -> Tensor {
    return torch.div(left, right)
}

public func / (left: Double, right: Tensor) -> Tensor {
    return torch.div(left, right)
}

public func / (left: Tensor, right: Int) -> Tensor {
    return torch.div(left, right)
}

public func / (left: Int, right: Tensor) -> Tensor {
    return torch.div(left, right)
}

public func + (left: Tensor, right: Double) -> Tensor {
    return torch.add(left, right)
}

public func + (left: Double, right: Tensor) -> Tensor {
    return torch.add(left, right)
}

public func + (left: Tensor, right: Int) -> Tensor {
    return torch.add(left, right)
}

public func + (left: Int, right: Tensor) -> Tensor {
    return torch.add(left, right)
}

public func > (left: Tensor, right: Tensor) -> Tensor {
    return torch.gt(left, right)
}

public func > (left: Tensor, right: Double) -> Tensor {
    return torch.gt(left, right)
}

public func > (left: Double, right: Tensor) -> Tensor {
    return torch.gt(left, right)
}

public func > (left: Tensor, right: Int) -> Tensor {
    return torch.gt(left, right)
}

public func > (left: Int, right: Tensor) -> Tensor {
    return torch.gt(left, right)
}

public func | (left: TransformApplicability, right: TransformApplicability) -> Set<TransformApplicability> {
    return [left, right]
} 

public func | (left: Set<TransformApplicability>, right: TransformApplicability) -> Set<TransformApplicability> {
    return left | [right]
}

public func | (left: TransformApplicability, right: Set<TransformApplicability>) -> Set<TransformApplicability> {
    return right | left
}

public func | (left: Set<TransformApplicability>, right: Set<TransformApplicability>) -> Set<TransformApplicability> {
    return left.union(right)
}