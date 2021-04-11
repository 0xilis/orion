import Foundation
import SwiftSyntax

public final class OrionParser {

    private enum Source {
        case file(URL)
        case contents(String)

        func parseSyntax(diagnosticEngine: DiagnosticEngine? = nil) throws -> SourceFileSyntax {
            switch self {
            case .file(let url):
                return try SyntaxParser.parse(url, diagnosticEngine: diagnosticEngine)
            case .contents(let contents):
                return try SyntaxParser.parse(source: contents, diagnosticEngine: diagnosticEngine)
            }
        }

        var filename: String {
            switch self {
            case .file(let url): return url.relativePath
            case .contents: return "<unknown>"
            }
        }
    }

    public let engine: DiagnosticEngine
    private let source: Source

    public init(file: URL, diagnosticEngine: OrionDiagnosticEngine = .init()) {
        source = .file(file)
        self.engine = diagnosticEngine.createEngine()
    }

    public init(contents: String, diagnosticEngine: OrionDiagnosticEngine = .init()) {
        source = .contents(contents)
        self.engine = diagnosticEngine.createEngine()
    }

    public func parse() throws -> OrionData {
        let syntax = try source.parseSyntax(diagnosticEngine: engine)
        let converter = SourceLocationConverter(file: source.filename, tree: syntax)
        let visitor = OrionVisitor(diagnosticEngine: engine, sourceLocationConverter: converter)
        visitor.walk(syntax)
        guard !visitor.didFail else {
            throw OrionFailure()
        }
        return visitor.data
    }

}
