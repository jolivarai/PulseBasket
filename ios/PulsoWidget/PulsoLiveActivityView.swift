import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Live Activity: pantalla de bloqueo + Dynamic Island.
///
/// El target de la extensión tiene deployment target 16.1, de modo que las
/// APIs de Live Activity están siempre disponibles. Los botones interactivos
/// (`Button(intent:)`) requieren iOS 17: en 16.1–16.4 se usa `Link`, que abre
/// la app con el esquema `pulso://` (un toque, misma función).
struct PulsoLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PulsoActivityAttributes.self) { context in
            PulsoLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.82))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.distance, systemImage: "figure.run")
                        .font(.caption.bold())
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.pace)
                        .font(.caption.bold())
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        PulsoControls(state: context.state, compact: true)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: context.state.paused ? "pause.fill" : "figure.run")
            } compactTrailing: {
                Text(context.state.distance)
                    .font(.caption2.bold())
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "figure.run")
            }
        }
    }
}

/// Vista de pantalla de bloqueo (el "widget" que el usuario ve con el móvil
/// bloqueado).
private struct PulsoLockScreenView: View {
    let context: ActivityViewContext<PulsoActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(context.attributes.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                Text(context.state.paused ? "PAUSADO" : "GRABANDO")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(context.state.paused ? .orange : .green)
            }

            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(context.state.distance)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 1) {
                    Text(context.state.pace)
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text("ritmo / vel.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
            }

            ProgressView(value: min(max(context.state.progress, 0), 1))
                .tint(.orange)

            HStack {
                Text(context.state.remaining)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
            }

            PulsoControls(state: context.state, compact: false)
        }
        .padding(16)
    }
}

/// Pausar/Reanudar + Detener.
private struct PulsoControls: View {
    let state: PulsoActivityAttributes.ContentState
    let compact: Bool

    /// `UserDefaults(suiteName:)` devuelve nil si el App Group no está en los
    /// entitlements (típico con Apple ID gratuito). En ese caso los botones
    /// interactivos no podrían comunicarse con la app, así que se usa el
    /// deep link `pulso://`, que funciona en cualquier cuenta.
    private var hasAppGroup: Bool {
        UserDefaults(suiteName: PulsoCommandWriter.appGroup) != nil
    }

    var body: some View {
        HStack(spacing: 10) {
            if #available(iOS 17.0, *), hasAppGroup {
                // iOS 17+: el botón ejecuta un LiveActivityIntent, no abre la app.
                if state.paused {
                    Button(intent: PulsoResumeIntent()) {
                        label("Reanudar", "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    Button(intent: PulsoPauseIntent()) {
                        label("Pausar", "pause.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }

                Button(intent: PulsoStopIntent()) {
                    label("Detener", "stop.fill")
                }
                .buttonStyle(.bordered)
                .tint(.red)

            } else {
                // iOS 16.1–16.4: no hay botones interactivos; Link abre la app.
                let target = state.paused ? "resume" : "pause"
                Link(destination: URL(string: "pulso://\(target)")!) {
                    label(state.paused ? "Reanudar" : "Pausar",
                          state.paused ? "play.fill" : "pause.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(state.paused ? .green : .orange)

                Link(destination: URL(string: "pulso://stop")!) {
                    label("Detener", "stop.fill")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }

    @ViewBuilder
    private func label(_ text: String, _ icon: String) -> some View {
        if compact {
            Image(systemName: icon).font(.caption.bold())
        } else {
            Label(text, systemImage: icon)
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
        }
    }
}
