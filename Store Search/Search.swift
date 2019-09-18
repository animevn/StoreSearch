import Foundation

class Search{
    
    var searchResults = [SearchResult]()
    var hasSearched = false
    var isLoading = false
    var dataTask:URLSessionDataTask? = nil
    typealias SearchComplete = (Bool)->Void
    
    private let stringUrl = "https://itunes.apple.com/search?term=%@&limit=200&entity=%@"
    
   
    
    private func iTunesUrl(searchText:String, category:Int) -> URL{
        let categoryName:String
        switch category{
        case 1: categoryName = "musicTrack"
        case 2: categoryName = "software"
        case 3: categoryName = "ebook"
        default: categoryName = ""
        }
        let escapedSearchText = searchText.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed)!
        let urlString = String(format: stringUrl, escapedSearchText, categoryName)
        let url = URL(string: urlString)
        return url!
    }
    
    private func parseJson(data:Data)->[String:Any]?{
        do{
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]
        }catch let error{
            print(error)
            return nil
        }
    }
    
    
    private func parseTrackToSearchResult(dict:[String:Any])->SearchResult{
        let searchResult = SearchResult()
        searchResult.name = dict["trackName"] as! String
        searchResult.artistName = dict["artistName"] as! String
        searchResult.artworkSmallUrl = dict["artworkUrl60"] as! String
        searchResult.artworkLargeUrl = dict["artworkUrl100"] as! String
        searchResult.kind = dict["kind"] as! String
        searchResult.storeUrl = dict["trackViewUrl"] as! String
        searchResult.currency = dict["currency"] as! String
        if let price = dict["trackPrice"] as? Double{
            searchResult.price = price
        }
        if let genre = dict["primaryGenreName"] as? String{
            searchResult.genre = genre
        }
        
        return searchResult
    }
    
    private func parseSoftwareToSearchResult(dict:[String:Any])->SearchResult{
        let searchResult = SearchResult()
        searchResult.name = dict["trackName"] as! String
        searchResult.artistName = dict["artistName"] as! String
        searchResult.artworkSmallUrl = dict["artworkUrl60"] as! String
        searchResult.artworkLargeUrl = dict["artworkUrl100"] as! String
        searchResult.storeUrl = dict["trackViewUrl"] as! String
        searchResult.kind = dict["kind"] as! String
        searchResult.currency = dict["currency"] as! String
        
        if let price = dict["price"] as? Double {
            searchResult.price = price
        }
        if let genre = dict["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    private func parseAudioBookToSearchResult(dict:[String:Any])->SearchResult{
        let searchResult = SearchResult()
        searchResult.name = dict["collectionName"] as! String
        searchResult.artistName = dict["artistName"] as! String
        searchResult.artworkSmallUrl = dict["artworkUrl60"] as! String
        searchResult.artworkLargeUrl = dict["artworkUrl100"] as! String
        searchResult.storeUrl = dict["collectionViewUrl"] as! String
        searchResult.kind = "Audiobook"
        searchResult.currency = dict["currency"] as! String
        
        if let price = dict["collectionPrice"] as? Double {
            searchResult.price = price
        }
        if let genre = dict["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    private func parseEbookToSearchResult(dict:[String:Any])->SearchResult{
        let searchResult = SearchResult()
        searchResult.name = dict["trackName"] as! String
        searchResult.artistName = dict["artistName"] as! String
        searchResult.artworkSmallUrl = dict["artworkUrl60"] as! String
        searchResult.artworkLargeUrl = dict["artworkUrl100"] as! String
        searchResult.storeUrl = dict["trackViewUrl"] as! String
        searchResult.kind = dict["kind"] as! String
        searchResult.currency = dict["currency"] as! String
        
        if let price = dict["price"] as? Double {
            searchResult.price = price
        }
        if let genres: Any = dict["genres"] {
            searchResult.genre = (genres as! [String]).joined(separator: ", ")
        }
        return searchResult
    }
    
    private func parseDict(dict:[String:Any])->[SearchResult]{
        
        guard let array = dict["results"] as? [Any] else {return []}
        
        searchResults = []
        for item in array{
            
            var searchResult:SearchResult?
            if let resultDict = item as? [String:Any]{
                if  let wrapperType = resultDict["wrapperType"] as? String{
                    switch wrapperType{
                    case "track":
                        searchResult = parseTrackToSearchResult(dict: resultDict)
                    case "audiobook":
                        searchResult = parseAudioBookToSearchResult(dict: resultDict)
                    case "software":
                        searchResult = parseSoftwareToSearchResult(dict: resultDict)
                    default:
                        break
                    }
                }else if let kind = resultDict["kind"] as? String, kind == "ebook"{
                    searchResult = parseEbookToSearchResult(dict: resultDict)
                }
            }
            if let result = searchResult{
                searchResults.append(result)
            }
        }
        return searchResults
    }
    
    private func prepareSearch(){
        dataTask?.cancel()
        searchResults = []
        isLoading = true
        hasSearched = true
    }
    
    func performeSearch(text:String, category:Int, completion:@escaping SearchComplete){
        if !text.isEmpty{
            prepareSearch()
            
            let url = iTunesUrl(searchText:text, category:category)
            let session = URLSession.shared
            dataTask = session.dataTask(with: url, completionHandler: {
                data, response, error in
                var success = false
                if let error = error as NSError?, error.code == -999{
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200{
                    if let data = data, let jsonDictionary = self.parseJson(data: data){
                        self.searchResults = self.parseDict(dict: jsonDictionary)
                        self.searchResults.sort(by: <)
                        self.isLoading = false
                        success = true
                    }
                }
                if !success{
                    self.hasSearched = false
                    self.isLoading = false
                }
                
                DispatchQueue.main.async {
                    completion(success)
                }
            })
            dataTask?.resume()
        }
    }
    
}
