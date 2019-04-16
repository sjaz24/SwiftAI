// Copyright (c) 2019 Stephen Johnson. All rights reserved.

public enum TransformApplicability : Hashable {
    case Mode(Mode)
    case X, Y
}

open class Transform {

    var appliesTo: Set<TransformApplicability>
    
    let percent: Int

    public init(appliesTo: Set<TransformApplicability>, percent: Int = 100) {
        self.appliesTo = appliesTo
        if percent < 0 {
            self.percent = 0
        } else if percent > 100 {
            self.percent = 100
        } else {
            self.percent = percent
        }
    }

    public func include(_ applicability: Set<TransformApplicability>) -> Transform {
        self.appliesTo.formUnion(applicability)
        return self
    }

    public func include(_ applicability: TransformApplicability) -> Transform {
        return include([applicability])
    }

    public func exclude(_ applicability: Set<TransformApplicability>) -> Transform {
        self.appliesTo.subtract(applicability)
        return self
    }

    public func exclude(_ applicability: TransformApplicability) -> Transform {
        return exclude([applicability])
    }

    open func from(_ from: (Any?, Any?)) -> (Any?, Any?) {
        fatalError("Must override")
    }

    func applies(mode: Mode) -> Bool {
        guard appliesTo.contains(.Mode(mode)) else {
            return false
        }

        guard percent == 100 || percent >= Int.random(in: 1...100) else {
            return false
        }

        return true
    }

}
