import Parsing

indirect enum ConfigValue: Equatable {
    case number(String)
    case string(String)
    case array([ConfigValue])
    case dictionary([ConfigEntry])
    case reference(String)
}

struct ConfigEntry: Equatable {
    let name: String
    let value: ConfigValue
}

struct ConfigDocument: Equatable {
    let constants: [ConfigEntry]
    let root: ConfigValue
}

struct ConfigParser: Parser {
    var body: some Parser<Substring, ConfigDocument> {
        Parse { result in
            ConfigDocument(constants: result.0, root: result.1)
        } with: {
            whitespace
            Many { constant }
            ValueParser()
            End()
        }
    }

    private var constant: some Parser<Substring, ConfigEntry> {
        Parse { result in
            ConfigEntry(name: result.0, value: result.1)
        } with: {
            "const"
            Skip { Prefix<Substring>(1...) { $0.isWhitespace } }
            name
            symbol("=")
            ValueParser()
        }
    }
}

private struct ValueParser: Parser {
    var body: some Parser<Substring, ConfigValue> {
        Parse(input: Substring.self) {
            OneOf {
                number
                quotedString
                array
                dictionary
                reference
            }
            whitespace
        }
    }

    private var number: some Parser<Substring, ConfigValue> {
        Parse(input: Substring.self) {
            Prefix<Substring>(while: isDigit)
            "."
            Prefix<Substring>(1..., while: isDigit)
        }
        .map { whole, fraction in
            ConfigValue.number(String(whole) + "." + String(fraction))
        }
    }

    private var quotedString: some Parser<Substring, ConfigValue> {
        Parse(input: Substring.self) {
            "\""
            Prefix<Substring> { $0 != "\"" && !$0.isNewline }
            "\""
        }
        .map { ConfigValue.string(String($0)) }
    }

    private var array: some Parser<Substring, ConfigValue> {
        Parse(input: Substring.self) {
            symbol("array")
            symbol("(")
            Many {
                ValueParser()
            } separator: {
                symbol(",")
            } terminator: {
                symbol(")")
            }
        }
        .map(ConfigValue.array)
    }

    private var dictionary: some Parser<Substring, ConfigValue> {
        Parse(input: Substring.self) {
            symbol("@{")
            Many {
                entry
            } terminator: {
                symbol("}")
            }
        }
        .map(ConfigValue.dictionary)
    }

    private var entry: some Parser<Substring, ConfigEntry> {
        Parse { result in
            ConfigEntry(name: result.0, value: result.1)
        } with: {
            name
            symbol("=")
            ValueParser()
            symbol(";")
        }
    }

    private var reference: some Parser<Substring, ConfigValue> {
        Parse(input: Substring.self) {
            "|"
            Prefix<Substring>(1..., while: isUppercaseLetter)
            "|"
        }
        .map { ConfigValue.reference(String($0)) }
    }
}

private var whitespace: some Parser<Substring, Void> {
    Skip { Prefix<Substring> { $0.isWhitespace } }
}

private var name: some Parser<Substring, String> {
    Parse(input: Substring.self) {
        Prefix<Substring>(1..., while: isUppercaseLetter)
        whitespace
    }
    .map { String($0) }
}

private func symbol(_ literal: String) -> some Parser<Substring, Void> {
    Parse(input: Substring.self) {
        literal
        whitespace
    }
}

private func isDigit(_ character: Character) -> Bool {
    guard let byte = character.asciiValue else { return false }
    return (48...57).contains(byte)
}

private func isUppercaseLetter(_ character: Character) -> Bool {
    guard let byte = character.asciiValue else { return false }
    return (65...90).contains(byte)
}