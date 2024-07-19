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