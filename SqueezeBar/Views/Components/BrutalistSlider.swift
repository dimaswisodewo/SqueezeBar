import SwiftUI
import AppKit

/// Custom drawing on NSSlider preserves native tracking, focus, and accessibility.
struct BrutalistSlider: NSViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var isDisabled = false
    var title = "Quality"
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    func makeNSView(context: Context) -> SteppedSlider {
        let slider = SteppedSlider()
        slider.cell = BrutalistSliderCell()
        slider.isContinuous = true
        slider.target = context.coordinator
        slider.action = #selector(Coordinator.changed(_:))
        slider.focusRingType = .exterior
        updateNSView(slider, context: context)
        return slider
    }

    func updateNSView(_ slider: SteppedSlider, context: Context) {
        context.coordinator.parent = self
        slider.minValue = range.lowerBound
        slider.maxValue = range.upperBound
        slider.doubleValue = value
        slider.step = step
        slider.isEnabled = isEnabled && !isDisabled
        slider.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        slider.setAccessibilityLabel(title)
        slider.setAccessibilityValueDescription("\(Int(value * 100)) percent")
        slider.needsDisplay = true
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject {
        var parent: BrutalistSlider
        init(_ parent: BrutalistSlider) { self.parent = parent }

        @objc func changed(_ slider: NSSlider) {
            let lower = parent.range.lowerBound
            let stepped = lower + ((slider.doubleValue - lower) / parent.step).rounded() * parent.step
            let value = min(max(stepped, lower), parent.range.upperBound)
            slider.doubleValue = value
            parent.value = value
        }
    }
}

final class SteppedSlider: NSSlider {
    var step: Double = 0.05

    override func keyDown(with event: NSEvent) {
        guard isEnabled else { return }
        switch event.keyCode {
        case 123, 125: doubleValue = max(minValue, doubleValue - step)
        case 124, 126: doubleValue = min(maxValue, doubleValue + step)
        default:
            super.keyDown(with: event)
            return
        }
        sendAction(action, to: target)
    }
}

private final class BrutalistSliderCell: NSSliderCell {
    private var ink: NSColor {
        let dark = controlView?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return NSColor(dark ? DesignTokens.Colors.white : DesignTokens.Colors.black)
    }

    override func drawBar(inside rect: NSRect, flipped: Bool) {
        let track = NSRect(x: rect.minX, y: rect.midY - 4, width: rect.width, height: 8)
        let fraction = CGFloat((doubleValue - minValue) / max(maxValue - minValue, 0.001))
        ink.withAlphaComponent(isEnabled ? 0.12 : 0.08).setFill()
        NSBezierPath(rect: track).fill()
        NSColor(DesignTokens.Colors.lime).withAlphaComponent(isEnabled ? 1 : 0.25).setFill()
        NSBezierPath(rect: NSRect(x: track.minX, y: track.minY, width: track.width * fraction, height: track.height)).fill()
        ink.withAlphaComponent(isEnabled ? 1 : 0.4).setStroke()
        let outline = NSBezierPath(rect: track.insetBy(dx: 1, dy: 1))
        outline.lineWidth = DesignTokens.Geometry.border
        outline.stroke()
    }

    override func drawKnob(_ knobRect: NSRect) {
        let knob = NSRect(x: knobRect.midX - 9, y: knobRect.midY - 12, width: 18, height: 24)
        NSColor(DesignTokens.Colors.lime).withAlphaComponent(isEnabled ? 1 : 0.4).setFill()
        NSBezierPath(rect: knob).fill()
        ink.withAlphaComponent(isEnabled ? 1 : 0.4).setStroke()
        let outline = NSBezierPath(rect: knob.insetBy(dx: 1, dy: 1))
        outline.lineWidth = DesignTokens.Geometry.border
        outline.stroke()
        let grip = NSBezierPath()
        grip.move(to: NSPoint(x: knob.midX, y: knob.minY + 6))
        grip.line(to: NSPoint(x: knob.midX, y: knob.maxY - 6))
        grip.lineWidth = 2
        grip.stroke()
    }
}
