import Foundation
import RegexBuilder

let markdownFilePaths = ProcessInfo.processInfo.arguments.filter { $0.hasSuffix(".md") }

print("Results:\n")


guard !markdownFilePaths.isEmpty else {
    throw Error.noMarkdownFilesPassed
}

let missingFiles = markdownFilePaths.filter { !FileManager().fileExists(atPath: $0) }

guard missingFiles.isEmpty else {
    missingFiles.forEach { path in
        print(Error.fileDoesNotExist(path).localizedDescription)
    }
    exit(1)
}

let pattern = #"```(?<language>[\w\s]+) lintguard: ?(?<filename>(?:[\/\w\-\.]+)*[\w\-\.]+)(#L(?<firstline>\d*))(-L(?<lastline>\d*))?[\t ]?\n(?<codeblock>([\s\S]*?))\n```"#
let regex = try NSRegularExpression(pattern: pattern)

var errors = [Swift.Error]()

markdownFilePaths.forEach { markdownFilePath in
    do {
        guard let markdownData = FileManager().contents(atPath: markdownFilePath) else {
            throw Error.noDataFromFile(markdownFilePath)
        }

        guard let markdownText = String(data: markdownData, encoding: .utf8) else {
            exit(1)
        }

        for match in regex.matches(in: markdownText, options: [], range: NSRange(location: 0, length: markdownText.utf8.count)) {
            guard let languageRange = Range(match.range(withName: "language"), in: markdownText),
                let filenameRange = Range(match.range(withName: "filename"), in: markdownText),
                let firstlineRange = Range(match.range(withName: "firstline"), in: markdownText),
                let codeBlockRange = Range(match.range(withName: "codeblock"), in: markdownText)
            else {
                print("WTF")
                continue
            }

            guard let thisRange = Range(NSRange(location: 0, length: match.range.location), in: markdownText) else {
                fatalError()
            }

            let lineNumber = String(markdownText[thisRange]).components(separatedBy: .newlines).count

            let language = String(markdownText[languageRange])
            let filename = String(markdownText[filenameRange])

            let lastlineRange = Range(match.range(withName: "lastline"), in: markdownText)
            guard let firstline = Int(markdownText[firstlineRange]), let lastline = Int(markdownText[lastlineRange ?? firstlineRange])
            else {
                fatalError("Could not get firstline or lastline")
            }

            let codeBlockFromMarkdown = String(markdownText[codeBlockRange])

            do {

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
                    print(Color.red + "Code block in \(markdownFilePath):\(lineNumber) referencing \(filename)#L\(firstline)-L\(lastline)")
                    throw Error.codeBlockOutOfDate(
                        lineNumber: lineNumber,
                        language: language,
                        markdownFilePath: markdownFilePath,
                        filename: filename,
                        firstline: firstline,
                        lastline: lastline,
                        codeBlockFromMarkdown: codeBlockFromMarkdown,
                        codeBlockFromFile: codeBlockFromFile
                    )
                }

                print(Color.green + "Code block in \(markdownFilePath):\(lineNumber) referencing \(filename)#L\(firstline)-L\(lastline)")
            } catch {
                errors.append(error)
            }
        }
    } catch {
        errors.append(error)
    }
}

if !errors.isEmpty {
    print("""
    
    Failures:
    
    """)
}

for error in errors {
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
}

guard errors.isEmpty else {
    exit(1)
}
