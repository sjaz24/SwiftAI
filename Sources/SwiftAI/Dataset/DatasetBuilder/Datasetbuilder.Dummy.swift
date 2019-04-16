// Copyright (c) 2019 Stephen Johnson. All rights reserved.

public extension DatasetBuilder {

    @discardableResult
    func setX(_ x: X, type: FolderType, count: Int) -> DatasetBuilder<X,Y> {
        let xs = [X](repeating: x, count: count)

        switch type {
        case .Train: trainX = xs
        case .Valid: validX = xs
        case .Test: trainX = xs
        }

        return self
    }

    @discardableResult
    func withX(builderId: String? = nil, _ x: X, type: FolderType, count: Int) -> DatasetBuilder<X,Y> {
        funcs.append((id: builderId ?? "DummyX", fn: { self.setX(x, type: type, count: count) }))

        return self
    }

    @discardableResult
    func setY(_ y: Y, type: FolderType) -> DatasetBuilder<X,Y> {
        switch type {
        case .Train: trainY = [Y](repeating: y, count: trainX?.count ?? 0)
        case .Valid: validY = [Y](repeating: y, count: validX?.count ?? 0)
        case .Test: testY = [Y](repeating: y, count: testX?.count ?? 0)
        }

        return self
    }

    @discardableResult
    func withY(builderId: String? = nil, _ y: Y, type: FolderType) -> DatasetBuilder<X,Y> {
        funcs.append((id: builderId ?? "DummyY", fn: { self.setY(y, type: type) }))

        return self
    }
   
}