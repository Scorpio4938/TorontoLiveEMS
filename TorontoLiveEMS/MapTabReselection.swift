import Observation

/// A counter a page can watch for a second tap on its tab.
///
/// **A signal, not a coupling.** The tab-bar interop knows nothing about a map; the map knows
/// nothing about UIKit. The interop raises this counter, and whichever page is watching decides
/// what a re-tap means. The value is a count rather than a flag so two re-taps are two events
/// rather than one state that has to be cleared.
@Observable
final class MapTabReselectionSignal {

    private(set) var count = 0

    func send() {
        count += 1
    }
}

#if os(iOS)

import SwiftUI
import UIKit

/// The one UIKit bridge for the Map tab's second tap.
///
/// **SwiftUI cannot do this.** `TabView` and `Tab` expose no re-selection event, and tapping the
/// tab that is already selected does not change the `selection` binding, so nothing in SwiftUI
/// fires. `UITabBarControllerDelegate.tabBarController(_:shouldSelect:)` is the only callback that
/// sees *every* tap, including one on the selected tab; `didSelect` sees only a change. So the app
/// borrows that callback.
///
/// **Wrap, never replace.** The interop never owns the bar. It keeps the delegate that was there —
/// weakly, so it cannot keep a dead delegate alive — and installs a proxy that it retains strongly.
/// Every method the proxy does not handle is forwarded to the original, and the original's refusal
/// is honoured. The delegate proxy is the only UIKit in the feature; the map sees a counter.
///
/// **The view finds its own tab bar.** It walks up from its own view controller and view, never
/// `UIApplication.shared`'s windows: on iPad with two windows that finds the wrong one. It also
/// remembers which tab it is in by walking to the child of the tab bar controller, rather than
/// assuming an index or a title.
struct MapTabReselectionInterop: UIViewControllerRepresentable {

    let signal: MapTabReselectionSignal

    func makeCoordinator() -> Coordinator {
        Coordinator(signal: signal)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = InteropViewController()
        controller.view.backgroundColor = .clear
        controller.coordinator = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // **Re-assert on every update.** SwiftUI may rebuild the container or install its own
        // delegate again. If the installed delegate is no longer the proxy, wrap the current one.
        context.coordinator.connect(from: uiViewController)
    }

    static func dismantleUIViewController(
        _ uiViewController: UIViewController,
        coordinator: Coordinator
    ) {
        coordinator.disconnect()
    }

    /// Holds the proxy strongly, and the original delegate weak through the proxy.
    final class Coordinator {

        private let proxy = DelegateProxy()
        private weak var installedOn: UITabBarController?
        private weak var originalDelegate: UITabBarControllerDelegate?
        private var didLogMissingTabBar = false

        init(signal: MapTabReselectionSignal) {
            proxy.onReselect = { [signal] in signal.send() }
        }

        /// Finds the bar from this view, wraps its delegate if needed, and remembers the map tab.
        func connect(from viewController: UIViewController) {
            // Before the view is in a window there is nothing to walk. `update` and the deferred
            // call from `make` try again once it is.
            guard viewController.view.window != nil else { return }

            guard let tabBarController = Self.tabBarController(from: viewController) else {
                logMissingTabBar()
                return
            }

            guard let mapTabController = Self.tabRoot(
                for: viewController,
                in: tabBarController
            ) else {
                return
            }

            if installedOn !== tabBarController {
                disconnect()
                installedOn = tabBarController
            }

            proxy.mapTabController = mapTabController

            if tabBarController.delegate !== proxy {
                let current = tabBarController.delegate
                originalDelegate = current
                proxy.original = current
                tabBarController.delegate = proxy
            }
        }

        /// Puts the original delegate back when this interop goes away.
        func disconnect() {
            if let installedOn, installedOn.delegate === proxy {
                installedOn.delegate = originalDelegate
            }
            installedOn = nil
            originalDelegate = nil
            proxy.original = nil
            proxy.mapTabController = nil
        }

        private func logMissingTabBar() {
            guard !didLogMissingTabBar else { return }
            didLogMissingTabBar = true
            #if DEBUG
            print(
                "MapTabReselectionInterop: no UITabBarController in the hierarchy; "
                    + "the Map tab's second tap will not reset the camera"
            )
            #endif
        }

        /// The bar this view belongs to, found from the view rather than from the application.
        private static func tabBarController(
            from viewController: UIViewController
        ) -> UITabBarController? {
            var current: UIViewController? = viewController
            while let controller = current {
                if let tabBarController = controller as? UITabBarController {
                    return tabBarController
                }
                if let tabBarController = controller.tabBarController {
                    return tabBarController
                }
                current = controller.parent
            }

            // The responder chain is the second half of the same walk: a view may be hosted
            // without the view-controller parent chain reaching the bar.
            var responder: UIResponder? = viewController.view
            while let current = responder {
                if let tabBarController = current as? UITabBarController {
                    return tabBarController
                }
                if let controller = current as? UIViewController,
                   let tabBarController = controller.tabBarController {
                    return tabBarController
                }
                responder = current.next
            }

            return nil
        }

        /// The tab this interop belongs to: the child of the tab bar controller that contains it.
        private static func tabRoot(
            for viewController: UIViewController,
            in tabBarController: UITabBarController
        ) -> UIViewController? {
            var current: UIViewController? = viewController
            while let controller = current {
                if controller.parent === tabBarController {
                    return controller
                }
                current = controller.parent
            }
            return nil
        }
    }
}

/// Tells the coordinator when the interop is actually in a window.
///
/// The representable may be created while its tab is not selected, so `makeUIViewController` cannot
/// assume a window. These callbacks are the reliable moment when the map tab becomes visible.
private final class InteropViewController: UIViewController {

    weak var coordinator: MapTabReselectionInterop.Coordinator?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        coordinator?.connect(from: self)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        coordinator?.connect(from: self)
    }
}

/// The delegate proxy.
///
/// **Strongly held by the coordinator, and the original is weak.** `UITabBarController.delegate`
/// is weak, so a proxy the bar alone references would deallocate immediately and take the delegate
/// with it. The coordinator is the owner; the proxy only borrows the original.
///
/// **Every method is forwarded.** `shouldSelect` is the one method this proxy handles, because it is
/// the event being borrowed. Anything else the original implements is forwarded through
/// `responds(to:)` and `forwardingTarget(for:)`, so a delegate SwiftUI installs keeps working.
private final class DelegateProxy: NSObject, UITabBarControllerDelegate {

    weak var original: UITabBarControllerDelegate?
    weak var mapTabController: UIViewController?
    var onReselect: (() -> Void)?

    /// One reset at a time. A second tap can arrive while the camera is still animating.
    private var lastReset: TimeInterval = 0

    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        // Honour the delegate that was there first, including a refusal. A refused tab must not
        // reset anything, because it is not being selected.
        if let original {
            let allowed = original.tabBarController?(
                tabBarController,
                shouldSelect: viewController
            ) ?? true
            guard allowed else { return false }
        }

        // A tap on another tab changes the selection, so it is not a re-tap. Only a tap whose
        // target is both the bar's current selection and this interop's own tab resets.
        if tabBarController.selectedViewController === viewController,
           viewController === mapTabController {
            let now = ProcessInfo.processInfo.systemUptime
            if now - lastReset >= 0.5 {
                lastReset = now
                onReselect?()
            }
        }

        return true
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        if let original, original.responds(to: aSelector) { return true }
        return false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if let original, original.responds(to: aSelector) { return original }
        return super.forwardingTarget(for: aSelector)
    }
}

#endif
