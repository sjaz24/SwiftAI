// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public class Transforms<X,Y,U:PythonConvertible,V:PythonConvertible> {

    var transforms: [Transform]

    public init(_ transforms: [Transform]) {
        self.transforms = transforms
    }

    func apply<U,V>(to: (Any?, Any?), mode: Mode) -> (U, V) {
        var result = to
        for transform in transforms {
            guard transform.applies(mode: mode) else {
                continue
            }
            let tmp = result
            let from = (transform.appliesTo.contains(.X) ? tmp.0 : nil, 
                        transform.appliesTo.contains(.Y) ? tmp.1 : nil)
            result = transform.from(from)
            result = (transform.appliesTo.contains(.X) ? result.0 : tmp.0, 
                      transform.appliesTo.contains(.Y) ? result.1 : tmp.1)
        }
        return result as! (U, V)
    }

    func processBatch(mode: Mode, batch: [(X,Y)]) -> PythonObject {
        var array = [PythonObject]()
        array.reserveCapacity(batch.count)
        for element in batch {
            let e: (Any?, Any?) = (element.0, element.1)
            let (x, y): (U, V) = apply(to: e, mode: mode)
            array.append(PythonObject(tupleOf: x, y))
        }

        return PythonObject(array)
    }

    public func remove(transformType: Transform.Type) -> Transforms {
        for (index, transform) in transforms.enumerated() {
            if type(of: transform) == transformType {
                transforms.remove(at: index)
                break
            }
        }

        return self
    }

    public func append(_ transform: Transform) -> Transforms {
        transforms.append(transform)

        return self
    }

}