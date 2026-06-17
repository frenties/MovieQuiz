import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    private var correctAnswers = 0
    private var currentQuestionIndex = 0
    private let questionsAmount = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter = AlertPresenter()
    private var statisticService: StatisticServiceProtocol?
    
    // MARK: - Actions
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        checkAnswer(false)
        setupButtonsEnabled(false)
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        checkAnswer(true)
        setupButtonsEnabled(false)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupQuestionfacory()
        setupStatiscticService()
    }
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
            
            self?.setupButtonsEnabled(true)
        }
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        showLoadingIndicator()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
    }
    
    private func setupQuestionfacory() {
        questionFactory = QuestionFactory(moviesLoader:MoviesLoader(),delegate: self)
        questionFactory?.loadData()
        
    }
    
    private func setupStatiscticService() {
        statisticService = StatisticService()
    }
    
    private func setupButtonsEnabled(_ isEnabled: Bool) {
        noButton.isEnabled = isEnabled
        yesButton.isEnabled = isEnabled
    }
    
    private func checkAnswer(_ givenAnswer: Bool) {
        guard let currentQuestion = currentQuestion else {return}
        
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        setupButtonsEnabled(false)
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }
    
    private func show(quiz step: QuizStepViewModel) {
        hideLoadingIndicator()
        
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func show(quiz result:QuizResultsViewModel) {
        guard let statisticService = statisticService else { return }
        
        let currentGameResult = GameResult(correct: correctAnswers,
                                           total: questionsAmount,
                                           date: Date()
        )
        
        statisticService.store(newResult: currentGameResult)
        
        let gamesCount = "Количество сыгранных квизов: \(statisticService.gamesCount)"
        let bestGameResult = "Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date.dateTimeString))"
        
        let averrageAccuracy = "Средняя точность:\(String(format: "%.2f", statisticService.totalAccuracy))%"
        
        let model = AlertModel(title: result.title,
                               message: "\(result.text) \n \(gamesCount) \n  \(bestGameResult) \n \(averrageAccuracy)",
                               buttonText: result.buttonText
        ) { [weak self] in
            guard let self = self else {return}
            self.restartQuiz()
        }
        alertPresenter.showAlert(on: self, model: model)
    }
    
    private func restartQuiz() {
        correctAnswers = 0
        currentQuestionIndex = 0
        showLoadingIndicator()
        questionFactory?.delegate = self
        questionFactory?.requestNextQuestion()
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.cornerRadius = 20
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreenIOS.cgColor : UIColor.ypRedIOS.cgColor
        
        if isCorrect {
            correctAnswers += 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.imageView.layer.borderWidth = 0
            self.showNextQuestionOrResults()
        }
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
            let text = correctAnswers == questionsAmount ?
            "Поздравляем,\n Вы ответили на 10 из 10!" :
            "Вы ответили на \(correctAnswers) из 10,\n попробуйте ещё раз!"
            
            let viewModel = QuizResultsViewModel (
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Сыграть ещё раз"
            )
            show(quiz: viewModel)
        } else {
            currentQuestionIndex += 1
            showLoadingIndicator()
            questionFactory?.requestNextQuestion()
        }
    }
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        setupButtonsEnabled(false)
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    private func showNetworkError(message:String) {
        hideLoadingIndicator()
        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать ещё раз") { [weak self] in
            guard let self = self else {return}
            
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            
            self.showLoadingIndicator()
            self.questionFactory?.loadData()
        }
        alertPresenter.showAlert(on: self, model: model)
    }
    
    func didLoadDataFromServer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            questionFactory?.requestNextQuestion()
        }
    }
    
    func didFailToLoadData(with error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            showNetworkError(message: error.localizedDescription)
        }
    }
}
