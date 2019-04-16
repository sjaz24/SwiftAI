// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation

public class Pascal : LargestBBoxODVP {

    public override init() {
        super.init()

        testPct = 0.2
        folder = "./data/pascal"
        validFolder = "train"
        trainCocoJson = "pascal_train2007.json"
        validCocoJson = "pascal_val2007.json"
        testCocoJson = "pascal_test2007.json"

        savedModelPath = "./pascal.pth"

        // redis
        queue = "pascal"
    }

}