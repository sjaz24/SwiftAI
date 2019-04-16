// Copyright (c) 2019 Stephen Johnson. All rights reserved.

class ArrayIterator<T>: Iterator<T> {

    private var index = -1
    private var array: [T]

    init(array: [T]) {
        self.array = array
    }

    override func next() -> T? {
        guard index < array.count - 1 else {
            return nil
        }
        index += 1
        return array[index]
    }
    
}