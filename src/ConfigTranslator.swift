import Foundation

enum TranslationError: LocalizedError {
    case duplicateConstant(String)
    case unknownConstant(String)
    case duplicateKey(String)

    var errorDescription: String? {
        switch self {
        case .duplicateConstant(let name):
            return "Константа «\(name)» уже объявлена."
        case .unknownConstant(let name):
            return "Константа «\(name)» ещё не объявлена."
        case .duplicateKey(let name):
            return "Ключ «\(name)» повторяется в словаре."
        }
    }
}

struct ConfigTranslator {
    func translate(_ document: ConfigDocument) throws -> String {
        var constants: [String: String] = [:]

        for declaration in document.constants {
            guard constants[declaration.name] == nil else {
                throw TranslationError.duplicateConstant(declaration.name)
            }
            constants[declaration.name] = try render(
                declaration.value,
                constants: constants
            )
        }

        return try render(document.root, constants: constants)
    }

    private func render(_ value: ConfigValue, constants: [String: String]) throws -> String {
        switch value {
        case .number(let literal):
            let parts = literal.split(separator: ".", omittingEmptySubsequences: false)
            let whole = parts[0].drop(while: { $0 == "0" })
            return (whole.isEmpty ? "0" : String(whole)) + "." + parts[1]

        case .string(let text):
            let encoded = try JSONEncoder().encode(text)
            return String(decoding: encoded, as: UTF8.self)

        case .array(let values):
            let elements = try values.map { try render($0, constants: constants) }
            return "[" + elements.joined(separator: ", ") + "]"

        case .dictionary(let entries):
            return try renderDictionary(entries, constants: constants)

        case .reference(let name):
            guard let json = constants[name] else {
                throw TranslationError.unknownConstant(name)
            }
            return json
        }
    }

    private func renderDictionary(_ entries: [ConfigEntry], constants: [String: String]) throws -> String {
        var names: Set<String> = []

        let members = try entries.map { entry in
            guard names.insert(entry.name).inserted else {
                throw TranslationError.duplicateKey(entry.name)
            }
            let key = try render(.string(entry.name), constants: constants)
            let value = try render(entry.value, constants: constants)
            return key + ": " + value
        }

        return "{" + members.joined(separator: ", ") + "}"
    }
}