// Copyright (c) 2019 Stephen Johnson. All rights reserved.

public extension DatasetBuilder {

    @discardableResult
    func setClasses(_ classes: [String]) -> DatasetBuilder<X,Y> {
        if let currentClasses = self.classes {
            let newClasses = Set.init(classes)
            let currentClasses = Set.init(currentClasses)
            if !currentClasses.isSubset(of: newClasses) {
                let invalidClasses = currentClasses.subtracting(newClasses)
                fatalError("Invalid classes found: \(invalidClasses)")
            }
        }
        self.classes = classes

        return self
    }

    @discardableResult
    func withClasses(builderId: String? = nil, _ classes: [String]) -> DatasetBuilder<X,Y> {
        funcs.append((id: builderId ?? "Classes", 
                      fn: { self.setClasses(classes) }))

        return self
    }

}