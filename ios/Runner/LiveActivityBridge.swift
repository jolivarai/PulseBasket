import ActivityKit
import Foundation

/// Gestión de la Live Activity (pantalla de bloqueo + Dynamic Island).
///
/// Los botones del widget no llaman a Flutter: ejecutan un `LiveActivityIntent`
/// (iOS 17+) que escribe el comando en el App Group. Este puente lee ese valor
/// una vez por segundo y lo reenvía a Dart por el canal `pulso/live_activity`.
///
/// Se usa App Group porque la extensión del widget y la app son procesos
/// distintos: sin App Group no pueden compartir ni una cadena de texto.
@available(iOS 16.1, *)
final class LiveActivityBridge {

    static let shared = LiveActivityBridge()

    /// Debe coincidir con `AppConfig.iosAppGroup` (Dart), con el App Group de
    /// Xcode y con `Runner.entitlements`.
    static let appGroup = "group.com.pulso.basket"
    static let commandKey = "pendingCommand"

    private var activity: Activity<PulsoActivityAttributes>?
    private var pollTimer: Timer?
    private var onCommand: ((String) -> Void)?

    // ────────────────────────────────────────────────────────── ciclo ──

    func start(title: String, targetMeters: Double) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // Si quedó una actividad huérfana de una sesión anterior, se cierra.
        Task { await endAll() }

        let state = PulsoActivityAttributes.ContentState(
            distance: "0 m",
            pace: "--",
            remaining: targetMeters > 0 ? "Objetivo \(Int(targetMeters / 1000)) km" : "",
            progress: 0,
            paused: false
        )
        let attributes = PulsoActivityAttributes(title: title)

        do {
            if #available(iOS 16.2, *) {
                activity = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
            } else {
                activity = try Activity.request(
                    attributes: attributes,
                    contentState: state,
                    pushType: nil
                )
            }
        } catch {
            // Sin Live Activities (ajustes del sistema) el GPS sigue funcionando:
            // la app no debe romperse por esto.
            print("LiveActivity start error: \(error)")
        }
    }

    func update(
        distance: String,
        pace: String,
        remaining: String,
        progress: Double,
        paused: Bool
    ) {
        guard let activity else { return }
        let state = PulsoActivityAttributes.ContentState(
            distance: distance,
            pace: pace,
            remaining: remaining,
            progress: progress,
            paused: paused
        )
        Task {
            if #available(iOS 16.2, *) {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            } else {
                await activity.update(using: state)
            }
        }
    }

    func end(summary: String) {
        guard let activity else { return }
        let state = PulsoActivityAttributes.ContentState(
            distance: summary,
            pace: "",
            remaining: "",
            progress: 1,
            paused: true
        )
        Task {
            if #available(iOS 16.2, *) {
                await activity.end(
                    ActivityContent(state: state, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            } else {
                await activity.end(using: state, dismissalPolicy: .immediate)
            }
            self.activity = nil
        }
    }

    private func endAll() async {
        for running in Activity<PulsoActivityAttributes>.activities {
            if #available(iOS 16.2, *) {
                await running.end(nil, dismissalPolicy: .immediate)
            } else {
                // iOS 16.1: no existe `end(_:dismissalPolicy:)`.
                await running.end(dismissalPolicy: .immediate)
            }
        }
        activity = nil
    }

    // ─────────────────────────────────────── comandos del widget ──

    /// Lee y limpia el comando pendiente escrito por el App Intent.
    func consumeCommand() -> String? {
        guard let defaults = UserDefaults(suiteName: Self.appGroup) else { return nil }
        guard let value = defaults.string(forKey: Self.commandKey), !value.isEmpty else {
            return nil
        }
        defaults.removeObject(forKey: Self.commandKey)
        return value
    }

    /// Sondeo ligero (1 Hz) mientras hay una sesión activa.
    /// No usa notificaciones Darwin porque el proceso ya está despierto por el GPS.
    func startPolling(onCommand: @escaping (String) -> Void) {
        self.onCommand = onCommand
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let command = self.consumeCommand() else { return }
            self.onCommand?(command)
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
}
