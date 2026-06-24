import Foundation

struct QuizStepViewModel {
    let imageData: Data
    let question: String
    let questionNumber: String
}

protocol MovieQuizViewControllerProtocol: AnyObject {
    func show(quiz step: QuizStepViewModel)
    func show(quiz result: QuizResultsViewModel)
    
    func highlightImageBorder(isCorrectAnswer: Bool)
    
    func showLoadingIndicator()
    func hideLoadingIndicator()
    
    func showNetworkError(message: String)
    
    func setupButtonsEnabled(_ isEnabled: Bool)
}

final class MovieQuizPresenter: QuestionFactoryDelegate {
    
    // MARK: - Properties
    
    private let statisticService: StatisticServiceProtocol
    var questionFactory: QuestionFactoryProtocol?
    private weak var viewController: MovieQuizViewControllerProtocol?
    let questionsAmount: Int = 10
    
    private var currentQuestionIndex: Int = 0
    var currentQuestion: QuizQuestion?
    var correctAnswers: Int = 0
    
    // MARK: - Lifecycle
    
    init(viewController: MovieQuizViewControllerProtocol) {
        self.viewController = viewController
        
        statisticService = StatisticService()
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory?.loadData()
        
        viewController.showLoadingIndicator()
    }
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question else { return }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {return}
            self.viewController?.setupButtonsEnabled(true)
            self.viewController?.show(quiz: viewModel)
        }
    }
    
    // MARK: - Methods
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            imageData: model.image,
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }
    
    func yesButtonClicked() {
        checkAnswer(true)
    }
    
    func noButtonClicked() {
        checkAnswer(false)
    }
    
    func proceedToNextQuestionOrResults() {
        if isLastQuestion() {
            let text = makeResultsMessage()
            
            let viewModel = QuizResultsViewModel (
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Сыграть ещё раз"
            )
            viewController?.show(quiz: viewModel)
        } else {
            self.switchToNextQuestion()
            viewController?.showLoadingIndicator()
            questionFactory?.requestNextQuestion()
        }
    }
    
    private func checkAnswer(_ givenAnswer: Bool) {
        guard let currentQuestion = currentQuestion else {return}
        
        let isCorrect = givenAnswer == currentQuestion.correctAnswer
        
        proceedWithAnswer(isCorrect:isCorrect)
    }
    
    func didAnswer(isCorrectAnswer: Bool) {
        if isCorrectAnswer {
            correctAnswers += 1
        }
    }
    
    func proceedWithAnswer(isCorrect: Bool) {
        didAnswer(isCorrectAnswer: isCorrect)
        
        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)
        viewController?.setupButtonsEnabled(false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.proceedToNextQuestionOrResults()
        }
    }
    
    func makeResultsMessage() -> String {
        statisticService.store(newResult: GameResult(correct: correctAnswers, total: questionsAmount, date: Date()))
        
        
        let bestGame = statisticService.bestGame
        
        let resultMessage = """
            Количество сыгранных квизов: \(statisticService.gamesCount)
            Ваш результат: \(correctAnswers)/\(questionsAmount)
            Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))
            Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
            """
        
        return resultMessage
    }
    
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: any Error) {
        let message = error.localizedDescription
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.showNetworkError(message: message)
        }
    }
}
