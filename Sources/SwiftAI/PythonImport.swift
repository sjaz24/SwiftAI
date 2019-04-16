// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

let sys = Python.import("sys")
let torch = Python.import("torch")
let nn = torch.nn
let sai = Python.import("swiftai")
let torchdataloader = Python.import("torch.utils.data.dataloader")
let torchvision = Python.import("torchvision")
let torchvisionF = torchvision.transforms.functional
let PIL = Python.import("PIL.Image")
let io = Python.import("io")
let tvmodels = Python.import("torchvision.models")

let ByteStorage = torch.ByteStorage
let ByteTensor = torch.ByteTensor