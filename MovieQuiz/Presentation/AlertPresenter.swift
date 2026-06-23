import UIKit

final class AlertPresenter {
    
    func showAlert(on viewController: UIViewController, model: AlertModel) {
        let alert = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: .alert
        )
        
        alert.view.accessibilityIdentifier = "Game results"
        let action = UIAlertAction(title: model.buttonText,style: .default) { _ in
            model.completion()
        }
        
        alert.addAction(action)
        viewController.present(alert, animated: true)
    }
}
