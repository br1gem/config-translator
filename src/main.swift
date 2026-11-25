import Foundation
import Parsing

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(EXIT_FAILURE)
}

let arguments = Array(CommandLine.arguments.dropFirst())

guard arguments.count == 2, arguments[0] == "--input", !arguments[1].isEmpty else {
    fail("Использование: ./run.sh --input <путь к файлу>")
}

let path = arguments[1]
let fileURL = URL(fileURLWithPath: path)
let source: String

do {
    source = try String(contentsOf: fileURL, encoding: .utf8)
} catch {
    fail("Не удалось прочитать файл «\(path)»: \(error.localizedDescription)")
}

do {
    _ = try ConfigParser().parse(source)
    print("Синтаксис корректен.")
} catch {
    fail("Синтаксическая ошибка в файле «\(path)»:\n\(error)")
}