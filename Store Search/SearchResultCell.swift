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
    
    func configureCell(searchResult:SearchResult){
        lbName.text = searchResult.name
        if searchResult.artistName.isEmpty{
            lbArtistName.text = "Unknown"
        }else{
            lbArtistName.text = String(format:"%@ (%@)", searchResult.artistName,
                                       kindForDisplay(kind: searchResult.kind))
        }
    }
}
