import UIKit

class SearchViewController: UIViewController {

    @IBOutlet weak var sbSearch: UISearchBar!
    @IBOutlet weak var tvResult: UITableView!
    
    var searchResults = [SearchResult]()
    private var hasSearched = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

}

extension SearchViewController:UISearchBarDelegate{
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        
        searchResults = []
        hasSearched = true
        
        if searchBar.text! != "Fabled"{
            for index in 0...5{
                guard let text = searchBar.text else {return}
                if !text.isEmpty{
                    let searchResult = SearchResult()
                    searchResult.name = String(format: "Result %d for", index)
                    searchResult.artistName = text
                    searchResults.append(searchResult)
                }
            }
        }
        
        tvResult.reloadData()
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
}

extension SearchViewController:UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if !hasSearched{
            return 0
        }else if searchResults.count == 0{
            return 1
        }else {
            return searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let identifier = "searchResultCell"
        var cell:UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil{
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        }
        
        if searchResults.count == 0{
            cell.textLabel!.text = "Nothing found"
            cell.detailTextLabel!.text = ""
        }else{
            let searchResult = searchResults[indexPath.row]
            cell.textLabel?.text = searchResult.name
            cell.detailTextLabel!.text = searchResult.artistName
        }
        return cell
    }
    
}

extension SearchViewController:UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if searchResults.count == 0{
            return nil
        }else{
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
