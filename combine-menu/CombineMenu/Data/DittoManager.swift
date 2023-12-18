//
//  DittoManager.swift
//  CombineMenu
//
//  Created by Maximilian Alexander on 3/3/22.
//

import Foundation
import DittoSwift
import Combine

final class DittoManager {
    static var shared = DittoManager()
    let ditto: Ditto

    init() {
        ditto = Ditto()
        try! ditto.disableSyncWithV3()
    }
}

protocol DittoDecodable: Decodable {
    var _id: String { get }

    init?(json: String)
}

extension DittoDecodable {
    init?(json: String) {
        let data = Data(json.utf8)
        let decorder = JSONDecoder()
        do {
            self = try decorder.decode(Self.self, from: data)
        } catch {
            print("ERROR:", error.localizedDescription, json)
            return nil
        }
    }
}

// MARK: - Extensions of `execute`
extension DittoStore {

    // Emit with mapped objects as an array
    func executePublisher<T: DittoDecodable>(query: String, arguments: Dictionary<String, Any?>? = [:], mapTo: T.Type) -> AnyPublisher<[T], Error> {
        return Future { promise in
            Task.init {
                do {
                    let result = try await self.execute(query: query, arguments: arguments)
                    let items = result.items.compactMap { T(json: $0.jsonString()) }
                    promise(.success(items))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }

    // Emit with a mapped object as a single value instead of an array
    func executePublisher<T: DittoDecodable>(query: String, arguments: Dictionary<String, Any?>? = [:], mapTo: T.Type, onlyFirst: Bool) -> AnyPublisher<T, Error> {
        return Future { promise in
            Task.init {
                do {
                    let result = try await self.execute(query: query, arguments: arguments)
                    guard let first = result.items.first else { return }
                    guard let item = T(json: first.jsonString()) else { return }
                    promise(.success(item))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - Extensions of `registerObserver`
extension DittoStore {

    // Send mapped objects as an array
    func observePublisher<T: DittoDecodable>(query: String, arguments: [String : Any?]? = nil, deliverOn queue: DispatchQueue = .main, mapTo: T.Type) -> AnyPublisher<[T], Error> {
        let subject = PassthroughSubject<[T], Error>()

        do {
            try self.registerObserver(query: query, arguments: arguments, deliverOn: queue) { result in
                let items = result.items.compactMap { T(json: $0.jsonString()) }
                subject.send(items)
            }
        } catch {
            subject.send(completion: .failure(error))
        }

        return subject.eraseToAnyPublisher()
    }

    // Send a mapped object as a single value instead of an array
    func observePublisher<T: DittoDecodable>(query: String, arguments: [String : Any?]? = nil, deliverOn queue: DispatchQueue = .main, mapTo: T.Type, onlyFirst: Bool) -> AnyPublisher<T, Error> {
        let subject = PassthroughSubject<T, Error>()

        do {
            try self.registerObserver(query: query, arguments: arguments, deliverOn: queue) { result in
                guard let first = result.items.first else { return }
                guard let item = T(json: first.jsonString()) else { return }
                subject.send(item)
            }
        } catch {
            subject.send(completion: .failure(error))
        }

        return subject.eraseToAnyPublisher()
    }
}

