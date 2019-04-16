// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation

public extension DatasetBuilder {

    @discardableResult
    func setFilesFromSingleFolder(folder: String, extensions: Set<String>? = nil, excludeExtensions: Bool = false, 
                                  folderType: FolderType = .Train) -> DatasetBuilder<X,Y> {

        let url = URL.init(fileURLWithPath: folder)
        let x = getFolderFiles(url: url, extensions: extensions, 
                               excludeExtensions: excludeExtensions) as? [X]

        switch folderType {
        case .Train: 
            trainX = x
            trainFolder = url.path
        case .Valid: 
            validX = x
            validFolder = url.path
        case .Test: 
            testX = x
            testFolder = url.path
        }

        return self
    }

    @discardableResult
    func withFilesFromSingleFolder(builderId: String? = nil, folder: String, 
                                   extensions: Set<String>? = nil, excludeExtensions: Bool = false, 
                                   folderType: FolderType = .Train) -> DatasetBuilder<X,Y> {
        funcs.append((id: builderId ?? "withFilesFromSingleFolder", 
                      fn: { self.setFilesFromSingleFolder(folder: folder, extensions: extensions, 
                                                          excludeExtensions: excludeExtensions,
                                                          folderType: folderType) }))

        return self
    }

    @discardableResult
    func setFilesFromFolders(parentFolder: String, extensions: Set<String>? = nil, 
                             excludeExtensions: Bool = false, trainFolder: String = "train",
                             validFolder: String = "valid", testFolder: String = "test") 
                             -> DatasetBuilder<X,Y> {

        let fm = FileManager.default

        let trainFolder = "\(parentFolder)/\(trainFolder)"
        if fm.fileExists(atPath: trainFolder) {
            setFilesFromSingleFolder(folder: trainFolder, extensions: extensions, 
                                     excludeExtensions: excludeExtensions)
        }

        let validFolder = "\(parentFolder)/\(validFolder)"
        if fm.fileExists(atPath: validFolder) {
            setFilesFromSingleFolder(folder: validFolder, extensions: extensions, 
                                     excludeExtensions: excludeExtensions, folderType: .Valid)
        }

        let testFolder = "\(parentFolder)/\(testFolder)"
        if fm.fileExists(atPath: testFolder) {
            setFilesFromSingleFolder(folder: testFolder, extensions: extensions, 
                                     excludeExtensions: excludeExtensions, folderType: .Test)
        }

        return self
    }

    @discardableResult
    func withFilesFromFolders(builderId: String? = nil, parentFolder: String, 
                              extensions: Set<String>? = nil, excludeExtensions: Bool = false, 
                              trainFolder: String = "train", validFolder: String = "valid", 
                              testFolder: String = "test") -> DatasetBuilder<X,Y> {
        funcs.append((id: builderId ?? "FilesFromFolders", 
                      fn: { self.setFilesFromFolders(parentFolder: parentFolder, extensions: extensions, 
                                                     excludeExtensions: excludeExtensions, trainFolder: trainFolder,
                                                     validFolder: validFolder, testFolder: testFolder) }))
        
        return self                    
    }

    @discardableResult
    func setFileLabelsWithMapper(includeTest: Bool = false, 
                                 mapper: @escaping (URL) -> String) -> DatasetBuilder<X,Y> {

        var classes = Set<String>()
        func map(_ x: [URL]) -> [String] {
            let labels = x.map { mapper($0) }
            classes.formUnion(labels)
            return labels
        }

        if let trainX = trainX as? [URL] {
            trainY = map(trainX) as? [Y]
        }

        if let validX = validX as? [URL] {
            validY = map(validX) as? [Y]
        }
        
        if includeTest, let testX = testX as? [URL] {
            testY = map(testX) as? [Y]
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
    func setFileLabelsOfParentFolder(includeTest: Bool = false) -> DatasetBuilder<X,Y> {
        return setFileLabelsWithMapper(includeTest: includeTest) { 
            $0.pathComponents[$0.pathComponents.count - 2]
        }
    }

    @discardableResult
    func withFileLabelsOfParentFolder(builderId: String? = nil, 
                                      includeTest: Bool = false) -> DatasetBuilder<X,Y> {
        funcs.append((id: builderId ?? "FileLabelsOfParentFolder", 
                      fn: { self.setFileLabelsOfParentFolder(includeTest: includeTest) }))

        return self
    }

    @discardableResult
    func setFileLabelsFromFilename(includeTest: Bool = false,
                                   mapper: @escaping (String) -> String) -> DatasetBuilder<X,Y> {
        return setFileLabelsWithMapper(includeTest: includeTest) { 
            mapper($0.lastPathComponent)
        }
    }

    @discardableResult
    func withFileLabelsFromFilename(builderId: String? = nil, at: Int? = nil, includeTest: Bool = false,
                                    mapper: @escaping (String) -> String) -> DatasetBuilder<X,Y> {
                                        
        addBuilderFunc(id: builderId ?? "FileLabelsFromFilename", at: at) {
            self.setFileLabelsFromFilename(includeTest: includeTest, mapper: mapper) 
        }

        return self
    }
}