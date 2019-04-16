// Copyright (c) 2019 Stephen Johnson. All rights reserved.

import Foundation

public extension DatasetBuilder {

    @discardableResult
    func setCocoJson(atPath: String, imagesFolder: String = "", type: FolderType = .Train,
                     largestBBoxOnly: Bool = false) -> DatasetBuilder<X,Y>  {

        let fm = FileManager.default

        guard let data = fm.contents(atPath: atPath),
            let jsonDict = try! JSONSerialization.jsonObject(with: data) as? [String: Any],
            let categories = jsonDict["categories"] as? [[String:Any]],
            let annotations = jsonDict["annotations"] as? [[String:Any]],
            let images = jsonDict["images"] as? [[String:Any]] else {
            return self
        }

        var classIdToClass = [Int:String]()
        var imageIdToBBoxes = [Int: [BoundingBox]]()
        var imageIdToFile = [Int: URL]()

        for category in categories {
            if let id = category["id"] as? Int, let name = category["name"] as? String {
                classIdToClass[id] = name
            }
        }

        let (left, top, width, height) = (0, 1, 2, 3)
        for annotation in annotations {
            guard let imageId = annotation["image_id"] as? Int,
                let classId = annotation["category_id"] as? Int,
                let bbox = annotation["bbox"] as? [Double] else {
                continue
            }

            if imageIdToBBoxes[imageId] == nil {
                imageIdToBBoxes[imageId] = [BoundingBox]()
            }
            imageIdToBBoxes[imageId]?.append(BoundingBox(cls: classIdToClass[classId]!,
                                                         top: bbox[top], left: bbox[left],
                                                         bottom: bbox[top] + bbox[height],
                                                         right: bbox[left] + bbox[width]))
        }

        for image in images {
            if let imageId = image["id"] as? Int, let _ = imageIdToBBoxes[imageId],
            let fileName = image["file_name"] as? String {
                imageIdToFile[imageId] = URL(fileURLWithPath: "\(imagesFolder)/\(fileName)")
            }
        }

        var imageFiles = [URL]()
        var bboxes = [[BoundingBox]]()
        var largestBBoxes = [BoundingBox]()
        for imageId in imageIdToFile.keys {
            imageFiles.append(imageIdToFile[imageId]!)
            let imageBBoxes = imageIdToBBoxes[imageId]!
            bboxes.append(imageBBoxes)
            largestBBoxes.append(imageBBoxes.max { $0.area < $1.area }! )
        }

        switch type {
            case .Train:
            trainX = imageFiles as? [X]
            if largestBBoxOnly {
                trainY = largestBBoxes as? [Y]
            } else {
                trainY = bboxes as? [Y]
            }
            trainFolder = imagesFolder

        case .Valid:
            validX = imageFiles as? [X]
            if largestBBoxOnly {
                validY = largestBBoxes as? [Y]
            } else {
                validY = bboxes as? [Y]
            }
            validFolder = imagesFolder

        case .Test:
            testX = imageFiles as? [X]
            if largestBBoxOnly {
                testY = largestBBoxes as? [Y]
            } else {
                testY = bboxes as? [Y]
            }
            testFolder = imagesFolder
        }

        if let classes = classes {
            var newClasses = Set<String>(classes)
            newClasses.formUnion(classIdToClass.values)
            self.classes = [String](newClasses).sorted()
        } else {
              classes = classIdToClass.values.sorted()
        }

        return self
    }

    @discardableResult
    func withCocoJson(builderId: String? = nil, atPath: String, imagesFolder: String = "", 
                      type: FolderType = .Train, largestBBoxOnly: Bool = false) -> DatasetBuilder<X,Y> {
        funcs.append((id: builderId ?? "CocoJson", 
                      fn: { self.setCocoJson(atPath: atPath, imagesFolder: imagesFolder, type: type,
                             largestBBoxOnly: largestBBoxOnly) }))

        return self
    }


}