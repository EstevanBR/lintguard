import Foundation
import RegexBuilder

let markdownFilePaths = ProcessInfo.processInfo.arguments.filter { $0.hasSuffix(".md") }

guard !markdownFilePaths.isEmpty else {
    print(Color.yellow.rawValue + "No markdown files passed")
    exit(1)
}

markdownFilePaths.forEach { markdownFilePath in
    guard FileManager().fileExists(atPath: markdownFilePath) else {
        print(Color.red.rawValue + "file does not exist: \(markdownFilePath)")
        exit(1)
    }
}

let pattern = #"\`\`\`(?<language>[\w\s]+) lintguard: ?(?<filename>(?:[\/\w\-\.]+)*[\w\-\.]+)(#L(?<firstline>\d*))(-L(?<lastline>\d*))?[\t ]?\n(?<snippet>([\s\S]*?))\n\`\`\`"#
let regex = try NSRegularExpression(pattern: pattern)

markdownFilePaths.forEach { markdownFilePath in
    guard let markdownData = FileManager().contents(atPath: markdownFilePath) else { exit(1) }
    guard let markdownText = String(data: markdownData, encoding: .utf8) else { exit(1) }

    for match in regex.matches(in: markdownText, options: [], range: NSRange(location: 0, length: markdownText.utf8.count)) {
        guard let languageRange = Range(match.range(withName: "language"), in: markdownText),
              let filenameRange = Range(match.range(withName: "filename"), in: markdownText),
              let firstlineRange = Range(match.range(withName: "firstline"), in: markdownText),
              let lastlineRange = Range(match.range(withName: "lastline"), in: markdownText),
              let snippetRange = Range(match.range(withName: "snippet"), in: markdownText)
        else {
            fatalError()
        }

        let language = String(markdownText[languageRange])
        let filename = String(markdownText[filenameRange])

        guard let firstline = Int(markdownText[firstlineRange]),
              let lastline = Int(markdownText[safe: lastlineRange] ?? markdownText[firstlineRange])
        else {
            print(Color.red.rawValue + "Could not get firstline or lastline")
            exit(1)
        }

        let snippet = String(markdownText[snippetRange])//.split(separator: "\n").joined(separator: "\n")

        guard FileManager().fileExists(atPath: filename) else {
            print(Color.red.rawValue + "No file")
            exit(1)
        }
        
        guard let fileData = FileManager().contents(atPath: filename),
            let fileString = String(data: fileData, encoding: .utf8) else {
            print(Color.red.rawValue + "No file data")
            exit(1)
        }

        let snippetFromFile = fileString
            .components(separatedBy: .newlines)[(firstline-1)...(lastline-1)]
            //.split(separator: "\n")[(firstline-1)...(lastline-1)]
            .joined(separator: "\n")
        
        guard snippet == snippetFromFile else {
            print(Color.red.rawValue + "Snippet in \(markdownFilePath): \(filename)#L\(firstline)-L\(lastline)")
            print(Color.red.rawValue + """
            Failure: Snippets do not match
            From markdown:
            ```
            \(snippet)
            ```
            From file:
            ```
            \(snippetFromFile)
            ```
            """)
            exit(1)
        }

        print(Color.green.rawValue + "Snippet in \(markdownFilePath): \(filename)#L\(firstline)-L\(lastline)")
    }
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
}