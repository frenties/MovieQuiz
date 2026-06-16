import Foundation

protocol MoviesLoading {
    func loadMovies(handler: @escaping (Result<MostPopularMovies, any Error>) -> Void)
}

struct MoviesLoader:MoviesLoading {
    // MARK: - NetworkClient
    private let networkClient = NetworkClient()
    
    // MARK: - URL
    private var top250MoviesUrl: URL {
        guard let url = URL(string: "https://tv-api.com/en/API/Top250Movies/k_zcuw1ytf") else {
            preconditionFailure("Unable to construct top250MoviesUrl")
        }
        return url
    }
    
    private var mostPopularMoviesUrl: URL {
        guard let url = URL(string: "https://tv-api.com/en/API/MostPopularMovies/k_zcuw1ytf") else {
            preconditionFailure("Unable to construct mostPopularMoviesUrl")
        }
        return url
    }
    
    func loadMovies(handler: @escaping (Result<MostPopularMovies, any Error>) -> Void) {
        networkClient.fetch(url: mostPopularMoviesUrl) { firstResult in
            
            switch firstResult {
            case .success(let firstData):
                do {
                    let mostPopularMovies = try JSONDecoder().decode(MostPopularMovies.self, from: firstData)
                    if !mostPopularMovies.errorMessage.isEmpty {
                        let error = NSError(domain: "MoviesLoader", code: 0, userInfo: [NSLocalizedDescriptionKey: mostPopularMovies.errorMessage])
                        handler(.failure(error))
                        return
                    }
                    
                    self.networkClient.fetch(url: self.top250MoviesUrl) { secondResult in
                        switch secondResult {
                        case .success(let secondData):
                            do {
                                let top250Movies = try JSONDecoder().decode(MostPopularMovies.self, from: secondData)
                                if !top250Movies.errorMessage.isEmpty {
                                    let error = NSError(domain: "MoviesLoader", code: 0, userInfo: [NSLocalizedDescriptionKey: top250Movies.errorMessage])
                                    handler(.failure(error))
                                    return
                                }
                                
                                let generalListofMovies = mostPopularMovies.items + top250Movies.items
                                
                                let mixedListOfMovies = MostPopularMovies(
                                    errorMessage: top250Movies.errorMessage.isEmpty ? mostPopularMovies.errorMessage : top250Movies.errorMessage,
                                    items: generalListofMovies.shuffled()
                                )
                                
                                handler(.success(mixedListOfMovies))
                                
                            } catch {
                                handler(.failure(error))
                            }
                            
                        case .failure(let error):
                            handler(.failure(error))
                        }
                    }
                    
                } catch {
                    handler(.failure(error))
                }
            case .failure(let error):
                handler(.failure(error))
            }
        }
    }
}
