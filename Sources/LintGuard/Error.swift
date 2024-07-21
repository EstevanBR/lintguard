import protocol Foundation.LocalizedError

enum Error: Swift.Error, LocalizedError {
    case noMarkdownFilesPassed
    case fileDoesNotExist(_ path: String)
    case noDataFromFile(_ path: String)
    case noStringFromFile(_ path: String)
    case codeBlockOutOfDate(lineNumber: Int, language: String, markdownFilePath: String, filename: String, firstline: Int, lastline: Int, codeBlockFromMarkdown: String, codeBlockFromFile: String)

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
            
            case let .codeBlockOutOfDate(lineNumber, language, markdownFilePath, filename, firstline, lastline, codeBlockFromMarkdown, codeBlockFromFile):
                Color.red +
                """
                Code block @\(markdownFilePath):\(lineNumber) does not match code block @\(filename)#L\(firstline)-L\(lastline)\(Color.bgBlack.rawValue)
                ```\(language) lintguard: \(filename)#L\(firstline)-L\(lastline)
                \(codeBlockFromMarkdown.colorizedDifference(from: codeBlockFromFile, color: .bgBlack))\(Color.bgBlack.rawValue)
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
