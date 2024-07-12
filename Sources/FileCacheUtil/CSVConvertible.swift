//
//  File.swift
//  
//
//  Created by Иван Дроботов on 12.07.2024.
//

public protocol CSVConvertible {

    static func parse(csv: Any, with separator: String) -> Self?

    static func getHeader(with separator: String) -> String

    func csv(with separator: String) -> String
}
