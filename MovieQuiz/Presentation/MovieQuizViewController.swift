import UIKit

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    // MARK: - IBOutlets
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    private var presenter:MovieQuizPresenter?
    private var alertPresenter = AlertPresenter()
    
    // MARK: - Actions
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter?.noButtonClicked()
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter?.yesButtonClicked()
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter = MovieQuizPresenter(viewController: self)
        
        setupUI()
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        showLoadingIndicator()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
    }
    
    func setupButtonsEnabled(_ isEnabled: Bool) {
        noButton.isEnabled = isEnabled
        yesButton.isEnabled = isEnabled
    }
    
    func show(quiz step: QuizStepViewModel) {
        hideLoadingIndicator()
        
        imageView.layer.borderWidth = 0
        
        imageView.image = UIImage(data:step.imageData) ?? UIImage()
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        
        setupButtonsEnabled(true)
    }
    
    func show(quiz result:QuizResultsViewModel) {
        let model = AlertModel(
            title: result.title,
            message: result.text,
            buttonText: result.buttonText
        ) { [weak self] in
            guard let self = self else { return }
            self.presenter?.restartGame()
        }
        alertPresenter.showAlert(on: self, model: model)
    }
    
    func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        setupButtonsEnabled(false)
    }
    
    func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    func showNetworkError(message:String) {
        hideLoadingIndicator()
        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать ещё раз") { [weak self] in
            guard let self = self else {return}
            
            self.showLoadingIndicator()
            self.presenter?.restartGame()
        }
        alertPresenter.showAlert(on: self, model: model)
    }
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreenIOS.cgColor : UIColor.ypRedIOS.cgColor
    }
}
