//
//  File.swift
//  
//
//  Created by Иван Дроботов on 12.07.2024.
//

import Foundation

public enum FileCacheError: Error {
    case itemAlreadyExists
    case documentDirectoryNotFound
    case invalidJSON
    case invalidCSV
    case fileNotFound
}

public enum FileFormat {
    case json
    case csv
}

@available(macOS 10.15, *)
public final class FileCache<T: JSONConvertible & CSVConvertible & Identifiable> {
    
    private(set) var todoItems: [T] = []
    
    public init(todoItems: [T]) {
        self.todoItems = todoItems
    }

    public func add(item: T) throws {
        guard todoItems.first(where: { $0.id == item.id }) == nil else {
            throw FileCacheError.itemAlreadyExists
        }

        todoItems.append(item)
    }

    @discardableResult public func removeItem(by id: T.ID) -> T? {
        guard let index = todoItems.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return todoItems.remove(at: index)
    }

    public func save(to file: String, with format: FileFormat = .json, by separator: String = ",") throws {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw FileCacheError.documentDirectoryNotFound
        }
        let filePath = dir.appendingPathComponent(file)

        switch format {
        case .json:
            let jsonArray = todoItems.map { $0.json }
            guard JSONSerialization.isValidJSONObject(jsonArray) else {
                throw FileCacheError.invalidJSON
            }
            try jsonArray.description.write(to: filePath, atomically: true, encoding: .utf8)
        case .csv:
            let csvData = ([T.getHeader(with: separator)] + todoItems.map { $0.csv(with: separator) })
                .joined(separator: "/n")
            try csvData.write(to: filePath, atomically: true, encoding: .utf8)
        }
    }

    public func load(from file: String, with format: FileFormat = .json, by separator: String = ",") throws {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw FileCacheError.documentDirectoryNotFound
        }
        let filePath = dir.appendingPathComponent(file)
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            throw FileCacheError.fileNotFound
        }

        switch format {
        case .json:
            let data = try Data(contentsOf: filePath)
            guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
                throw FileCacheError.invalidJSON
            }
            todoItems = jsonArray.compactMap { T.parse(json: $0) }
        case .csv:
            guard let data = try? String(contentsOf: filePath) else {
                throw FileCacheError.invalidCSV
            }
            var csvRows = data.components(separatedBy: "/n")
            csvRows.removeFirst()
            todoItems = csvRows.compactMap { T.parse(csv: $0, with: separator) }
        }
    }
}

