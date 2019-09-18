import UIKit

class LandscapeViewController:UIViewController{
    
    @IBOutlet weak var svLandscape: UIScrollView!
    @IBOutlet weak var pgLandscape: UIPageControl!
    
    var search:Search!
    private var firstTime = true
    private var downloadTasks = [URLSessionDownloadTask]()
    
    deinit {
        
        for downloadTask in downloadTasks{
            downloadTask.cancel()
        }
        
        print("The class \(type(of: self)) was remove from memory")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.removeConstraints(view.constraints)
        view.translatesAutoresizingMaskIntoConstraints = true
        
        pgLandscape.removeConstraints(pgLandscape.constraints)
        pgLandscape.translatesAutoresizingMaskIntoConstraints = true
        pgLandscape.numberOfPages = 0
        
        svLandscape.removeConstraints(svLandscape.constraints)
        svLandscape.translatesAutoresizingMaskIntoConstraints = true
        svLandscape.backgroundColor = UIColor(patternImage: UIImage(named: "LandscapeBackground")!)
        svLandscape.delegate = self
    }
    
    func loadImage(searchResult:SearchResult, button:UIButton){
        
        guard let url = URL(string: searchResult.artworkSmallUrl) else {return}
        let session = URLSession.shared
        let downloadTask = session.downloadTask(with: url, completionHandler: {
            [weak button] url, response, error in
            if error == nil, let url = url, let data = try? Data(contentsOf: url),
                let image = UIImage(data: data){
                
                DispatchQueue.main.async {
                    if let button = button{
                        button.setImage(image, for: .normal)
                    }
                }
            }
        })
        downloadTask.resume()
        downloadTasks.append(downloadTask)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "landscapeDetail"{
            if case .results(let list) = search.state{
                let destination = segue.destination as! DetailViewController
                let searchResult = list[(sender as! UIButton).tag - 2000]
                destination.searchResult = searchResult
            }
        }
    }
    
    @objc private func buttonPressed(sender:UIButton){
        performSegue(withIdentifier: "landscapeDetail", sender: sender)
    }
    
    private func tileButtons(searchResults:[SearchResult]){
        
        var columns = 5
        var rows = 3
        var width:CGFloat = 96
        var height:CGFloat = 88
        var marginX:CGFloat = 0
        var marginY:CGFloat = 20
        
        let buttonWidth:CGFloat = 82
        let buttonHeight:CGFloat = 82
        let paddingX = (width - buttonWidth)/2
        let paddingY = (height - buttonHeight)/2
        
        let scrollViewWidth = svLandscape.bounds.size.width
        
        switch scrollViewWidth{
        case 568:
            columns = 6
            width = 94
            marginX = 2
            
        case 667:
            columns = 6
            width = 94
            height = 98
            marginX = 1
            marginY = 29
            
        case 736:
            columns = 8
            rows = 4
            width = 92
            
        default:
            break
        }
        
        var row = 0
        var column = 0
        var x = marginX
        
        for (index, searchResult) in searchResults.enumerated(){
            let button = UIButton(type: .custom)
            button.setBackgroundImage(UIImage(named: "LandscapeButton"), for: .normal)
            button.frame = CGRect(x: x + paddingX,
                                  y: marginY + CGFloat(row)*height + paddingY,
                                  width: buttonWidth, height: buttonHeight)
            
            loadImage(searchResult: searchResult, button: button)
            button.tag = 2000 + index
            button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
            svLandscape.addSubview(button)
            row += 1
            if row == rows{
                row = 0
                x += width
                column += 1
                
                if column == columns{
                    column = 0
                    x += marginX*2
                }
            }
        }
        
        let buttons = columns * rows
        let numPages = 1 + (searchResults.count - 1)/buttons
        
        svLandscape.contentSize = CGSize(width: CGFloat(numPages)*scrollViewWidth,
                                         height: svLandscape.bounds.size.height)
        
        pgLandscape.numberOfPages = numPages
        pgLandscape.currentPage = 0
        
    }
    
    private func hideSpinner(){
        view.viewWithTag(1999)?.removeFromSuperview()
    }
    
    func searchResultReceived(){
        hideSpinner()
        switch search.state{
        case .notSearchedYet, .loading, .noResults:
            break
        case .results(let list):
            tileButtons(searchResults: list)
        }
    }
    
    private func showSpinner(){
        let spinner = UIActivityIndicatorView(style: .whiteLarge)
        spinner.center = CGPoint(x: svLandscape.bounds.midX + 0.5,
                                 y: svLandscape.bounds.midY + 0.5)
        spinner.tag = 1999
        view.addSubview(spinner)
        spinner.startAnimating()
    }
    
    private func showNothingFoundLabel(){
        
        let label = UILabel(frame: .zero)
        label.text = "Nothing found"
        label.textColor = .white
        label.backgroundColor = .clear
        label.sizeToFit()
        
        var rect = label.frame
        rect.size.width = ceil(rect.size.width/2)*2
        rect.size.height = ceil(rect.size.height/2)*2
        label.frame = rect
        label.center = CGPoint(x: svLandscape.bounds.midX, y: svLandscape.bounds.midY)
        view.addSubview(label)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        svLandscape.frame = view.bounds
        pgLandscape.frame = CGRect(
            x: 0,
            y: view.frame.size.height - pgLandscape.frame.size.height,
            width: view.frame.size.width,
            height: pgLandscape.frame.size.height)
        
        if firstTime{
            firstTime = false
            switch search.state{
            case .results(let list):
                tileButtons(searchResults: list)
            case .noResults:
                showNothingFoundLabel()
            case .loading:
                showSpinner()
            default:
                break
            }
        }
    }
    
    @IBAction func onPageChanged(_ sender: UIPageControl) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.svLandscape.contentOffset = CGPoint(
                x: self.svLandscape.bounds.size.width*CGFloat(sender.currentPage),
                y: 0)}, completion: nil)
    }
}

extension LandscapeViewController:UIScrollViewDelegate{
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.size.width
        let currentPage = Int((scrollView.contentOffset.x + width/2)/width)
        pgLandscape.currentPage = currentPage
    }
}
