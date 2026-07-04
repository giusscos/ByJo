//
//  OnboardingSuccessStep.swift
//  ByJo
//

import SwiftUI

struct OnboardingSuccessStep: View {
    let onComplete: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            ConfettiView()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 120, height: 120)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.green)
                    }
                    .scaleEffect(appeared ? 1.0 : 0.3)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.1), value: appeared)

                    VStack(spacing: 12) {
                        Text("You're All Set!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .onboardingAppear(appeared, delay: 0.25)

                        Text("Your financial journey starts now. ByJo will help you track every step — from savings to investments.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .onboardingAppear(appeared, delay: 0.35)
                    }
                }

                Spacer()

                Button(action: onComplete) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .onboardingAppear(appeared, delay: 0.45)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { appeared = true }
    }
}

// MARK: - Confetti
//
// Particles spawn at the bottom, shoot upward with a cubic ease-out curve to a
// random peak in the upper half, then fall back down with a cubic ease-in curve
// plus slight horizontal drift. Alpha fades from 1→0 over the fall phase.
//
// Per-frame allocation budget: zero.
// - One static unit-rect Path shared by all particles.
// - GraphicsContext.Shading pre-created per particle (stored on the struct).
// - Per particle: one struct copy of GraphicsContext (value-type, stack only),
//   two CGAffineTransform mutations (6-double value types), one fill call.

private let _confettiUnitRect = Path(CGRect(x: -0.5, y: -0.5, width: 1, height: 1))

private struct ConfettiParticle {
    // Horizontal trajectory (screen points)
    let startX: CGFloat
    let peakX: CGFloat
    let endX: CGFloat
    // Vertical trajectory (screen points); startY is below the screen bottom
    let startY: CGFloat
    let peakY: CGFloat
    // Timing
    let delay: Double
    let riseDuration: Double
    let fallDuration: Double
    // Rotation
    let rotation0: Double   // radians
    let rotSpeed: Double    // radians / second
    // Shape
    let width: CGFloat
    let height: CGFloat
    // Pre-allocated paint — alpha controlled via context.opacity, not the shading itself
    let shading: GraphicsContext.Shading
}

private struct ConfettiView: View {
    var particleCount: Int = 160
    var colors: [UIColor] = [
        .systemRed, .systemBlue, .systemGreen, .systemYellow,
        .systemPurple, .systemOrange, .systemPink, .systemTeal,
        UIColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1),
        UIColor(red: 0.1, green: 0.75, blue: 0.85, alpha: 1)
    ]

    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false
    @State private var startDate = Date.distantPast

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(paused: !isAnimating)) { timeline in
                Canvas { context, size in
                    guard isAnimating else { return }
                    let elapsed = timeline.date.timeIntervalSince(startDate)
                    drawParticles(in: context, size: size, elapsed: elapsed)
                }
            }
            .onAppear {
                guard particles.isEmpty else { return }
                launch(in: geo.size)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: Setup

    private func launch(in size: CGSize) {
        var rng = SystemRandomNumberGenerator()
        let pad: CGFloat = 20

        particles = (0..<particleCount).map { _ in
            let uiColor = colors[Int.random(in: 0..<colors.count, using: &rng)]
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

            let startX = CGFloat.random(in: pad...(size.width - pad), using: &rng)
            let peakX  = startX + CGFloat.random(in: -60...60, using: &rng)
            let endX   = peakX  + CGFloat.random(in: -100...100, using: &rng)
            let sign: Double = Bool.random(using: &rng) ? 1 : -1

            return ConfettiParticle(
                startX: startX,
                peakX: peakX,
                endX: endX,
                startY: size.height + pad,
                peakY: CGFloat.random(in: size.height * 0.05...size.height * 0.45, using: &rng),
                delay: Double.random(in: 0...0.9, using: &rng),
                riseDuration: Double.random(in: 0.5...1.0, using: &rng),
                fallDuration: Double.random(in: 0.9...1.8, using: &rng),
                rotation0: Double.random(in: 0...(2 * .pi), using: &rng),
                rotSpeed: Double.random(in: 3...7, using: &rng) * sign,
                width: CGFloat.random(in: 6...13, using: &rng),
                height: CGFloat.random(in: 10...18, using: &rng),
                shading: .color(red: Double(r), green: Double(g), blue: Double(b))
            )
        }

        startDate = .now
        isAnimating = true

        let total = particles.map { $0.delay + $0.riseDuration + $0.fallDuration }.max() ?? 4
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(total + 0.05))
            isAnimating = false
        }
    }

    // MARK: Draw

    private func drawParticles(in context: GraphicsContext, size: CGSize, elapsed: Double) {
        for p in particles {
            let t = elapsed - p.delay
            guard t > 0 else { continue }

            let x: CGFloat
            let y: CGFloat
            let alpha: Double

            if t < p.riseDuration {
                // Cubic ease-out rise
                let progress = CGFloat(t / p.riseDuration)
                let eased = 1 - pow(1 - progress, 3)
                x = p.startX + (p.peakX - p.startX) * eased
                y = p.startY + (p.peakY - p.startY) * eased
                alpha = 1
            } else {
                let fallT = t - p.riseDuration
                guard fallT < p.fallDuration else { continue }
                // Cubic ease-in fall, linear horizontal drift
                let progress = CGFloat(fallT / p.fallDuration)
                let eased = progress * progress * progress
                x = p.peakX + (p.endX - p.peakX) * progress
                y = p.peakY + (size.height + 30 - p.peakY) * eased
                alpha = Double(1 - progress)
            }

            let angle = p.rotation0 + p.rotSpeed * t

            // Struct copy resets context state for this particle only (no heap alloc).
            var ctx = context
            ctx.opacity = alpha
            ctx.translateBy(x: x, y: y)
            ctx.rotate(by: .radians(angle))
            ctx.scaleBy(x: p.width, y: p.height)
            ctx.fill(_confettiUnitRect, with: p.shading)
        }
    }
}
