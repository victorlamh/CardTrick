import Foundation
import UserNotifications

class CalculatorState: ObservableObject {
    @Published var displayValue: String = "0"
    @Published var expressionDisplay: String = ""
    @Published var activeOperator: String? = nil
    @Published var isArmed: Bool = false
    @Published var vibrationDelay: Double = 10.0
    @Published var notificationPermissionGranted: Bool = false
    @Published var lastScheduleError: String = ""

    private var firstOperand: Double? = nil
    private var pendingOperator: String? = nil
    private var shouldResetDisplay = false

    // MARK: - Button Actions
    func tapped(_ symbol: String) {
        switch symbol {
        case "0"..."9":
            handleDigit(symbol)
        case ".":
            handleDecimal()
        case "+", "−", "×", "÷":
            handleOperator(symbol)
        case "=":
            handleEquals()
        case "AC":
            handleClear()
        case "+/-":
            handleSign()
        case "%":
            handlePercent()
        default:
            break
        }
    }

    private func handleDigit(_ d: String) {
        if shouldResetDisplay {
            displayValue = d
            shouldResetDisplay = false
        } else {
            displayValue = displayValue == "0" ? d : displayValue + d
        }
    }

    private func handleDecimal() {
        if shouldResetDisplay {
            displayValue = "0."
            shouldResetDisplay = false
            return
        }
        if !displayValue.contains(".") {
            displayValue += "."
        }
    }

    private func handleOperator(_ op: String) {
        firstOperand = Double(displayValue)
        pendingOperator = op
        expressionDisplay = formatResult(Double(displayValue) ?? 0) + op
        activeOperator = op
        shouldResetDisplay = true
    }

    private func handleEquals() {
        guard let first = firstOperand,
              let op = pendingOperator,
              let second = Double(displayValue) else { return }

        var result: Double
        switch op {
        case "+": result = first + second
        case "−": result = first - second
        case "×": result = first * second
        case "÷": result = second != 0 ? first / second : 0
        default:  result = second
        }

        displayValue = formatResult(result)
        expressionDisplay = ""
        activeOperator = nil
        firstOperand = nil
        pendingOperator = nil
        shouldResetDisplay = true

        if isArmed {
            scheduleVibration(after: vibrationDelay)
            isArmed = false  // disarm after firing
        }
    }

    private func handleClear() {
        displayValue = "0"
        firstOperand = nil
        pendingOperator = nil
        expressionDisplay = ""
        activeOperator = nil
        shouldResetDisplay = false
    }

    private func handleSign() {
        if let val = Double(displayValue) {
            displayValue = formatResult(val * -1)
        }
    }

    private func handlePercent() {
        if let val = Double(displayValue) {
            displayValue = formatResult(val / 100)
        }
    }

    private func formatResult(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 && abs(val) < 1e12 {
            return String(Int(val))
        }
        return String(val)
    }

    // MARK: - Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = granted
            }
        }
        // Check existing status too
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    private func scheduleVibration(after delay: Double) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "Reminder"       // non-empty — iOS won't suppress it
        content.body = " "               // single space — required on some versions
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, delay),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "vibration",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.lastScheduleError = error.localizedDescription
                } else {
                    self.lastScheduleError = "Scheduled OK ✓"
                }
            }
        }
    }
}
