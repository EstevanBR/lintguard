struct ProcessResult: CustomStringConvertible {
    let filePath: String
    let upToDate: Bool
    let codeblock: LintGuard.CodeBlock

    var description: String {
        (upToDate ? Color.green : Color.red) + "[\(upToDate ? "up to date" : "out of date")] \(filePath):\(codeblock.lineNumber)"
    }
}
