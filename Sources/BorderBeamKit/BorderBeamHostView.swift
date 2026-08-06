#if canImport(AppKit)
import AppKit
import SwiftUI

/// The AppKit seam: an `NSView` that draws a beam ring over whatever it is
/// pinned to, so an AppKit-only application never touches the SwiftUI half of
/// this package (the same containment ThinkingOrbs keeps for its orb view).
///
/// The view is purely decorative by contract — it swallows no events
/// (`hitTest` answers nil) and exposes no accessibility elements. The embedder
/// pins it over the surface it should ring and restates `configuration`
/// whenever the facts change; equal restatements cost nothing.
@available(macOS 14.0, *)
public final class BorderBeamHostView: NSView {

    /// Everything the beam can be told. Mirrors `BorderBeam`'s parameters,
    /// minus content and callbacks, which the AppKit embedder owns.
    public struct Configuration: Equatable, Sendable {
        public var size: BeamSize
        public var colorVariant: BeamColorVariant
        public var theme: BeamTheme
        public var staticColors: Bool
        public var duration: Double?
        public var active: Bool
        public var borderRadius: Double?
        public var brightness: Double?
        public var saturation: Double?
        public var hueRange: Double
        public var strength: Double
        public var tuning: BeamTuning

        public init(
            size: BeamSize = .md,
            colorVariant: BeamColorVariant = .colorful,
            theme: BeamTheme = .dark,
            staticColors: Bool = false,
            duration: Double? = nil,
            active: Bool = true,
            borderRadius: Double? = nil,
            brightness: Double? = nil,
            saturation: Double? = nil,
            hueRange: Double = 30,
            strength: Double = 1,
            tuning: BeamTuning = .none
        ) {
            self.size = size
            self.colorVariant = colorVariant
            self.theme = theme
            self.staticColors = staticColors
            self.duration = duration
            self.active = active
            self.borderRadius = borderRadius
            self.brightness = brightness
            self.saturation = saturation
            self.hueRange = hueRange
            self.strength = strength
            self.tuning = tuning
        }
    }

    public var configuration: Configuration {
        didSet {
            guard configuration != oldValue else { return }
            applyRootView()
        }
    }

    /// When true the beam renders one fully-faded-in frame and the driving
    /// timeline pauses — a genuinely static picture rather than an animation
    /// rendering identical frames. This is the mode an embedder switches to
    /// under Reduce Motion; activation and deactivation become jump cuts,
    /// which is what collapsed motion means.
    public var rendersStatically: Bool = false {
        didSet {
            guard rendersStatically != oldValue else { return }
            applyRootView()
        }
    }

    private let hosting: NSHostingView<AnyView>

    // MARK: - Initialization

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        self.hosting = NSHostingView(rootView: Self.rootView(configuration, staticTime: nil))
        super.init(frame: .zero)

        hosting.sizingOptions = []
        hosting.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: trailingAnchor),
            hosting.topAnchor.constraint(equalTo: topAnchor),
            hosting.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        setAccessibilityElement(false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: - Decorative contract

    /// Never claims a click; whatever the beam rings stays interactive.
    public override func hitTest(_ point: NSPoint) -> NSView? { nil }

    public override func accessibilityChildren() -> [Any]? { [] }

    // MARK: - Private

    private func applyRootView() {
        hosting.rootView = Self.rootView(
            configuration,
            staticTime: rendersStatically ? configuration.size.staticDisplayTime : nil
        )
    }

    private static func rootView(_ c: Configuration, staticTime: Double?) -> AnyView {
        let beam = BorderBeam(
            size: c.size,
            colorVariant: c.colorVariant,
            theme: c.theme,
            staticColors: c.staticColors,
            duration: c.duration,
            active: c.active,
            borderRadius: c.borderRadius,
            brightness: c.brightness,
            saturation: c.saturation,
            hueRange: c.hueRange,
            strength: c.strength,
            tuning: c.tuning
        ) {
            Color.clear
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)

        guard let staticTime else { return AnyView(beam) }
        return AnyView(beam.environment(\.beamFrozenTime, staticTime))
    }
}

extension BeamSize {
    /// A cycle position at which each family reads fully visible — the same
    /// choice the snapshot harness makes, and for the same reason: `line`
    /// outside 32.5%–67.5% of its cycle legitimately fades to near-nothing.
    var staticDisplayTime: Double {
        switch self {
        case .sm, .md: return 0.49
        case .line: return 3.1 * 0.5
        case .pulseInner, .pulseOutside: return 0.8
        }
    }
}
#endif
