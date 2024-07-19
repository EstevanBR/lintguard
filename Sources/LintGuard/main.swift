import Foundation
import RegexBuilder

let markdownFilePaths = ProcessInfo.processInfo.arguments.filter { $0.hasSuffix(".md") }

enum Error: Swift.Error, LocalizedError {
    case noMarkdownFilesPassed
    case fileDoesNotExist(_ path: String)
    case noDataFromFile(_ path: String)
    case noStringFromFile(_ path: String)
    case codeBlockOutOfDate(language: String, markdownFilePath: String, filename: String, firstline: Int, lastline: Int, codeBlockFromMarkdown: String, codeBlockFromFile: String)

    var errorDescription: String? {
        switch self {
            case .noMarkdownFilesPassed:
                Color.yellow + "No markdown files passed"
            
            case .fileDoesNotExist(let path):
                Color.red + "File does not exist: \(path)"
            
            case .noDataFromFile(let path):
                Color.red + "No Data from file: \(path)"
            
            case .noStringFromFile(let path):
                Color.red + "No String from file: \(path)"
            
            case let .codeBlockOutOfDate(language, markdownFilePath, filename, firstline, lastline, codeBlockFromMarkdown, codeBlockFromFile):
                Color.red + """
                Following code block in \(markdownFilePath) is out of date:
                ```\(language) lintguard: \(filename)#L\(firstline)-L\(lastline)
                \(codeBlockFromMarkdown)
                ```
                
                Actual code block from file:
                ```
                \(codeBlockFromFile)
                ```
                """
        }
    }

    var recoverySuggestion: String? {
        switch self {
            case .noMarkdownFilesPassed: "Pass markdown files ending in .md to lintguard"
            case .fileDoesNotExist: "Did you mistype the filename?"
            case .noDataFromFile: nil
            case .noStringFromFile: nil
            case .codeBlockOutOfDate: "Update the code block"
        }
    }
}

do {
    guard !markdownFilePaths.isEmpty else {
        throw Error.noMarkdownFilesPassed
    }

    try markdownFilePaths.forEach { markdownFilePath in
        guard FileManager().fileExists(atPath: markdownFilePath) else {
            throw Error.fileDoesNotExist(markdownFilePath)
        }
    }

    let pattern = #"\`\`\`(?<language>[\w\s]+) lintguard: ?(?<filename>(?:[\/\w\-\.]+)*[\w\-\.]+)(#L(?<firstline>\d*))(-L(?<lastline>\d*))?[\t ]?\n(?<codeblock>([\s\S]*?))\n\`\`\`"#
    let regex = try NSRegularExpression(pattern: pattern)

    try markdownFilePaths.forEach { markdownFilePath in
        guard let markdownData = FileManager().contents(atPath: markdownFilePath) else {
            throw Error.noDataFromFile(markdownFilePath)
        }

        guard let markdownText = String(data: markdownData, encoding: .utf8) else { exit(1) }

        for match in regex.matches(in: markdownText, options: [], range: NSRange(location: 0, length: markdownText.utf8.count)) {
            guard let languageRange = Range(match.range(withName: "language"), in: markdownText),
                  let filenameRange = Range(match.range(withName: "filename"), in: markdownText),
                  let firstlineRange = Range(match.range(withName: "firstline"), in: markdownText),
                  let lastlineRange = Range(match.range(withName: "lastline"), in: markdownText),
                  let codeBlockRange = Range(match.range(withName: "codeblock"), in: markdownText)
            else {
                fatalError()
            }

            let language = String(markdownText[languageRange])
            let filename = String(markdownText[filenameRange])

            guard let firstline = Int(markdownText[firstlineRange]), let lastline = Int(markdownText[safe: lastlineRange] ?? markdownText[firstlineRange])
            else {
                fatalError("Could not get firstline or lastline")
            }

            let codeBlockFromMarkdown = String(markdownText[codeBlockRange])

            guard FileManager().fileExists(atPath: filename) else {
                throw Error.fileDoesNotExist(filename)
            }
            
            guard let fileData = FileManager().contents(atPath: filename), let fileString = String(data: fileData, encoding: .utf8) else {
                throw Error.noDataFromFile(filename)
            }

            let codeBlockFromFile = fileString
                .components(separatedBy: .newlines)[(firstline-1)...(lastline-1)]
                .joined(separator: "\n")
            
            guard codeBlockFromMarkdown == codeBlockFromFile else {
                throw Error.codeBlockOutOfDate(
                    language: language,
                    markdownFilePath: markdownFilePath,
                    filename: filename,
                    firstline: firstline,
                    lastline: lastline,
                    codeBlockFromMarkdown: codeBlockFromMarkdown,
                    codeBlockFromFile: codeBlockFromFile
                )
            }

            print(Color.green + "Code block in \(markdownFilePath): \(filename)#L\(firstline)-L\(lastline)")
        }
    }
} catch {
    if let error = error as? LocalizedError {
        if let errorDescription = error.errorDescription {
            print(errorDescription)
        } else {
            print(error.localizedDescription)
        }
        
        if let recoverySuggestion = error.recoverySuggestion {
            print("Recovery suggestion: " + recoverySuggestion)
        }
    } else {
        print(error.localizedDescription)
    }
    exit(1)
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    subscript (safe range: Range<Index>) -> SubSequence? {
        guard range.lowerBound >= startIndex, range.upperBound <= endIndex else {
            return nil
        }
        return self[range]
    }
}

enum Color: String {
    case reset = "\u{001B}[0;0m"
    // case black = "\u{001B}[0;30m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    // case blue = "\u{001B}[0;34m"
    // case magenta = "\u{001B}[0;35m"
    // case cyan = "\u{001B}[0;36m"
    // case white = "\u{001B}[0;37m"

    // case bgBlack = "\u{001B}[0;40m"
    // case bgRed = "\u{001B}[0;41m"
    // case bgGreen = "\u{001B}[0;42m"
    // case bgYellow = "\u{001B}[0;43m"
    // case bgBlue = "\u{001B}[0;44m"
    // case bgMagenta = "\u{001B}[0;45m"
    // case bgCyan = "\u{001B}[0;46m"
    // case bgWhite = "\u{001B}[0;47m"

    static func +(color: Color, text: String) -> String {
        return color.rawValue + text + Color.reset.rawValue
    }
}