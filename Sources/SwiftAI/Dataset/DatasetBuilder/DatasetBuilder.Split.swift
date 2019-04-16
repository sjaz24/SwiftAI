// Copyright (c) 2019 Stephen Johnson. All rights reserved.

public extension DatasetBuilder {

    @discardableResult
    func split(random: Bool, from: FolderType, to: FolderType? = nil, pct: Double) -> DatasetBuilder<X,Y> {
        guard pct > 0.0, pct < 1.0 else {
            return self
        }

        if let to = to, from == to {
            return self
        }

        var fromX: [X]?
        var fromY: [Y]?
        switch from {
        case .Train: fromX = trainX; fromY = trainY;
        case .Valid: fromX = validX; fromY = validY
        case .Test: fromX = testX; fromY = testY
        }

        guard let x = fromX else {
            return self
        }

        let split: ([[Any]],[[Any]])
        let ySplit: Bool
        if let y = fromY {
            ySplit = true

            if random {
                split = randomSplit(percent: pct, arrays: x as [Any], y)
            } else {
                if let splitOf = x as? [CustomStringConvertible] {
                    split = fixedSplit(of: splitOf, salt: "\(from)", percent: pct, arrays: x as [Any], y)
                } else {
                    return self
                }
            }
        } else {
            ySplit = false
            if random {
                split = randomSplit(percent: pct, arrays: x as [Any])
            } else {
                if let splitOf = x as? [CustomStringConvertible] {
                    split = fixedSplit(of: splitOf, salt: "\(from)", percent: pct, arrays: x as [Any])
                } else {
                    return self
                }
            }
        }

        fromX = split.0[0] as? [X]
        fromY = ySplit ? split.0[1] as? [Y] : nil
        switch from {
        case .Train: trainX = fromX; trainY = fromY
        case .Valid: validX = fromX; validY = fromY
        case .Test: testX = fromX; testY = fromY
        }

        if let to = to {
            let toX = split.1[0] as? [X]
            let toY = ySplit ? split.1[1] as? [Y] : nil
            switch to {
            case .Train: trainX = toX; trainY = toY
            case .Valid: validX = toX; validY = toY
            case .Test: testX = toX; testY = toY
            }
        }

        return self
    }

    @discardableResult
    func withFixedSplit(builderId: String? = nil, from: FolderType, to: FolderType, 
                        pct: Double) -> DatasetBuilder<X,Y> {
        let id = "\(from)To\(to)FixedSplit"
        funcs.append((id: id, fn: { self.split(random: false, from: from, to: to, pct: pct) }))

        return self
    }

    @discardableResult
    func withRandomSplit(builderId: String? = nil, from: FolderType, to: FolderType, 
                         pct: Double) -> DatasetBuilder<X,Y> {
        let id = builderId ?? "\(from)To\(to)RandomSplit"
        funcs.append((id: id, fn: { self.split(random: true, from: from, to: to, pct: pct) }))

        return self
    }

    @discardableResult
    func withSplit(builderId: String? = nil, from: FolderType, to: FolderType, 
                   pct: Double, fixed: Bool = false) -> DatasetBuilder<X,Y> {
        let builderId = builderId ?? "\(from)To\(to)Split"
        if fixed {
            return withFixedSplit(builderId: builderId, from: from, to: to, pct: pct)
        } else {
            return withRandomSplit(builderId: builderId, from: from, to: to, pct: pct)
        }
    }

    @discardableResult
    func withFixedSample(builderId: String? = nil, of: FolderType, pct: Double) -> DatasetBuilder<X,Y> {
        let id = builderId ?? "\(of)FixedSample"
        funcs.append((id: id, fn: { self.split(random: false, from: of, pct: 1.0 - pct) }))

        return self
    }

    @discardableResult
    func withRandomSample(builderId: String? = nil, of: FolderType, pct: Double) -> DatasetBuilder<X,Y> {
        let id = builderId ?? "\(of)RandomSample"
        funcs.append((id: id, fn: { self.split(random: true, from: of, pct: 1.0 - pct) }))

        return self
    }

    @discardableResult
    func withSample(builderId: String? = nil, of: FolderType, pct: Double, 
                    fixed: Bool = false) -> DatasetBuilder<X,Y> {
        let builderId = builderId ?? "\(of)Sample"
        if fixed {
            return withFixedSample(builderId: builderId, of: of, pct: pct)
        } else {
            return withRandomSample(builderId: builderId, of: of, pct: pct)
        }
    }

}