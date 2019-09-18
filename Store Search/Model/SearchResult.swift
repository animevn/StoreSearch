import Foundation

class SearchResult{
    var name = ""
    var artistName = ""
    var artworkSmallUrl = ""
    var artworkLargeUrl = ""
    var storeUrl = ""
    var kind = ""
    var currency = ""
    var price = 0.0
    var genre = ""
    
    static func <(lhs:SearchResult, rhs:SearchResult)->Bool{
        return lhs.name.localizedCompare(rhs.name) == .orderedAscending
    }
    
}
