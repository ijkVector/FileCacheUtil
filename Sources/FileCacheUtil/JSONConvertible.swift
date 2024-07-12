//
//  File.swift
//  
//
//  Created by Иван Дроботов on 12.07.2024.
//

protocol JSONConvertible {

    static func parse(json: Any) -> Self?

    var json: Any { get }
}

