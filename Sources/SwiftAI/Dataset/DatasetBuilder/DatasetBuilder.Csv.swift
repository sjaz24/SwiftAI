// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation
import CSV

public extension DatasetBuilder {

    enum FilenameMatchOption {
        case WithSuffix, WithoutSuffix
    }

    @discardableResult
    func setFileLabelsFromCSV(file: String, filenameCol: Int = 0, labelsCol: Int = 1, 
                              hasHeaderRow: Bool = true, separator: Character = " ", 
                              filenameMatchOption: FilenameMatchOption = .WithoutSuffix,
                              singleLabel: Bool = false) -> DatasetBuilder<X,Y> {
        guard let stream = InputStream(fileAtPath: file) else {
            return self
        }

        var classes = Set<String>()

        var filenameMapping = [String: [String]]()
        let csv = try! CSVReader(stream: stream, hasHeaderRow: hasHeaderRow) 
        while let row = csv.next() {
            let labels = row[labelsCol].split(separator: separator).map { String($0) }
            classes.formUnion(labels)
            filenameMapping[row[filenameCol].lowercased()] = labels
        }

        func mapFilenamesToLabels(_ fileURLs: [URL]) -> [Y] {
            var ys = [Y]()
            for fileURL in fileURLs {
                var filename = fileURL.lastPathComponent
                if filenameMatchOption == .WithoutSuffix && filename.contains(".") {
                    filename = String(filename.split(separator: ".")[0])
                } 
                
                let y: Y
                if let mapping = filenameMapping[filename] {
                    if singleLabel {
                        y = mapping[0] as! Y
                    } else {
                        y = mapping as! Y
                    }
                } else {
                    if singleLabel {
                        y = "" as! Y
                    } else {
                        y = [""] as! Y
                    }
                }

                ys.append(y)
            }
            
            return ys
        }

        trainY = mapFilenamesToLabels(trainX as! [URL])

        if let validX = validX as? [URL] {
            validY = mapFilenamesToLabels(validX)
        }  

        if let testX = testX as? [URL] {
            testY = mapFilenamesToLabels(testX)
        }

        if let specifiedClasses = self.classes {
            if !classes.isSubset(of: specifiedClasses) {
                let invalidClasses = Set.init(classes).subtracting(specifiedClasses)
                fatalError("Invalid classes found: \(invalidClasses)")
            }
        } else {
            self.classes = classes.sorted()
        }

        return self
    }

    @discardableResult
    func withFileLabelsFromCSV(builderId: String? = nil, file: String, filenameCol: Int = 0, 
                               labelsCol: Int = 1, hasHeaderRow: Bool = true, separator: Character = " ", 
                               filenameMatchOption: FilenameMatchOption = .WithoutSuffix,
                               singleLabel: Bool = false) -> DatasetBuilder<X,Y> {
        funcs.append((id: builderId ?? "FileLabelsFromCSV", 
                      fn: { self.setFileLabelsFromCSV(file: file, filenameCol: filenameCol, labelsCol: labelsCol, 
                                                      hasHeaderRow: hasHeaderRow, separator: separator, 
                                                      filenameMatchOption: filenameMatchOption, 
                                                      singleLabel: singleLabel) }))

        return self
    }

}