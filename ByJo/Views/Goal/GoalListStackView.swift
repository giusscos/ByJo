//
//  GoalListStackView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 02/08/25.
//

import SwiftUI

struct GoalListStackView: View {
    var goals: [Goal]
    
    @State private var xOffsets: [Double] = [0.0]
    @State private var zIndexes: [Double] = [0.0]
    @State private var rotates: [Double] = [0.0]
    
    var body: some View {
        Section {
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                
                ZStack(alignment: .top) {
                    ForEach(Array(goals.enumerated()), id: \.offset) { index, goal in
                        if let asset = goal.asset, xOffsets.count == goals.count, zIndexes.count == goals.count {
                            GoalRowView(goal: goal, asset: asset)
                                .offset(x: xOffsets[index])
                                .rotationEffect(Angle(degrees: rotates[index]))
                                .zIndex(zIndexes[index])
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            withAnimation {
                                                xOffsets[index] = value.translation.width
                                            }
                                        }
                                        .onEnded { value in
                                            let threshold = screenWidth * 0.5
                                            
                                            if xOffsets[index] >= threshold || xOffsets[index] <= -threshold {
                                                withAnimation {
                                                    zIndexes[index] = zIndexes[index] - 1
                                                    xOffsets[index] = .zero
                                                    rotates[index] = .random(in: -4...4)
                                                }
                                            }
                                            
                                            withAnimation {
                                                xOffsets[index] = .zero
                                            }
                                        }
                                )
                        }
                    }
                }
                .padding()
            }
            .frame(height: 250)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .onAppear() {
            let goalsCount = goals.count
            
            let startingArray = Array(repeating: 0.0, count: goalsCount)
            
            xOffsets = startingArray
            zIndexes = startingArray
            
            for _ in goals {
                rotates.append(.random(in: -4...4))
            }
        }
        .onDisappear() {
            let goalsCount = goals.count
            
            let startingArray = Array(repeating: 0.0, count: goalsCount)
            
            zIndexes = startingArray
        }
    }
}

#Preview {
    GoalListStackView(
        goals: [Goal(title: "Goal 1", startingAmount: 1000.0, targetAmount: 2000.0)]
    )
}
