import UIKit

class SearchResultCell:UITableViewCell{
    
    @IBOutlet weak var ivImage: UIImageView!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbArtistName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let selectedCell = UIView(frame: .zero)
        selectedCell.backgroundColor = UIColor(red:20/255, green:160/255, blue:160/255, alpha:0.5)
        selectedBackgroundView = selectedCell
    }
    
}
