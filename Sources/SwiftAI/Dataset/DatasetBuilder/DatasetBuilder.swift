// Copyright (c) 2019 Stephen Johnson. All rights reserved.

public class DatasetBuilder<X,Y> {

    public var funcs = [(id: String, fn: () -> ())]()

    public var trainFolder: String?
    public var trainX: [X]?
    public var trainY: [Y]?

    public var validFolder: String?
    public var validX: [X]?
    public var validY: [Y]?

    public var testFolder: String?
    public var testX: [X]?
    public var testY: [Y]?

    public var classes: [String]?

    public enum FolderType: CustomStringConvertible {
        case Train, Valid, Test

        public var description : String { 
            switch self {
            case .Train: return "Train"
            case .Valid: return "Valid"
            case .Test: return "Test"
            }
        }
    }

    public func build() -> (train: Dataset<X,Y>?, valid: Dataset<X,Y>?, test: Dataset<X,Y>?) {

        (trainFolder, trainX, trainY) = (nil, nil, nil)
        (validFolder, validX, validY) = (nil, nil, nil)
        (testFolder, testX, testY) = (nil, nil, nil)

        for (_, fn) in funcs {
            fn()
        }

        var trainDs: DatasetBase<X,Y>! 
        if let trainX = trainX, let trainY = trainY {
            trainDs = DatasetBase<X, Y>(x: trainX, y: trainY)
            trainDs.classes = classes 
        }

        var validDs: DatasetBase<X,Y>! 
        if let validX = validX, let validY = validY {
            validDs = DatasetBase<X, Y>(x: validX, y: validY)
            validDs.classes = classes         
        }

        var testDs: DatasetBase<X,Y>!
        if let testX = testX {
            testDs = DatasetBase<X, Y>(x: testX, y: testY ?? [Y]())
            testDs.classes = classes
        }

        return (trainDs, validDs, testDs)
    }

    public func addBuilderFunc(id: String, at: Int? = nil, fn: @escaping () -> ()) {
        let builderFunc = (id: id, fn: fn) 
        if let at = at, at >= 0, at <= funcs.count {
            funcs.insert(builderFunc, at: at)
        } else {
            funcs.append(builderFunc)
        }
    }

    public func indexOf(builderId: String) -> Int? {
        for (index, builderFunc) in funcs.enumerated() {
            if builderId == builderFunc.id {
                return index
            }
        }

        return nil
    }

    @discardableResult
    public func without(builderId: String) -> DatasetBuilder<X,Y> {
        if let index = indexOf(builderId: builderId) {
            funcs.remove(at: index)
        }

        return self
    }

}