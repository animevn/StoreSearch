import UIKit

class DetailViewController:UIViewController{
    
    @IBOutlet weak var lbPopup: UIView!
    @IBOutlet weak var ivImage: UIImageView!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbArtist: UILabel!
    @IBOutlet weak var lbKind: UILabel!
    @IBOutlet weak var lbGenre: UILabel!
    @IBOutlet weak var bnPrice: UIButton!
    
    var searchResult:SearchResult!
    var downloadTask:URLSessionDownloadTask?
    var dismissAnimationStyle = AnimationStyle.fade
    
    enum AnimationStyle{
        case slide
        case fade
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    deinit {
        downloadTask?.cancel()
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
    
    private func updatePrice(){
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = searchResult.currency
        
        let priceText:String
        if searchResult.price == 0{
            priceText = "Free"
        }else if let text = formatter.string(from: searchResult.price as NSNumber){
            priceText = text
        }else{
            priceText = ""
        }
        bnPrice.setTitle(priceText, for: .normal)
    }
    
    private func updateViews(){
        
        lbName.text = searchResult.name
        if searchResult.artistName.isEmpty{
            lbArtist.text = "Unknown"
        }else{
            lbArtist.text = searchResult.artistName
        }
        lbKind.text = kindForDisplay(kind: searchResult.kind)
        lbGenre.text = searchResult.genre
        
        if let largeUrl = URL(string: searchResult.artworkLargeUrl){
            downloadTask = ivImage.loadImage(url: largeUrl)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        lbPopup.layer.cornerRadius = 15
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onClose))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
        
        if searchResult != nil{
            updateViews()
            updatePrice()
        }
    }
    
    @IBAction func onClose(_ sender: UIButton) {
        dismissAnimationStyle = .slide
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onOpen(_ sender: UIButton) {
        if let url = URL(string: searchResult.storeUrl){
            print(url)
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension DetailViewController:UIGestureRecognizerDelegate{
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        return (touch.view === self.view)
    }
    
}

extension DetailViewController:UIViewControllerTransitioningDelegate{
    
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        return DimmingPresentationController(presentedViewController: presented,
                                             presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController)->UIViewControllerAnimatedTransitioning?{
        return BounceAnimViewController()
    }
    
    func animationController(forDismissed dismissed: UIViewController)
                                -> UIViewControllerAnimatedTransitioning? {
        switch dismissAnimationStyle{
            case .slide:
                return SlideOutAnimationController()
            case .fade:
                return FadeOutAnimationController()
        }
    }

}
