import Foundation

enum ExternalRuntimeBuildOptions {
    static var zooFMProviderCompileFlagEnabled: Bool {
        #if ENABLE_ZOO_FM_PROVIDER
        true
        #else
        false
        #endif
    }

    static var zooFMProviderModuleLinked: Bool {
        #if canImport(ZooFMProvider)
        true
        #else
        false
        #endif
    }
}
