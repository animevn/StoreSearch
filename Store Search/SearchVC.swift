import UIKit

class SearchViewController: UIViewController {

    @IBOutlet weak var sbSearch: UISearchBar!
    @IBOutlet weak var tvResult: UITableView!
    @IBOutlet weak var scTitles: UISegmentedControl!
    
    var landScape:LandscapeViewController?
    var searchResults = [SearchResult]()
    private var hasSearched = false
    private var isLoading = false
    private var dataTask:URLSessionDataTask?
    
    
    struct TableViewCellIdentifier{
        static let searchResultCell = "searchResultCell"
        static let nothingCell = "nothingCell"
        static let loadingCell = "loadingCell"
    }
    
    private func setupSearchCell(){
//        tvResult.layer.borderColor = UIColor.lightGray.cgColor
//        tvResult.layer.borderWidth = 0.5
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
        
        let tintColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 1)
        scTitles.tintColor = tintColor
//        scTitles.layer.cornerRadius = 0
//        scTitles.layer.borderColor = tintColor.cgColor
//        scTitles.layer.borderWidth = 0.1
        sbSearch.becomeFirstResponder()
        setupSearchCell()
    }
    
    private func iTunesUrl(searchText:String, category:Int) -> URL{
        let categoryName:String
        switch category{
        case 1: categoryName = "musicTrack"
        case 2: categoryName = "software"
        case 3: categoryName = "ebook"
        default: categoryName = ""
        }
        let escapedSearchText = searchText
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let urlString = String(format:"https://itunes.apple.com/search?term=%@&limit=200&entity=%@",
                               escapedSearchText, categoryName)
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
    
    private func parseJson(data:Data)->[String:Any]?{
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
}

extension SearchViewController:UISearchBarDelegate{
    
    private func prepareSearch(){
        sbSearch.resignFirstResponder()
        dataTask?.cancel()
        searchResults = []
        isLoading = true
        tvResult.reloadData()
        hasSearched = true
    }
    
    private func showAlertIfSearchWrong(){
        DispatchQueue.main.async {
            self.hasSearched = false
            self.isLoading = false
            self.tvResult.reloadData()
            self.showNetworkError()
        }
    }
    
    private func getResultFromSearchText(){
        let url = self.iTunesUrl(searchText:sbSearch.text!, category:scTitles.selectedSegmentIndex)
        let session = URLSession.shared
        self.dataTask = session.dataTask(with: url, completionHandler: {
            data, response, error in
            if let error = error as NSError?, error.code == -999{
                return
            }else if let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200{
                if let data = data, let jsonDictionary = self.parseJson(data: data){
                    self.searchResults = self.parseDict(dict: jsonDictionary)
                    self.searchResults.sort(by: <)
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.tvResult.reloadData()
                    }
                    return
                }
            }else{
                print("Error reading")
            }
            self.showAlertIfSearchWrong()
        })
        self.dataTask?.resume()
    }
    
    private func performeSearch(){
        if !sbSearch.text!.isEmpty{
            prepareSearch()
            getResultFromSearchText()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
       performeSearch()
    }
    
    @IBAction func onSegmentChanged(_ sender: UISegmentedControl) {
        performeSearch()
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
            cell.configureCell(searchResult: searchResult)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail"{
            let destination = segue.destination as! DetailViewController
            let indexPath = sender as! IndexPath
            let searchResult = searchResults[indexPath.row]
            destination.searchResult = searchResult
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "showDetail", sender: indexPath)
    }
    
}

extension SearchViewController{
    
    private func showLandscape(coordinator: UIViewControllerTransitionCoordinator){
        guard landScape == nil else {return}
        landScape = storyboard!.instantiateViewController(
            withIdentifier: "landscapeViewController") as? LandscapeViewController
        if let controller = landScape{
            controller.view.frame = view.bounds
            view.addSubview(controller.view)
            addChild(controller)
            controller.didMove(toParent: self)
        }
    }
    
    private func hideLandscape(coordinator: UIViewControllerTransitionCoordinator){
        if let controller = landScape{
            controller.willMove(toParent: nil)
            controller.view.removeFromSuperview()
            controller.removeFromParent()
            landScape = nil
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        switch newCollection.verticalSizeClass{
        case .compact: showLandscape(coordinator: coordinator)
        case .regular, .unspecified: hideLandscape(coordinator: coordinator)
        @unknown default:
            fatalError("Error")
        }
    }
    
}
