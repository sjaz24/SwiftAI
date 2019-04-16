// Copyright (c) 2019 Stephen Johnson. All rights reserved.

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public class LinePrinter {

    private var currentLineLength = 0

    public func print(_ str: String) {
        let clear = String(repeating: "\u{8}", count: currentLineLength)
        Swift.print(clear, terminator: "")

        Swift.print(str, terminator: "")
        fflush(stdout)
        currentLineLength = str.count
    }

    public func newLine() {
        Swift.print()
        currentLineLength = 0
    }

}