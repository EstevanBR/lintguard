extension String {
    func colorizedDifference(from: String, color: Color = .red, removalColor: Color = .bgRed, insertColor: Color = .bgGreen) -> String {
        color + difference(from: from).reduce(into: from) { partialResult, difference in
            switch difference {
            case let .remove(offset, element, _):
                let startIndex = from.startIndex
                let start = from.index(startIndex, offsetBy: offset)
                let end = from.index(startIndex, offsetBy: offset+1)
                partialResult.replaceSubrange(start..<end, with: removalColor.rawValue + String(element) + color.rawValue)

            case let .insert(offset, element, _):
                let startIndex = from.startIndex
                let end = from.index(startIndex, offsetBy: offset)
                partialResult.insert(contentsOf: insertColor.rawValue + String(element) + color.rawValue, at: end)
            }
        }
    }
}
