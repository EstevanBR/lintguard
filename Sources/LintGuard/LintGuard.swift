import Foundation

@main
struct LintGuard {
    static private var errors = [Swift.Error]()
    static private var results = [ProcessResult]()
    
    static func main() throws {
        do {
            let markdownFilePaths = try getMarkdownFilePaths()
            try markdownFilePaths.forEach { path in
                let markdownText = try loadText(fromFilePath: path)
                do {
                    try process(markdownFilePath: path, markdownText: markdownText, results: &results, errors: &errors)
                } catch {
                    errors.append(error)
                }
            }
        } catch {
            errors.append(error)
        }

        print(results: results)
        printErrors(errors)

        exit(errors.isEmpty ? 0 : 1)
    }
}

private func getMarkdownFilePaths() throws -> [String] {
    let markdownFilePaths = ProcessInfo.processInfo.arguments.filter { $0.hasSuffix(".md") }

    guard !markdownFilePaths.isEmpty else {
        throw Error.noMarkdownFilesPassed
    }

    let missingFiles = markdownFilePaths.filter { !FileManager().fileExists(atPath: $0) }

    guard missingFiles.isEmpty else {
        throw Error.filesDoNotExist(missingFiles)
    }

    return markdownFilePaths
}

private func loadText(fromFilePath filePath: String) throws -> String {
    guard let data = FileManager().contents(atPath: filePath) else {
        throw Error.noDataFromFile(filePath)
    }

    guard let text = String(data: data, encoding: .utf8) else {
        throw Error.noStringFromFile(filePath)
    }

    return text
}

private func process(markdownFilePath: String, markdownText: String, results: inout [ProcessResult], errors: inout [Swift.Error]) throws {
    let pattern = #"```(?<language>[\w\s]+) lintguard: ?(?<filename>(?:[\/\w\-\.]+)*[\w\-\.]+)(#L(?<firstline>\d*))(-L(?<lastline>\d*))?[\t ]?\n(?<codeblock>([\s\S]*?))\n?```"#
    let regex = try NSRegularExpression(pattern: pattern)

    for match in regex.matches(in: markdownText, options: [], range: NSRange(location: 0, length: markdownText.utf8.count)) {
        let codeblock = LintGuard.CodeBlock(match: match, in: markdownText)

        do {
            guard FileManager().fileExists(atPath: codeblock.filename) else {
                throw Error.fileDoesNotExist(codeblock.filename)
            }
            
            guard let fileData = FileManager().contents(atPath: codeblock.filename), let fileString = String(data: fileData, encoding: .utf8) else {
                throw Error.noDataFromFile(codeblock.filename)
            }

            let codeBlockFromFile = fileString
                .components(separatedBy: .newlines)[(codeblock.firstline-1)...(codeblock.lastline-1)]
                .joined(separator: "\n")
            
            guard codeblock.codeblock == codeBlockFromFile else {
                results.append(.init(filePath: markdownFilePath, upToDate: false, codeblock: codeblock))
                throw Error.codeBlockOutOfDate(
                    lineNumber: codeblock.lineNumber,
                    language: codeblock.language,
                    markdownFilePath: markdownFilePath,
                    filename: codeblock.filename,
                    firstline: codeblock.firstline,
                    lastline: codeblock.lastline,
                    codeBlockFromMarkdown: codeblock.codeblock,
                    codeBlockFromFile: codeBlockFromFile
                )
            }

            results.append(.init(filePath: markdownFilePath, upToDate: true, codeblock: codeblock))
        } catch {
            errors.append(error)
        }
    }
}

private func print(results: [ProcessResult]) {
    guard !results.isEmpty else { return }
    print("Results:\n")
    print(results.map { $0.description }.joined(separator: "\n"))
}

private func printErrors(_ errors: [Swift.Error]) {
    var errorStrings = [String]()
    errors.forEach { error in
        if let error = error as? LocalizedError {
            if let errorDescription = error.errorDescription {
                errorStrings.append(errorDescription)
            } else {
                errorStrings.append(error.localizedDescription)
            }
            
            if let recoverySuggestion = error.recoverySuggestion {
                errorStrings.append(Color.yellow + "Recovery suggestion: \(recoverySuggestion)\n\n")
            }
        } else {
            errorStrings.append(error.localizedDescription)
        }
    }

    guard !errors.isEmpty else {
        return
    }
    
    print("""
    
    Failures:
    
    """)

    print(errorStrings.joined(separator: "\n"), terminator: "")
}
