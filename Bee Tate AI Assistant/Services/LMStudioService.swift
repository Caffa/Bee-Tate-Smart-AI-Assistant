//
//  LMStudioService.swift
//  Bee Tate AI Assistant
//

import Foundation

class LMStudioService {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = URL(string: "http://localhost:1234/v1")!) {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        self.session = URLSession(configuration: config)
    }

    func enhanceTranscription(_ text: String, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt =
        """
        Enhance the following transcription by removing filler words,
        rephrasing sentences for clarity while using the same words, and improving coherence and flow.
        Keep the original meaning intact:

        \(text)
        """

        sendPrompt(prompt, completion: completion)
    }

    func generateTitle(from text: String, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt =
        """
        Generate a concise, descriptive title for the following text.
        The title should capture the main topic or theme:

        \(text)
        """

        sendPrompt(prompt, completion: completion)
    }

    func generateFollowUpQuestions(from text: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let prompt =
        """
        Based on the following text, generate 3 follow-up questions that would help
        expand on the ideas or explore related topics:

        \(text)
        """

        sendPrompt(prompt) { result in
            switch result {
            case .success(let response):
                // Parse the response to extract questions
                let questions = response.split(separator: "\n")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                completion(.success(questions.map { String($0) }))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func convertToPost(text: String, format: String, examples: [String]? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        var prompt =
        """
        Convert the following text into a \(format) post.
        Maintain the original ideas but format it appropriately for the platform:

        \(text)
        """

        if let examples = examples, !examples.isEmpty {
            prompt += "\n\nHere are some examples of my style:\n"
            examples.forEach { example in prompt += "\n\(example)\n" }
        }

        sendPrompt(prompt, completion: completion)
    }

    private func sendPrompt(_ prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let requestURL = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": "local-model",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "LMStudioService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "LMStudioService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }
}

