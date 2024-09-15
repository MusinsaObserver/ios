//
//  SceneDelegate.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else {
            fatalError("Failed to cast scene to UIWindowScene")
        }
        
        setupWindow(with: windowScene)
    }

    private func setupWindow(with windowScene: UIWindowScene) {
        let window = UIWindow(windowScene: windowScene)
        let homeView = createHomeView()
        window.rootViewController = UIHostingController(rootView: homeView)
        self.window = window
        window.makeKeyAndVisible()
    }
    
    private func createHomeView() -> some View {
        // 여기에서 필요한 의존성을 주입할 수 있습니다.
        // 예: let apiClient = APIClient()
        return HomeView()
    }

    // MARK: - Lifecycle methods
    // 필요한 경우 아래 메서드들을 구현할 수 있습니다.
    
    /*
    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
    */
}
