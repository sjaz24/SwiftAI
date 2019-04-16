// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

open class TestCallback<X,Y> {

    open func onTestBegin(size: Int) { }

    open func onBatchResults(batch: (([X],[Y]), PythonObject), output: PythonObject) { }

    open func onTestEnd() { }

}