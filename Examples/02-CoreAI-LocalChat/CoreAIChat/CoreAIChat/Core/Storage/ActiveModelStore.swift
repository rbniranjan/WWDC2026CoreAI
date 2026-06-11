import Foundation

struct ActiveModelStore {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "CoreAIChat.activeModelID") {
        self.defaults = defaults
        self.key = key
    }

    var activeModelID: String? {
        get {
            defaults.string(forKey: key)
        }
        nonmutating set {
            defaults.set(newValue, forKey: key)
        }
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
