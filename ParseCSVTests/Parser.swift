//
//  Parser.swift
//  Parser
//
//  Created by Ilya Belenkiy on 9/21/19.
//  Copyright © 2019 Ilya Belenkiy. All rights reserved.
//

public struct Parser<A> {
    @inline(__always)
    let run: (inout Substring.UnicodeScalarView) -> A?
}

extension Parser {
    @inline(__always)
    public func run(_ str: String, from startIndex: Int) -> (A?, String) {
        let strStartIndex = str.index(str.startIndex, offsetBy: startIndex)
        var substr = str.unicodeScalars[strStartIndex...]
        let res = run(&substr)
        return (res, String(substr))
    }

    @inline(__always)
    public func run(_ str: String) -> A? {
        let (value, remaining) = run(str, from: 0)
        guard let res = value, remaining.isEmpty else { return nil }
        return res
    }
}

public extension Parser {
    @inline(__always)
    func map<B>(_ f: @escaping (A) -> B) -> Parser<B> {
        Parser<B> { str in
            self.run(&str).map(f)
        }
    }

    @inline(__always)
    func flatMap<B>(_ f: @escaping (A) -> Parser<B>) -> Parser<B> {
        Parser<B> { str in
            let original = str
            let matchA = self.run(&str)
            let parserB = matchA.map(f)
            guard let matchB = parserB?.run(&str) else {
                str = original
                return nil
            }
            return matchB
        }
    }

    @inline(__always)
    init(wrapped: @escaping () -> Parser<A>) {
        self = Parser { str in
            return wrapped().run(&str)
        }
    }
}

public protocol Parsable: ExpressibleByStringLiteral {
    @inline(__always)
    static var parser: Parser<Self> { get }
}

extension Parsable {
    @inline(__always)
    public init(stringLiteral value: String) {
        self = Self.parser.run(value)! // swiftlint:disable:this force_unwrapping
    }

    @inline(__always)
    public init(extendedGraphemeClusterLiteral value: String) {
        self = Self.parser.run(value)! // swiftlint:disable:this force_unwrapping
    }

    @inline(__always)
    public init(unicodeScalarLiteral value: String) {
        self = Self.parser.run(value)! // swiftlint:disable:this force_unwrapping
    }

    @inline(__always)
    public static func parse(_ string: String) -> Self? {
        Self.parser.run(string)
    }
}
