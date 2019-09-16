import UIKit

class SearchViewController: UIViewController {

    @IBOutlet weak var sbSearch: UISearchBar!
    @IBOutlet weak var tvResult: UITableView!
    
    var searchResults = [SearchResult]()
    private var hasSearched = false
    private var isLoading = false
    
    struct TableViewCellIdentifier{
        static let searchResultCell = "searchResultCell"
        static let nothingCell = "nothingCell"
        static let loadingCell = "loadingCell"
    }
    
    private func setupSearchCell(){
        var nib = UINib(nibName: "SearchResultCell", bundle: nil)
        tvResult.register(nib, forCellReuseIdentifier: TableViewCellIdentifier.searchResultCell)
        tvResult.rowHeight = 80
        
        nib = UINib(nibName: "NothingCell", bundle: nil)
        tvResult.register(nib, forCellReuseIdentifier: TableViewCellIdentifier.nothingCell)
        
        nib = UINib(nibName: "LoadingCell", bundle: nil)
        tvResult.register(nib, forCellReuseIdentifier: TableViewCellIdentifier.loadingCell)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sbSearch.becomeFirstResponder()
        setupSearchCell()
    }
    
    private func iTunesUrl(searchText:String) -> URL{
        let escapedSearchText = searchText
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let urlString = String(format:"https://itunes.apple.com/search?term=%@", escapedSearchText)
        let url = URL(string: urlString)
        return url!
    }
    
    private func performStoreRequest(with url:URL)->String?{
        do{
            return try String(contentsOf: url, encoding: .utf8)
        }catch let error{
            print(error)
            return nil
        }
    }
    
    private func parseJson(json:String)->[String:Any]?{
        guard let data = json.data(using: .utf8, allowLossyConversion: false) else {return nil}
        
        do{
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]
        }catch let error{
            print(error)
            return nil
        }
    }
    
    private func showNetworkError(){
        let alert = UIAlertController(
            title: "Sorry ...",
            message: "There was an error reading from iTune, try again please",
            preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    private func kindForDisplay(kind: String)->String{
        switch kind{
        case "album": return "Album"
        case "audiobook": return "Audio Book"
        case "book": return "Book"
        case "ebook": return "E-Book"
        case "feature-movie": return "Movie"
        case "music-video": return "Music Video"
        case "podcast": return "Podcast"
        case "software": return "App"
        case "song": return "Song"
        case "tv-episode": return "TV Episode"
        default: return kind
        }
    }
    
    private func parseTrackToSearchResult(dict:[String:Any])->SearchResult{
        let searchResult = SearchResult()
        searchResult.name = dict["trackName"] as! String
        searchResult.artistName = dict["artistName"] as! String
        searchResult.artworkSmallUrl = dict["artworkUrl60"] as! String
        searchResult.artworkLargeUrl = dict["artworkUrl100"] as! String
        searchResult.kind = kindForDisplay(kind: dict["kind"] as! String)
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
                }
            }
            if let result = searchResult{
                searchResults.append(result)
            }
        }
        return searchResults
    }

}

extension SearchViewController:UISearchBarDelegate{
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if !searchBar.text!.isEmpty{
            searchBar.resignFirstResponder()
            
            searchResults = []
            isLoading = true
            tvResult.reloadData()
            hasSearched = true
            let text = searchBar.text!
            
            DispatchQueue.global().async {
                let url = self.iTunesUrl(searchText: text)
                if let jsonString = self.performStoreRequest(with: url){
                    if let jsonDictionary = self.parseJson(json: jsonString){
                        self.searchResults = self.parseDict(dict: jsonDictionary)
                        self.searchResults.sort(by: <)
                        
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.tvResult.reloadData()
                        }
                        return
                    }
                }
                DispatchQueue.main.async {
                    self.showNetworkError()
                }
            }
            
        }
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
}

extension SearchViewController:UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isLoading{
            return 1
        }else if !hasSearched{
            return 0
        }else if searchResults.count == 0{
            return 1
        }else {
            return searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isLoading{
            let cell = tableView.dequeueReusableCell(
                withIdentifier: TableViewCellIdentifier.loadingCell, for: indexPath)
            let spinner = cell.viewWithTag(99) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
            
        }else if searchResults.count == 0{
            let identifier = TableViewCellIdentifier.nothingCell
            return tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        }else{
            let identifier = TableViewCellIdentifier.searchResultCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier,
                                                     for: indexPath) as! SearchResultCell
            let searchResult = searchResults[indexPath.row]
            cell.lbName.text = searchResult.name
            if searchResult.artistName.isEmpty{
                cell.lbArtistName.text = "Unknown"
            }else{
                cell.lbArtistName.text = String(format: "%@ (%@)",
                                                searchResult.artistName, searchResult.kind)
            }
            return cell
        }
        
    }
    
}

extension SearchViewController:UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if searchResults.count == 0 || isLoading{
            return nil
        }else{
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
