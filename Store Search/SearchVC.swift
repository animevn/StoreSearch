import UIKit

class SearchViewController: UIViewController {

    @IBOutlet weak var sbSearch: UISearchBar!
    @IBOutlet weak var tvResult: UITableView!
    @IBOutlet weak var scTitles: UISegmentedControl!
    
    var landScape:LandscapeViewController?
    let search = Search()
    
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
        
        let tintColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 1)
        scTitles.tintColor = tintColor
        sbSearch.becomeFirstResponder()
        setupSearchCell()
    }

}

extension SearchViewController:UISearchBarDelegate{
    
    private func showNetworkError(){
        let alert = UIAlertController(
            title: "Sorry ...",
            message: "There was an error reading from iTune, try again please",
            preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    private func showAlertIfSearchWrong(){
        DispatchQueue.main.async {
            self.search.hasSearched = false
            self.search.isLoading = false
            self.tvResult.reloadData()
            self.showNetworkError()
        }
    }
    
    private func performeSearch(){
        
        search.performeSearch(text: sbSearch.text!, category: scTitles.selectedSegmentIndex){
            if !$0{
                self.showNetworkError()
            }
            self.tvResult.reloadData()
        }
        tvResult.reloadData()
        sbSearch.resignFirstResponder()
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
        
        if search.isLoading{
            return 1
        }else if !search.hasSearched{
            return 0
        }else if search.searchResults.count == 0{
            return 1
        }else {
            return search.searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if search.isLoading{
            let cell = tableView.dequeueReusableCell(
                withIdentifier: TableViewCellIdentifier.loadingCell, for: indexPath)
            let spinner = cell.viewWithTag(99) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
            
        }else if search.searchResults.count == 0{
            let identifier = TableViewCellIdentifier.nothingCell
            return tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        }else{
            let identifier = TableViewCellIdentifier.searchResultCell
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier,
                                                     for: indexPath) as! SearchResultCell
            let searchResult = search.searchResults[indexPath.row]
            cell.configureCell(searchResult: searchResult)
            return cell
        }
    }
}

extension SearchViewController:UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if search.searchResults.count == 0 || search.isLoading{
            return nil
        }else{
            return indexPath
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail"{
            let destination = segue.destination as! DetailViewController
            let indexPath = sender as! IndexPath
            let searchResult = search.searchResults[indexPath.row]
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
            controller.search = search
            view.addSubview(controller.view)
            addChild(controller)
            
            coordinator.animate(alongsideTransition: {_ in
                controller.view.alpha = 1
                self.sbSearch.resignFirstResponder()
                if self.presentedViewController != nil{
                    self.dismiss(animated: true, completion: nil)
                }
            }, completion: {_ in
                controller.didMove(toParent: self)
            })
        }
    }
    
    private func hideLandscape(coordinator: UIViewControllerTransitionCoordinator){
        if let controller = landScape{
            controller.willMove(toParent: nil)
            coordinator.animate(alongsideTransition: {_ in
                controller.view.alpha = 0
            }, completion: {_ in
                controller.view.removeFromSuperview()
                controller.removeFromParent()
                self.landScape = nil
            })
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
