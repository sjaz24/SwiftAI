// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

public typealias Tensor = PythonObject
public typealias TensorImage = Tensor
public typealias PilImage = PythonObject
public typealias LossFunc = (Tensor, Tensor) -> Tensor