// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import PythonKit

public class SaveModel : Callback {

    private var batchCount = 0
    private let model: PythonObject
    private let filePath: String

    public init(model: PythonObject, filePath: String) {
        self.model = model
        self.filePath = filePath

        super.init(order: 0, applicable: .Training)
    }

    public override func onEpochEnd(state: [CallbackKey: Any]) -> Bool { 
        torch.save(model.state_dict(), filePath)

        return false 
    }

}