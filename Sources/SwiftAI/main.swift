// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit
import SwiftRedis
import CSV

let version = "0.0.0.1"

print()
print("SwiftAI")
print("-------")
print("Version      : \(version)")
print("Python       : \(Python.version)")
print("Torch        : \(torch.__version__)")
print("Torch Vision : \(torchvision.__version__)")
print("PIL          : \(PIL.__version__)")

let arguments = CommandLine.arguments

let project: Project
switch arguments[1] {
case "dogscats":
    project = DogsCats()
case "cifar10":
    project = Cifar10()
case "mnist":
    project = Mnist()
case "planet":
    project = Planet()
case "pascal":
    project = Pascal()
default:
    fatalError("Incorrect argument \(arguments[1]).")
}

switch arguments[2] {
case "train":
    let epochs = arguments.count > 3 ? Int(arguments[3])! : 1
    if arguments.count > 4 {
        project.learningRate = Double(arguments[4])!
        if arguments.count > 5 {
            project.batchSize = Int(arguments[5])!
        }
    }
    project.train(epochs: epochs)
case "test":
    let useValidDl = arguments.count > 3 ? arguments[3] == "valid" : false
    if arguments.count > 4 {
        project.batchSize = Int(arguments[4])!
    }
    project.test(useValidDl: useValidDl)
case "redis":
    switch arguments[3] {
    case "load":
        project.startRedisLoading()

    case "train":
        let epochs = arguments.count > 4 ? Int(arguments[4])! : 1
        project.redisTrain(epochs: epochs, train: true, valid: true)

    case "test":
        project.redisTest()

    default:
        fatalError("Incorrect argument \(arguments[3]).")
    }
default:
    fatalError("Incorrect argument \(arguments[2]).")
}

