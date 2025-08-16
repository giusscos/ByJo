//
//  GoalListStackView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 02/08/25.
//

import SwiftData
import SwiftUI

struct GoalListStackView: View {
    @Query(filter: #Predicate<Goal> { goal in
        goal.completedGoal == nil
    }, sort: \Goal.dueDate, order: .reverse) var goals: [Goal]
    
    @State private var xOffsets: [Double] = [0.0]
    @State private var zIndexes: [Double] = [0.0]
    @State private var rotates: [Double] = [0.0]
    
    var body: some View {
        if !goals.isEmpty {
            Section {
                HStack {
                    Spacer()
                    GeometryReader { geometry in
                        let screenWidth = geometry.size.width
                        
                        ZStack {
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
                    .frame(maxWidth: 500)
                    Spacer()
                }
                .frame(height: 200)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            .onChange(of: goals) { _, newValue in
                calculateGoalsPositionAndRotation(goals: newValue)
            }
            .onAppear() {
                calculateGoalsPositionAndRotation(goals: goals)
            }
            .onDisappear() {
                restoreGoalsZIndexes(goals: goals)
            }
        }
    }
    
    private func calculateGoalsPositionAndRotation(goals: [Goal]) {
        let goalsCount = goals.count
        
        let startingArray = Array(repeating: 0.0, count: goalsCount)
        
        xOffsets = startingArray
        zIndexes = startingArray
        
        for _ in goals {
            rotates.append(.random(in: -4...4))
        }
    }
    
    private func restoreGoalsZIndexes(goals: [Goal]) {
        let goalsCount = goals.count
        
        let startingArray = Array(repeating: 0.0, count: goalsCount)
        
        zIndexes = startingArray
    }
}

#Preview {
    GoalListStackView()
}
