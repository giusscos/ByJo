//
//  OnboardingComponents.swift
//  ByJo
//

import SwiftUI
import UIKit

// MARK: - Animation Helper

extension View {
    func onboardingAppear(_ appeared: Bool, delay: Double = 0) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .blur(radius: appeared ? 0 : 8)
            .offset(y: appeared ? 0 : 20)
            .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(delay), value: appeared)
    }
}

// MARK: - StatCard

struct StatCard: View {
    let value: String
    let label: String
    let accent: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.weight(.bold))
                .foregroundStyle(accent)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 16).fill(accent.opacity(0.08)))
    }
}

// MARK: - FactRow

struct FactRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Gradient Blur Background

struct GradientBlurBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> GradientBlurUIView { GradientBlurUIView() }
    func updateUIView(_ uiView: GradientBlurUIView, context: Context) {}
}

class GradientBlurUIView: UIView {
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let gradientMask = CAGradientLayer()

    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        backgroundColor = .clear
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        gradientMask.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradientMask.locations = [0.0, 0.4]
        gradientMask.startPoint = CGPoint(x: 0, y: 0)
        gradientMask.endPoint = CGPoint(x: 0, y: 1)
        layer.mask = gradientMask
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientMask.frame = bounds
    }
}
