//
//  FavoriteManager.swift
//  Observer
//
//  Created by Jiwon Kim on 9/11/24.
//

import Foundation

class FavoriteManager: ObservableObject {
    @Published private(set) var favorites: Set<Int> = []
    private let favoriteService: FavoriteServiceProtocol
    
    init(favoriteService: FavoriteServiceProtocol) {
        self.favoriteService = favoriteService
        Task {
            await loadFavorites()
        }
    }
    
    func toggleFavorite(for productId: Int) {
        if favorites.contains(productId) {
            favorites.remove(productId)
        } else {
            favorites.insert(productId)
        }
        
        Task {
            do {
                let isFavorite = try await favoriteService.toggleFavorite(for: productId)
                await MainActor.run {
                    if isFavorite {
                        self.favorites.insert(productId)
                    } else {
                        self.favorites.remove(productId)
                    }
                }
            } catch {
                print("Error toggling favorite: \(error.localizedDescription)")
                await MainActor.run {
                    self.favorites.toggle(productId)
                }
            }
        }
    }
    
    func isFavorite(_ productId: Int) -> Bool {
        return favorites.contains(productId)
    }
    
    @MainActor
    private func loadFavorites() async {
        do {
            let favoriteIds = try await favoriteService.getFavorites()
            self.favorites = Set(favoriteIds)
        } catch {
            print("Error loading favorites: \(error.localizedDescription)")
        }
    }
}

extension Set {
    mutating func toggle(_ element: Element) {
        if contains(element) {
            remove(element)
        } else {
            insert(element)
        }
    }
}
