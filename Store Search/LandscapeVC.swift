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
        
        svLandscape.removeConstraints(svLandscape.constraints)
        svLandscape.translatesAutoresizingMaskIntoConstraints = true
        svLandscape.backgroundColor = UIColor(patternImage: UIImage(named: "LandscapeBackground")!)
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
        
        for (_, searchResult) in searchResults.enumerated(){
            let button = UIButton(type: .custom)
            button.setBackgroundImage(UIImage(named: "LandscapeButton"), for: .normal)
            button.frame = CGRect(x: x + paddingX,
                                  y: marginY + CGFloat(row)*height + paddingY,
                                  width: buttonWidth, height: buttonHeight)
            
            loadImage(searchResult: searchResult, button: button)
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
            tileButtons(searchResults: search.searchResults)
        }
    }
    
}
