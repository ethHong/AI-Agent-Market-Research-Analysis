import Foundation

/// Backend-neutral tool-calling contract (doc 04 §7).
///
/// On the AFM path, tools are additionally wrapped as FoundationModels `Tool`
/// conformances in the app layer (guided generation makes calls structurally
/// valid for free). On the MLX path the model emits JSON and `ToolCallParser`
/// extracts/validates it — same tool implementations either way.
public struct ToolSpec: Equatable, Codable, Sendable {
    public let name: String
    public let description: String
    /// JSON-schema-ish parameter description given to the model.
    public let parameters: [Parameter]

    public struct Parameter: Equatable, Codable, Sendable {
        public let name: String
        public let type: String
        public let required: Bool
        public let description: String

        public init(name: String, type: String, required: Bool, description: String) {
            self.name = name
            self.type = type
            self.required = required
            self.description = description
        }
    }

    public init(name: String, description: String, parameters: [Parameter]) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

/// A parsed tool invocation from model output.
public struct ToolCall: Equatable, Sendable {
    public let name: String
    public let arguments: [String: JSONValue]
}

/// Minimal JSON value model (Foundation's JSONSerialization types aren't Sendable).
public enum JSONValue: Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
    public var numberValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }
}

public enum ToolCallParseError: Error, Equatable, Sendable {
    case noJSONObjectFound
    case malformedJSON
    case missingToolName
    case unknownTool(String)
    case missingRequiredArgument(tool: String, argument: String)
}

/// Extracts a `{"tool": "...", "arguments": {...}}` object from free-form model
/// text (MLX path). Tolerates surrounding prose and markdown fences; validates
/// against the registered specs.
public struct ToolCallParser: Sendable {
    public let specs: [ToolSpec]

    public init(specs: [ToolSpec]) {
        self.specs = specs
    }

    public func parse(_ modelOutput: String) throws -> ToolCall {
        guard let jsonRange = Self.firstJSONObjectRange(in: modelOutput) else {
            throw ToolCallParseError.noJSONObjectFound
        }
        let jsonText = String(modelOutput[jsonRange])
        guard let data = jsonText.data(using: .utf8),
              let raw = try? JSONSerialization.jsonObject(with: data),
              let object = raw as? [String: Any] else {
            throw ToolCallParseError.malformedJSON
        }
        guard let name = object["tool"] as? String ?? object["name"] as? String else {
            throw ToolCallParseError.missingToolName
        }
        guard let spec = specs.first(where: { $0.name == name }) else {
            throw ToolCallParseError.unknownTool(name)
        }
        let rawArguments = object["arguments"] as? [String: Any] ?? [:]
        let arguments = rawArguments.mapValues(Self.jsonValue)
        for parameter in spec.parameters where parameter.required {
            if arguments[parameter.name] == nil {
                throw ToolCallParseError.missingRequiredArgument(tool: name, argument: parameter.name)
            }
        }
        return ToolCall(name: name, arguments: arguments)
    }

    /// Finds the first balanced top-level `{...}` range, skipping strings.
    static func firstJSONObjectRange(in text: String) -> Range<String.Index>? {
        var depth = 0
        var start: String.Index?
        var inString = false
        var escaped = false
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]
            if inString {
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    inString = false
                }
            } else {
                switch character {
                case "\"":
                    inString = true
                case "{":
                    if depth == 0 { start = index }
                    depth += 1
                case "}":
                    depth -= 1
                    if depth == 0, let start {
                        return start..<text.index(after: index)
                    }
                default:
                    break
                }
            }
            index = text.index(after: index)
        }
        return nil
    }

    static func jsonValue(_ any: Any) -> JSONValue {
        switch any {
        case let value as String: return .string(value)
        case let value as Bool: return .bool(value)
        case let value as NSNumber:
            // JSONSerialization yields NSNumber for both bools and numbers; the
            // Bool case above catches direct Swift bools, and objCType "c"
            // identifies boolean NSNumbers portably (Darwin + corelibs-foundation).
            if String(cString: value.objCType) == "c" { return .bool(value.boolValue) }
            return .number(value.doubleValue)
        case let value as [Any]: return .array(value.map(jsonValue))
        case let value as [String: Any]: return .object(value.mapValues(jsonValue))
        default: return .null
        }
    }
}
