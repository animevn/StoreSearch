import UIKit

class DimmingPresentationController:UIPresentationController{
    
    lazy var dimmingView = GradientView(frame: .zero)
    
    override func presentationTransitionWillBegin() {
        dimmingView.frame = containerView!.bounds
        containerView!.insertSubview(dimmingView, at: 0)
    }
    
}
