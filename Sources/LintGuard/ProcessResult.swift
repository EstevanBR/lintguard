struct ProcessResult: CustomStringConvertible {
    let filePath: String
    let upToDate: Bool
    let codeblock: LintGuard.CodeBlock

    var description: String {
        (upToDate ? Color.green : Color.red) + "Code block in \(filePath):\(codeblock.lineNumber) referencing \(codeblock.filename)#L\(codeblock.firstline)-L\(codeblock.lastline)"
    }
}
