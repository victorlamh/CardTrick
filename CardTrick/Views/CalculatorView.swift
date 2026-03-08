import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject var calc: CalculatorState
    @State private var showConfig = false

    let buttons: [[String]] = [
        ["AC", "+/-", "%", "÷"],
        ["7",  "8",   "9", "×"],
        ["4",  "5",   "6", "−"],
        ["1",  "2",   "3", "+"],
        ["⊞",  "0",   ".", "="]
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let pad: CGFloat = 16
            let spacing: CGFloat = 12
            let buttonSize = (w - pad * 2 - spacing * 3) / 4

            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top bar with secret config tap zone
                    HStack {
                        // Orange hamburger icon — purely decorative
                        Image(systemName: "list.bullet")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color(red: 1.0, green: 0.62, blue: 0.04))
                            .padding(.leading, pad)

                        Spacer()

                        // Invisible secret tap zone — top right
                        Button(action: { showConfig = true }) {
                            Color.clear.frame(width: 60, height: 44)
                        }
                    }
                    .frame(height: 44)
                    .padding(.top, 8)

                    Spacer()

                    // Expression row (e.g. "7,000÷6")
                    HStack {
                        Spacer()
                        Text(calc.expressionDisplay)
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(Color.gray)
                            .lineLimit(1)
                            .padding(.trailing, pad)
                    }
                    .padding(.bottom, 4)

                    // Main display
                    HStack {
                        Spacer()
                        Text(calc.displayValue)
                            .font(.system(size: displayFontSize(calc.displayValue), weight: .light))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .padding(.trailing, pad)
                    }
                    .padding(.bottom, 24)

                    // Button grid
                    VStack(spacing: spacing) {
                        ForEach(buttons, id: \.self) { row in
                            HStack(spacing: spacing) {
                                ForEach(row, id: \.self) { symbol in
                                    CalcButton(
                                        symbol: symbol,
                                        size: buttonSize,
                                        isActiveOp: calc.activeOperator == symbol
                                    ) {
                                        calc.tapped(symbol)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, pad)
                    .padding(.bottom, pad + geo.safeAreaInsets.bottom)
                }
            }
        }
        .sheet(isPresented: $showConfig) {
            ConfigView().environmentObject(calc)
        }
    }

    private func displayFontSize(_ value: String) -> CGFloat {
        switch value.count {
        case 0...6:  return 96
        case 7...9:  return 72
        case 10...12: return 52
        default:     return 40
        }
    }
}

// MARK: - Individual Button
struct CalcButton: View {
    let symbol: String
    let size: CGFloat
    let isActiveOp: Bool
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.easeIn(duration: 0.08)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.08)) { pressed = false }
            }
            action()
        }) {
            ZStack {
                Circle()
                    .fill(pressed ? pressedColor : backgroundColor)
                    .frame(width: size, height: size)

                Text(displaySymbol)
                    .font(labelFont)
                    .foregroundColor(labelColor)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var backgroundColor: Color {
        if isActiveOp {
            return .white  // active operator shows inverted
        }
        switch symbol {
        case "÷", "×", "−", "+", "=":
            return Color(red: 1.0, green: 0.62, blue: 0.04)  // orange
        case "AC", "+/-", "%":
            return Color(red: 0.65, green: 0.65, blue: 0.65)  // light grey
        default:
            return Color(red: 0.20, green: 0.20, blue: 0.20)  // dark grey
        }
    }

    private var pressedColor: Color {
        switch symbol {
        case "÷", "×", "−", "+", "=":
            return Color(red: 1.0, green: 0.80, blue: 0.40)
        case "AC", "+/-", "%":
            return Color(red: 0.85, green: 0.85, blue: 0.85)
        default:
            return Color(red: 0.35, green: 0.35, blue: 0.35)
        }
    }

    private var labelColor: Color {
        if isActiveOp { return Color(red: 1.0, green: 0.62, blue: 0.04) }
        return .white
    }

    private var labelFont: Font {
        switch symbol {
        case "AC":
            return .system(size: 32, weight: .medium)
        case "+/-", "%", "÷", "×", "−", "+", "=":
            return .system(size: 36, weight: .medium)
        case "⊞":
            return .system(size: 28, weight: .regular)
        default:
            return .system(size: 38, weight: .regular)
        }
    }

    private var displaySymbol: String {
        switch symbol {
        case "×": return "×"
        case "÷": return "÷"
        case "⊞": return "⊞"
        default: return symbol
        }
    }
}
