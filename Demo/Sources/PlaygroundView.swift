import SwiftUI
import BorderBeamKit

/// Native replica of the playground at beam.jakubantalik.com: Rotate/Pulse
/// family tabs, type / color / strength controls, a live preview card with
/// play-pause, and the generated code snippet.
struct PlaygroundView: View {
    enum BeamFamily: String, CaseIterable {
        case rotate = "Rotate"
        case pulse = "Pulse"

        var sizes: [(BeamSize, String)] {
            switch self {
            case .rotate: return [(.md, "Large"), (.sm, "Small"), (.line, "Line")]
            case .pulse: return [(.pulseInner, "Pulse Inner"), (.pulseOutside, "Pulse Outside")]
            }
        }

        var defaultSize: BeamSize {
            self == .pulse ? .pulseInner : .md
        }
    }

    @State private var family: BeamFamily = .rotate
    @State private var size: BeamSize = .md
    @State private var variant: BeamColorVariant = .colorful
    /// Percent, 0–100, mirroring the web playground's slider.
    @State private var strength: Double = 70
    @State private var active = true
    @State private var isDark = true
    @State private var copied = false

    private var theme: BeamTheme { isDark ? .dark : .light }

    var body: some View {
        ZStack {
            (isDark ? Color(white: 0.027) : Color(white: 1.0)).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    familyTabs
                        .frame(maxWidth: .infinity)

                    Text("Playground")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(primary)

                    controls
                    preview
                    codeBlock
                    footer
                }
                .padding(32)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(isDark ? .dark : .light)
        .animation(.easeInOut(duration: 0.25), value: isDark)
    }

    // MARK: - Palette

    private var primary: Color { isDark ? .white : Color(white: 0.1) }
    private var secondary: Color { isDark ? Color(white: 0.62) : Color(white: 0.38) }
    private var panel: Color { isDark ? Color(white: 0.055) : Color(white: 0.965) }
    private var chip: Color { isDark ? Color(white: 0.13) : Color(white: 0.88) }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Border beam")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(primary)
                Text("Animated border beam component")
                    .font(.system(size: 15))
                    .foregroundStyle(secondary)
            }
            Spacer()
            Button {
                isDark.toggle()
            } label: {
                Image(systemName: isDark ? "sun.max" : "moon")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(secondary)
                    .frame(width: 32, height: 32)
                    .background(chip.opacity(0.6), in: Circle())
            }
            .buttonStyle(.plain)
            .help(isDark ? "Light theme" : "Dark theme")
        }
    }

    private var familyTabs: some View {
        HStack(spacing: 4) {
            ForEach(BeamFamily.allCases, id: \.self) { f in
                tabButton(f.rawValue, isActive: family == f) {
                    family = f
                    size = f.defaultSize
                }
            }
        }
        .padding(4)
        .background(panel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(alignment: .top, spacing: 28) {
            controlGroup("Type") {
                HStack(spacing: 4) {
                    ForEach(family.sizes, id: \.0) { value, label in
                        tabButton(label, isActive: size == value) { size = value }
                    }
                }
            }

            controlGroup("Color") {
                HStack(spacing: 4) {
                    ForEach(BeamColorVariant.allCases, id: \.self) { v in
                        tabButton(v.rawValue.capitalized, isActive: variant == v) { variant = v }
                    }
                }
            }

            controlGroup("Strength") {
                strengthSlider
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func controlGroup(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(label)
                .font(.system(size: 12.5))
                .foregroundStyle(secondary)
            content()
        }
    }

    private func tabButton(_ label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12.5, weight: isActive ? .medium : .regular))
                .foregroundStyle(isActive ? primary : secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    isActive ? chip : .clear,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }

    /// The site's strength control: a filled track with the percentage riding
    /// in a small chip, draggable across its full surface.
    private var strengthSlider: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isDark ? Color(white: 0.1) : Color(white: 0.9))
                if strength > 0 {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(chip)
                        .frame(width: max(30, geo.size.width * strength / 100))
                }
                Text("\(Int(strength))%")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(primary)
                    .padding(.leading, 10)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        strength = (min(max(drag.location.x / geo.size.width, 0), 1) * 100).rounded()
                    }
            )
        }
        .frame(width: 150, height: 32)
        .accessibilityElement()
        .accessibilityLabel("Effect strength")
        .accessibilityValue("\(Int(strength)) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: strength = min(strength + 5, 100)
            case .decrement: strength = max(strength - 5, 0)
            @unknown default: break
            }
        }
    }

    // MARK: - Preview

    private var preview: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            beamCard
            Spacer(minLength: 0)

            Button {
                active.toggle()
            } label: {
                Image(systemName: active ? "pause.fill" : "play.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(primary)
                    .frame(width: 34, height: 34)
                    .background(chip.opacity(0.8), in: Circle())
            }
            .buttonStyle(.plain)
            .help(active ? "Pause" : "Play")
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
        .background(panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var beamCard: some View {
        // Web demo card geometry: 348x122 radius 16; the sm preset is a
        // 150x44 pill. pulse-outside gets the website's tuned preset, which
        // the stock library intentionally does not apply.
        let isSm = size == .sm
        let radius: Double = isSm ? 22 : 16
        return BorderBeam(
            size: size,
            colorVariant: variant,
            theme: theme,
            active: active,
            borderRadius: radius,
            strength: strength / 100,
            tuning: size == .pulseOutside ? .webDemoPulsePreset : .none
        ) {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(isDark ? Color(white: 0.094) : Color(white: 0.97))
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(isDark ? Color(white: 0.22) : Color(white: 0.87), lineWidth: 1)
                )
                .frame(width: isSm ? 150 : 348, height: isSm ? 44 : 122)
                .overlay(alignment: isSm ? .center : .topLeading) {
                    Text(isSm ? "" : "Build anything…")
                        .font(.system(size: 15))
                        .foregroundStyle(isDark ? Color(white: 0.5) : Color(white: 0.55))
                        .padding(isSm ? 0 : 18)
                }
        }
    }

    // MARK: - Code block

    private var generatedCode: String {
        var args = "size: .\(swiftCase(size)), colorVariant: .\(variant.rawValue)"
        if strength < 100 {
            args += ", strength: \(String(format: "%.2f", strength / 100))"
        }
        return """
        BorderBeam(\(args)) {
            Card()
        }
        """
    }

    private func swiftCase(_ size: BeamSize) -> String {
        switch size {
        case .pulseInner: return "pulseInner"
        case .pulseOutside: return "pulseOutside"
        default: return size.rawValue
        }
    }

    private var codeBlock: some View {
        HStack(alignment: .top) {
            Text(generatedCode)
                .font(.system(size: 12.5, design: .monospaced))
                .foregroundStyle(primary.opacity(0.85))
                .textSelection(.enabled)
            Spacer()
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(generatedCode, forType: .string)
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundStyle(secondary)
                    .frame(width: 28, height: 28)
                    .background(chip.opacity(0.6), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Copy playground code")
        }
        .padding(16)
        .background(panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var footer: some View {
        HStack(spacing: 4) {
            Text("Made by")
                .foregroundStyle(secondary.opacity(0.7))
            Link("Jakub Antalik", destination: URL(string: "https://x.com/jakubantalik")!)
                .foregroundStyle(secondary)
            Text("· BorderBeamKit — SwiftUI + Metal")
                .foregroundStyle(secondary.opacity(0.7))
        }
        .font(.system(size: 12.5))
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
}

extension BeamTuning {
    /// The tuning the web demo applies to its `pulse-outside` card
    /// (`.beam-host--pulse-outside-tuned` in the site's styles): a 1.05x glow
    /// boost with 1.71x layer opacity and matching glow brightness/saturation.
    /// Without it the stock library output reads noticeably softer than the
    /// website preview.
    static let webDemoPulsePreset = BeamTuning(
        glowBoost: 1.05,
        strokeOpacity: 1.71,
        innerOpacity: 1.71,
        bloomOpacity: 1.71,
        glowBrightness: 1.3 * 1.71,
        glowSaturate: 1.2 * 1.71
    )
}

#Preview {
    PlaygroundView()
}
