import Foundation

extension LintGuard {
    struct CodeBlock {
        let lineNumber: Int
        let language: String
        let filename: String
        let firstline: Int
        let lastline: Int
        let codeblock: String

        init(match: NSTextCheckingResult, in markdownText: String) {
            guard let languageRange = Range(match.range(withName: "language"), in: markdownText),
                let filenameRange = Range(match.range(withName: "filename"), in: markdownText),
                let firstlineRange = Range(match.range(withName: "firstline"), in: markdownText),
                let codeBlockRange = Range(match.range(withName: "codeblock"), in: markdownText),
                let thisRange = Range(NSRange(location: 0, length: match.range.location), in: markdownText) else {
                fatalError()
            }

            self.lineNumber = String(markdownText[thisRange]).components(separatedBy: .newlines).count

            self.language = String(markdownText[languageRange])
            self.filename = String(markdownText[filenameRange])

            let lastlineRange = Range(match.range(withName: "lastline"), in: markdownText)
            guard let firstline = Int(markdownText[firstlineRange]), let lastline = Int(markdownText[lastlineRange ?? firstlineRange]) else {
                fatalError("Could not get firstline or lastline")
            }

            self.firstline = firstline
            self.lastline = lastline

            let codeblock = String(markdownText[codeBlockRange])
            self.codeblock = codeblock
        }
    }
}
