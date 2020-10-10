import Foundation
#if SWIFT_PACKAGE
import OrionC
#endif

public protocol Tweak {
    init()
    func didActivate()
}

extension Tweak {
    public func activate<BackendType: Backend>(backend: BackendType, hooks: [_ConcreteHook.Type]) {
        #if SWIFT_PACKAGE
        // this is effectively a no-op but we need it in order to prevent the
        // compiler from stripping out the constructor because it doesn't see
        // it being used
        __orion_constructor_c()
        #endif

        backend.hook { builder in
            for hook in hooks where hook.willActivate() {
                hook.activate(withHookBuilder: &builder)
                hook.didActivate()
            }
        }

        didActivate()
    }

    public func didActivate() {}
}

// a tweak which forces a custom backend
public protocol TweakWithBackend: Tweak {
    associatedtype BackendType: Backend
    var backend: BackendType { get }
}

extension TweakWithBackend {
    public func activate(hooks: [_ConcreteHook.Type]) {
        activate(backend: backend, hooks: hooks)
    }
}

public struct DefaultTweak: Tweak {
    public init() {}
}
