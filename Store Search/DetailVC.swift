import UIKit

class DetailViewController:UIViewController{
    
    @IBOutlet weak var lbPopup: UIView!
    @IBOutlet weak var ivImage: UIImageView!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbArtist: UILabel!
    @IBOutlet weak var lbKind: UILabel!
    @IBOutlet weak var lbGenre: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lbPopup.layer.cornerRadius = 15
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onClose))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
    }
    
    @IBAction func onClose(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
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
}
