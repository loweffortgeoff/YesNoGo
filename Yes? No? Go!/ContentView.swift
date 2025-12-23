//
//  ContentView.swift
//  Yes? No? Go!
//
//  Created by Geoffrey Silva on 11/1/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import AVFoundation
import AudioToolbox
import Combine

// MARK: - Quick Action Manager
class QuickActionManager: ObservableObject {
    static let shared = QuickActionManager()
    
    @Published var pendingQuickAction: String?
    
    private init() {}
}

struct MainCardBackground: View {
    let colors: [Color]
    let material: Material

    private var accentColor: Color {
        colors.first ?? .clear
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(material)

            RoundedRectangle(cornerRadius: 24)
                .fill(accentColor.opacity(0.05))

            RoundedRectangle(cornerRadius: 24)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        }
    }
}

struct SelectorBackground: View {
    let material: Material
    let accent: Color?

    private var accentColor: Color { accent ?? .clear }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(material)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(accentColor.opacity(0.1))
                )

            RoundedRectangle(cornerRadius: 25)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        }
    }
}

struct ContentView: View {
    @State private var activeMode = "coin"
    @State private var isAnimating = false
    @State private var result = ""
    @State private var customChoices = ["", ""]
    @State private var showResult = false
    @State private var coinRotation = 0.0
    @State private var showAlert = false
    @State private var dragOffset: CGSize = .zero
    @State private var selectedIndex: Int = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var showCredits = false
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.scenePhase) private var scenePhase

    private let modes = ["coin", "yesno", "custom", "rps"]
    private let modeLabels = ["Coin Flip", "Yes / No", "Custom", "RPS"]
    private let modeIcons = ["centsign.circle", "questionmark.circle", "shuffle", "hand.raised"]
    
    // Haptic feedback generators (iOS only)
    #if canImport(UIKit)
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    #endif
    
    // Audio feedback
    @State private var audioPlayer: AVAudioPlayer?
    
    // Dynamic gradient colors based on mode and appearance
    private var currentGradientColors: [Color] {        
        switch activeMode {
        case "coin":
            return systemColorScheme == .dark ? 
                [.yellow, .orange, .red] : 
                [.yellow, .orange, .pink]
        case "yesno":
            return systemColorScheme == .dark ? 
                [.blue, .cyan, .purple] : 
                [.blue, .cyan, .indigo]
        case "custom":
            return systemColorScheme == .dark ?
                [.green, .mint, .teal] :
                [.green, .mint, .cyan]
        case "rps":
            return systemColorScheme == .dark ?
                [.purple, .pink, .orange] :
                [.purple, .indigo, .pink]
        default:
            return systemColorScheme == .dark ?
                [.purple, .pink, .red] :
                [.purple, .pink, .blue]
        }
    }
    
    // Adaptive text colors
    private var primaryTextColor: Color {
        systemColorScheme == .dark ? .white : .black
    }
    
    private var secondaryTextColor: Color {
        systemColorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.7)
    }
    
    // Adaptive background materials
    private var cardMaterial: Material {
        return systemColorScheme == .dark ? .ultraThinMaterial : .regularMaterial
    }
    
    private var selectorMaterial: Material {
        return systemColorScheme == .dark ? .regularMaterial : .thickMaterial
    }
    
    // MARK: - Haptic Feedback Helpers
    private func triggerImpactFeedback() {
        #if canImport(UIKit)
        impactFeedback.impactOccurred()
        #endif
    }
    
    private func triggerSelectionFeedback() {
        #if canImport(UIKit)
        selectionFeedback.selectionChanged()
        #endif
    }
    
    private func triggerNotificationFeedback(_ type: NotificationFeedbackType) {
        #if canImport(UIKit)
        switch type {
        case .success:
            notificationFeedback.notificationOccurred(.success)
        case .error:
            notificationFeedback.notificationOccurred(.error)
        }
        #endif
    }
    
    private enum NotificationFeedbackType {
        case success, error
    }
    
    // MARK: - Quick Action Handling
    private func handlePendingQuickAction() {
        guard let quickAction = QuickActionManager.shared.pendingQuickAction else { return }
        
        // Clear the pending action
        QuickActionManager.shared.pendingQuickAction = nil
        
        // Handle the action
        handleQuickAction(quickAction)
    }
    
    private func handleQuickAction(_ actionType: String) {
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        
        switch actionType {
        case "\(bundleId).flipcoin":
            // Switch to coin mode and flip immediately
            withAnimation(.bouncy(duration: 0.4)) {
                activeMode = "coin"
                selectedIndex = 0
                resetResult()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                flipCoin()
            }
            
        case "\(bundleId).yesno":
            // Switch to yes/no mode and decide immediately
            withAnimation(.bouncy(duration: 0.4)) {
                activeMode = "yesno"
                selectedIndex = 1
                resetResult()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                generateYesNo()
            }
            
        case "\(bundleId).custom":
            // Switch to custom mode
            withAnimation(.bouncy(duration: 0.4)) {
                activeMode = "custom"
                selectedIndex = 2
                resetResult()
            }
            // Don't auto-execute custom since it needs user input

        case "\(bundleId).rps":
            // Switch to RPS mode and play immediately
            withAnimation(.bouncy(duration: 0.4)) {
                activeMode = "rps"
                selectedIndex = 3
                resetResult()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                playRPS()
            }

        default:
            break
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: currentGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.8), value: activeMode)
            
            // Subtle background blur layer for depth
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.1)
                .ignoresSafeArea()
                .blur(radius: 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .center) {
                        Text("Yes? No? Go!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(primaryTextColor)
                            .multilineTextAlignment(.center)
                        
                        Text("Let chance decide your next move!")
                            .foregroundColor(secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    
                    // Glass chip selector with swipe functionality
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            ForEach(modes.indices, id: \.self) { index in
                                Button(action: {
                                    triggerSelectionFeedback()
                                    playSound("select")
                                    withAnimation(.bouncy(duration: 0.4)) {
                                        selectedIndex = index
                                        activeMode = modes[index]
                                        resetResult()
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: modeIcons[index])
                                            .font(.system(size: 18))
                                        Text(modeLabels[index])
                                            .fontWeight(.semibold)
                                            .font(.system(size: 10))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 10)
                                    .background(
                                        // Glass effect background with dynamic theming
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(cardMaterial)
                                            .overlay(
                                                ZStack {
                                                    // Selected state gets mode color accent
                                                    if selectedIndex == index {
                                                        RoundedRectangle(cornerRadius: 20)
                                                            .fill(currentGradientColors.first?.opacity(0.15) ?? Color.clear)
                                                    }
                                                    
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(
                                                            selectedIndex == index ?
                                                            (currentGradientColors.first?.opacity(0.8) ?? Color.primary.opacity(0.6)) :
                                                                Color.primary.opacity(0.2),
                                                            lineWidth: selectedIndex == index ? 2 : 1
                                                        )
                                                }
                                            )
                                    )
                                    .foregroundColor(
                                        systemColorScheme == .dark ?
                                            (selectedIndex == index ? .white : .white.opacity(0.85)) :
                                            (selectedIndex == index ? .black : .black.opacity(0.85))
                                    )
                                    .scaleEffect(selectedIndex == index ? 1.05 : 1.0)
                                }
                                .accessibilityLabel(modeLabels[index])
                                .accessibilityHint("Switch to \(modeLabels[index]) mode")
                                .accessibilityAddTraits(selectedIndex == index ? .isSelected : [])
                            }
                        }
                        .offset(x: dragOffset.width)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    let threshold: CGFloat = 50
                                    let dragDirection = value.translation.width
                                    
                                    withAnimation(.bouncy(duration: 0.4)) {
                                        if dragDirection > threshold && selectedIndex > 0 {
                                            // Swipe right - go to previous
                                            triggerSelectionFeedback()
                                            playSound("select")
                                            selectedIndex -= 1
                                        } else if dragDirection < -threshold && selectedIndex < modes.count - 1 {
                                            // Swipe left - go to next
                                            triggerSelectionFeedback()
                                            playSound("select")
                                            selectedIndex += 1
                                        }
                                        
                                        activeMode = modes[selectedIndex]
                                        resetResult()
                                        dragOffset = .zero
                                    }
                                }
                        )
                        .animation(.bouncy(duration: 0.4), value: selectedIndex)
                    }
                    .padding(16)
                    .background(SelectorBackground(material: selectorMaterial, accent: currentGradientColors.first))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    
                    VStack {
                        if activeMode == "coin" {
                            coinFlipView()
                        } else if activeMode == "yesno" {
                            yesNoView()
                        } else if activeMode == "custom" {
                            customChoiceView()
                        } else {
                            rpsView()
                        }
                    }
                    .padding(32)
                    .background(MainCardBackground(colors: currentGradientColors, material: cardMaterial))
                    .shadow(color: {
                        let cardShadow = (currentGradientColors.first ?? .clear).opacity(0.3)
                        return cardShadow
                    }(), radius: 20, x: 0, y: 10)
                    
                    Text("Perfect for lunch decisions, weekend plans, and settling friendly debates! 🎲")
                        .foregroundColor(secondaryTextColor)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 16)
            }
        }
        .alert("Please enter at least 2 choices!", isPresented: $showAlert) {
            Button("OK") { }
        }
        .onAppear {
            // Handle Quick Actions when app becomes active
            handlePendingQuickAction()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                handlePendingQuickAction()
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: {
                showCredits = true
            }) {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(primaryTextColor.opacity(0.7))
                    .padding(20)
            }
        }
        .sheet(isPresented: $showCredits) {
            CreditsView()
        }
    }
    
    private func coinFlipView() -> some View {
        // local constant for shadow color
        let coinShadow = (currentGradientColors.first ?? .yellow).opacity(0.4)
        let isTails = coinRotation > 90 && coinRotation < 270
        let coinFace = isTails ? "tails" : "heads"
        let coinA11yLabel = isAnimating ? "Coin is flipping" : "Coin showing \(coinFace)"
        let coinA11yHint = isAnimating ? "Wait for the coin to land" : "The coin is ready to flip"
        
        return VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.yellow, .orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 128, height: 128)
                    .overlay(
                        Circle()
                            .stroke(LinearGradient(colors: currentGradientColors, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 4)
                    )
                    .shadow(color: coinShadow, radius: isAnimating ? 15 : 8)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                Text(isTails ? "🦅" : "👑")
                    .font(.system(size: 64))
                    .rotation3DEffect(
                        .degrees(coinRotation),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.3
                    )
            }
            .rotation3DEffect(
                .degrees(isAnimating ? 1440 : 0), // 4 full rotations
                axis: (x: 1, y: 0, z: 0) // Flip around X-axis for realistic coin flip
            )
            .offset(y: isAnimating ? -50 : 0) // Coin goes up then comes down
            .animation(
                isAnimating ?
                    .easeInOut(duration: 1.8)
                    .repeatCount(1, autoreverses: false) :
                        .none,
                value: isAnimating
            )
            .accessibilityLabel(coinA11yLabel)
            .accessibilityHint(coinA11yHint)
            
            if showResult {
                VStack {
                    Text(result)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(primaryTextColor)
                    
                    Text(result == "HEADS" ? "👑" : "🦅")
                        .font(.title)
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.bouncy(duration: 0.6), value: showResult)
                .accessibilityLabel("Coin flip result: \(result)")
                .accessibilityHint("The coin landed on \(result.lowercased())")
            }
            
            Button(action: {
                triggerImpactFeedback()
                playSound("coin")
                flipCoin()
            }) {
                Text(isAnimating ? "Flipping..." : "Flip Coin!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: currentGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .scaleEffect(isAnimating ? 0.95 : 1.0)
                    .shadow(radius: 8)
            }
            .disabled(isAnimating)
            .opacity(isAnimating ? 0.5 : 1.0)
            .accessibilityLabel(isAnimating ? "Flipping coin" : "Flip coin")
            .accessibilityHint(isAnimating ? "Please wait while the coin is being flipped" : "Tap to flip the coin and get heads or tails")
        }
    }
    
    private func yesNoView() -> some View {
        let thinkingLabel = isAnimating ? "Thinking and deciding" : "Thinking emoji, ready to decide"
        let thinkingHint = isAnimating ? "Wait while a yes or no decision is being made" : "Tap the button below to get a yes or no answer"
        
        return VStack(spacing: 30) {
            Text("🤔")
                .font(.system(size: 128))
                .scaleEffect(isAnimating ? 1.25 : 1.0)
                .opacity(isAnimating ? 0.5 : 1.0)
                .animation(.easeInOut(duration: 0.8), value: isAnimating)
                .accessibilityLabel(thinkingLabel)
                .accessibilityHint(thinkingHint)
            
            if showResult {
                let decisionResult = result
                
                VStack {
                    Text(result)
                        .font(.system(size: 48))
                        .fontWeight(.bold)
                        .foregroundColor(result == "YES!" ? .green : .red)
                    
                    Text(result == "YES!" ? "✅" : "❌")
                        .font(.largeTitle)
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.bouncy(duration: 0.6), value: showResult)
                .accessibilityLabel("Decision result: \(decisionResult)")
                .accessibilityHint("The answer to your yes or no question is \(decisionResult)")
            }
            
            let decideButtonLabel = isAnimating ? "Deciding..." : "Yes or No?"
            let decideA11yLabel = isAnimating ? "Making decision" : "Get yes or no answer"
            let decideA11yHint = isAnimating ? "Please wait while a decision is being made" : "Tap to get a random yes or no answer to your question"
            
            Button(action: {
                triggerImpactFeedback()
                playSound("decision")
                generateYesNo()
            }) {
                Text(decideButtonLabel)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: currentGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .scaleEffect(isAnimating ? 0.95 : 1.0)
                    .shadow(radius: 8)
            }
            .disabled(isAnimating)
            .opacity(isAnimating ? 0.5 : 1.0)
            .accessibilityLabel(decideA11yLabel)
            .accessibilityHint(decideA11yHint)
        }
    }
    
    private func customChoiceView() -> some View {
        let addDisabled = customChoices.count >= 6
        let addButtonTextColor: Color = systemColorScheme == .dark ? .white : .black
        let addButtonBG: Color = systemColorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
        let textFieldBG: Color = systemColorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
        let textFieldStroke: Color = systemColorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.15)
        let primaryFG = primaryTextColor
        
        return VStack(spacing: 20) {
            Text("Enter Your Options")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(primaryFG)
            
            VStack(spacing: 12) {
                ForEach(customChoices.indices, id: \.self) { index in
                    HStack {
                        TextField("Option \(index + 1)...", text: $customChoices[index])
                            .padding(12)
                            .background(textFieldBG)
                            .foregroundColor(primaryFG)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(textFieldStroke, lineWidth: 1)
                            )
                            .accessibilityLabel("Option \(index + 1)")
                            .accessibilityHint("Enter a choice for random selection")
                        
                        if customChoices.count > 2 {
                            Button(action: {
                                triggerImpactFeedback()
                                playSound("error")
                                removeChoice(at: index)
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.red.opacity(0.8))
                                    .padding(12)
                                    .background(Color.red.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .accessibilityLabel("Remove option \(index + 1)")
                            .accessibilityHint("Remove this option from the list")
                        }
                    }
                }
            }
            
            Button(action: {
                triggerSelectionFeedback()
                playSound("select")
                addChoice()
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Option")
                }
                .foregroundColor(addButtonTextColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(addButtonBG)
                .clipShape(Capsule())
            }
            .disabled(addDisabled)
            .opacity(addDisabled ? 0.5 : 1.0)
            .accessibilityLabel("Add option")
            .accessibilityHint(addDisabled ? "Maximum of 6 options reached" : "Add another option to choose from")
            
            if showResult {
                let winner = result
                
                VStack {
                    Text("The winner is...")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(primaryFG)
                    
                    Text(result)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .padding(16)
                        .background(Color.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Text("🎉")
                        .font(.largeTitle)
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.bouncy(duration: 0.6), value: showResult)
                .accessibilityLabel("Selection result: \(winner)")
                .accessibilityHint("The randomly chosen option from your custom choices is \(winner)")
            }
            
            let pickButtonLabel = isAnimating ? "Choosing..." : "Pick for Me!"
            let pickA11yLabel = isAnimating ? "Making selection" : "Pick random option"
            let pickA11yHint = isAnimating ? "Please wait while a random choice is being selected" : "Tap to randomly select one of your custom options"
            
            Button(action: {
                triggerImpactFeedback()
                playSound("shuffle")
                chooseCustom()
            }) {
                Text(pickButtonLabel)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: currentGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .scaleEffect(isAnimating ? 0.95 : 1.0)
                    .shadow(radius: 8)
            }
            .disabled(isAnimating)
            .opacity(isAnimating ? 0.5 : 1.0)
            .accessibilityLabel(pickA11yLabel)
            .accessibilityHint(pickA11yHint)
        }
    }
    
    private func rpsView() -> some View {
        let thinkingLabel = isAnimating ? "Choosing rock, paper, or scissors" : "Hand emojis, ready to play"
        let thinkingHint = isAnimating ? "Wait while a choice is being made" : "Tap the button below to see what the opponent chose"

        return VStack(spacing: 30) {
            HStack(spacing: 20) {
                Text("🪨")
                    .font(.system(size: 48))
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0.5 : 1.0)
                Text("📄")
                    .font(.system(size: 48))
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0.5 : 1.0)
                Text("✂️")
                    .font(.system(size: 48))
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0.5 : 1.0)
            }
            .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: isAnimating)
            .accessibilityLabel(thinkingLabel)
            .accessibilityHint(thinkingHint)

            Text("Think of your choice...")
                .font(.title3)
                .foregroundColor(secondaryTextColor)

            if showResult {
                VStack(spacing: 12) {
                    Text("Opponent chose:")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryTextColor)

                    Text(rpsEmoji(for: result))
                        .font(.system(size: 80))

                    Text(result)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(primaryTextColor)
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.bouncy(duration: 0.6), value: showResult)
                .accessibilityLabel("Opponent chose \(result)")
                .accessibilityHint("Compare this to your mental choice to see if you won")
            }

            let playButtonLabel = isAnimating ? "Choosing..." : "Shoot!"
            let playA11yLabel = isAnimating ? "Making choice" : "Reveal opponent's choice"
            let playA11yHint = isAnimating ? "Please wait while a choice is being made" : "Tap to see what the opponent chose"

            Button(action: {
                triggerImpactFeedback()
                playSound("decision")
                playRPS()
            }) {
                Text(playButtonLabel)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: currentGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .scaleEffect(isAnimating ? 0.95 : 1.0)
                    .shadow(radius: 8)
            }
            .disabled(isAnimating)
            .opacity(isAnimating ? 0.5 : 1.0)
            .accessibilityLabel(playA11yLabel)
            .accessibilityHint(playA11yHint)
        }
    }

    private func rpsEmoji(for choice: String) -> String {
        switch choice {
        case "Rock": return "🪨"
        case "Paper": return "📄"
        case "Scissors": return "✂️"
        default: return "❓"
        }
    }

    private func addChoice() {
        if customChoices.count < 6 {
            customChoices.append("")
        }
    }
    
    private func removeChoice(at index: Int) {
        if customChoices.count > 2 {
            customChoices.remove(at: index)
        }
    }
    
    private func flipCoin() {
        isAnimating = true
        showResult = false
        
        // Generate result immediately but don't show it until animation completes
        let coinResult = Bool.random() ? "HEADS" : "TAILS"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            result = coinResult
            coinRotation = coinResult == "HEADS" ? 0 : 180
            isAnimating = false
            
            withAnimation(.bouncy(duration: 0.6)) {
                showResult = true
            }
            
            // Success haptic feedback and sound when result is shown
            triggerNotificationFeedback(.success)
            
            // Play different sounds based on coin result
            if coinResult == "TAILS" {
                playSound("eagle")
            } else {
                playSound("crown")
            }
        }
    }
    
    private func generateYesNo() {
        isAnimating = true
        showResult = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            result = Bool.random() ? "YES!" : "NO!"
            isAnimating = false
            
            withAnimation(.bouncy(duration: 0.6)) {
                showResult = true
            }
            
            // Success haptic feedback and sound when result is shown
            triggerNotificationFeedback(.success)
            playSound("success")
        }
    }
    
    private func chooseCustom() {
        let validChoices = customChoices.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        if validChoices.count < 2 {
            triggerNotificationFeedback(.error)
            playSound("error")
            showAlert = true
            return
        }
        
        isAnimating = true
        showResult = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let randomChoice = validChoices.randomElement() {
                result = randomChoice
            }
            isAnimating = false
            
            withAnimation(.bouncy(duration: 0.6)) {
                showResult = true
            }
            
            // Success haptic feedback and sound when result is shown
            triggerNotificationFeedback(.success)
            playSound("success")
        }
    }

    private func playRPS() {
        isAnimating = true
        showResult = false

        let choices = ["Rock", "Paper", "Scissors"]

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let rpsResult = choices.randomElement()!
            result = rpsResult
            isAnimating = false

            withAnimation(.bouncy(duration: 0.6)) {
                showResult = true
            }

            // Success haptic feedback and sound when result is shown
            triggerNotificationFeedback(.success)

            // Play different sounds based on RPS result
            switch rpsResult {
            case "Rock":
                playSound("thud")
            case "Paper":
                playSound("paper")
            case "Scissors":
                playSound("slick")
            default:
                playSound("success")
            }
        }
    }

    private func resetResult() {
        withAnimation(.easeOut(duration: 0.3)) {
            showResult = false
        }
        result = ""
    }
    
    private func playSound(_ soundName: String) {
        // Use system sounds for lightweight playback
        switch soundName {
        case "coin":
            AudioServicesPlaySystemSound(1306) // Peek sound - bright and metallic like coin
        case "decision":
            AudioServicesPlaySystemSound(1057) // SMS Received 1 - subtle chime
        case "shuffle":
            AudioServicesPlaySystemSound(1519) // Begin Video Record - shuffling sound
        case "select":
            AudioServicesPlaySystemSound(1519) // Gentle selection sound
        case "success":
            AudioServicesPlaySystemSound(1025) // PhotoShutter - success sound
        case "eagle":
            if let url = Bundle.main.url(forResource: "eagle-sound-by-torma-368637", withExtension: "mp3") {
                audioPlayer = try? AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            }
        case "crown":
            if let url = Bundle.main.url(forResource: "descent-whoosh-long-cinematic-sound-effect-405921", withExtension: "mp3") {
                audioPlayer = try? AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            }
        case "thud":
            // Rock sound - heavy thud
            if let url = Bundle.main.url(forResource: "thud-82914", withExtension: "mp3") {
                audioPlayer = try? AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            }
        case "slick":
            // Scissors sound - slick cutting
            if let url = Bundle.main.url(forResource: "steel-blade-slice-4-188216", withExtension: "mp3") {
                audioPlayer = try? AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            }
        case "paper":
            // Paper sound - crumpling paper
            if let url = Bundle.main.url(forResource: "crumping-paper-109585", withExtension: "mp3") {
                audioPlayer = try? AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            }
        case "error":
            AudioServicesPlaySystemSound(1053) // Error sound
        default:
            break
        }
    }

}

// MARK: - Credits View
struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Sound Effects")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Eagle Sound")
                            .font(.headline)
                        Text("by Torma")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("From Pixabay")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cinematic Whoosh")
                            .font(.headline)
                        Text("Descent Whoosh Long")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("From Pixabay")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Thud Sound")
                            .font(.headline)
                        Text("Rock Paper Scissors - Rock")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("From Pixabay")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Steel Blade Slice")
                            .font(.headline)
                        Text("Rock Paper Scissors - Scissors")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("From Pixabay")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Crumpling Paper")
                            .font(.headline)
                        Text("Rock Paper Scissors - Paper")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("From Pixabay")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                AboutSectionView(currentAppName: "Yes? No? Go!")
            }
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
