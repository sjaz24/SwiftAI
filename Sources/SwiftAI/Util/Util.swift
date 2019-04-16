// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import PythonKit

public func arraysSplit<T>(mask: [Bool], arrays: [T]...) -> ([[T]],[[T]]) {
    return arraysSplit(mask: mask, arrays: arrays)
}

public func arraysSplit<T>(mask: [Bool], arrays: [[T]]) -> ([[T]],[[T]]) {
    let count = arrays.count
    var trueSplit = [[T]](repeating: [T](), count: count)
    var falseSplit = [[T]](repeating: [T](), count: count)

    for index in 0..<mask.count {
        if mask[index] {
            for idx in 0..<arrays.count {
                trueSplit[idx].append(arrays[idx][index])
            }
        } else {
            for idx in 0..<arrays.count {
                falseSplit[idx].append(arrays[idx][index])
            }            
        }
    }
    
    return (trueSplit, falseSplit)
}

public func randomSplit<T>(percent: Double, arrays: [T]...) -> ([[T]],[[T]]) {
    var mask = [Bool](repeating: false, count: arrays[0].count)

    for index in 0..<arrays[0].count {
        let rand = Double.random(in: 0..<1)
        if rand > percent {
            mask[index] = true
        }
    }

    return arraysSplit(mask: mask, arrays: arrays)
}

public func fixedPercent(of: CustomStringConvertible, salt: String = "") -> Double {
    let bytes = "\(salt):\(of.description)".utf8.md5.bytes
    let hash = (UInt32(bytes.12) << 24 | UInt32(bytes.13) << 16 | 
                UInt32(bytes.14) << 8 | UInt32(bytes.15)) % 100
                
    return Double(hash) / 99.0
}

public func fixedSplit<T>(of: [CustomStringConvertible], salt: String = "", percent: Double, arrays: [T]...) -> ([[T]],[[T]]) {
    var mask = [Bool](repeating: false, count: arrays[0].count)

    for index in 0..<of.count {
        if fixedPercent(of: of[index], salt: salt) > percent {
            mask[index] = true
        }
    }

    return arraysSplit(mask: mask, arrays: arrays)
}

public func getFolderFiles(url: URL, extensions: Set<String>? = nil, 
                    excludeExtensions exclude: Bool = false) -> [URL] {
    let fm = FileManager.default

    let contents = try! fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, 
                                                  options: [.skipsHiddenFiles])

    var files = contents.filter { !$0.absoluteString.hasSuffix("/") && (extensions == nil || 
                                  ((!exclude &&  extensions!.contains($0.pathExtension)) ||
                                  (  exclude && !extensions!.contains($0.pathExtension)))) }

    let subdirectories = contents.filter { $0.absoluteString.hasSuffix("/") }
    for subdirectory in subdirectories {
        let subfiles = getFolderFiles(url: subdirectory, extensions: extensions, 
                                      excludeExtensions: exclude)
        files.append(contentsOf: subfiles)
    }

    return files
}

public func freeze(model: PythonObject) {
    let iter = model.parameters()
    while let param = try? Python.next.throwing.dynamicallyCall(withArguments: iter) {
        param.requires_grad = false
    }
}

public func unfreeze(model: PythonObject) {
    let iter = model.parameters()
    while let param = try? Python.next.throwing.dynamicallyCall(withArguments: iter) {
        param.requires_grad = true
    }    
}