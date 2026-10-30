import AppIntents
import Foundation

/// Los botones de la Live Activity no pueden llamar a Flutter: corren en otro
/// proceso. El puente es el App Group.
enum PulsoCommandWriter {
    static let appGroup = "group.com.pulso.basket"
    static let key = "pendingCommand"

    static func write(_ command: String) {
        UserDefaults(suiteName: appGroup)?.set(command, forKey: key)
    }
}

// Los tres intents son SIN parámetros a propósito: es la forma más estable de
// AppIntents y evita problemas de serialización entre app y extensión.
// `LiveActivityIntent` se ejecuta en el proceso de la app (no la abre), así el
// puente nativo lee el comando en menos de un segundo.
//
// Este archivo está incluido en los dos targets (Runner y PulsoWidget).

@available(iOS 17.0, *)
struct PulsoPauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pausar entreno"
    static var description = IntentDescription("Pausa el entrenamiento en curso.")
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        PulsoCommandWriter.write("pause")
        return .result()
    }
}

@available(iOS 17.0, *)
struct PulsoResumeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Reanudar entreno"
    static var description = IntentDescription("Reanuda el entrenamiento pausado.")
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        PulsoCommandWriter.write("resume")
        return .result()
    }
}

@available(iOS 17.0, *)
struct PulsoStopIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Terminar entreno"
    static var description = IntentDescription("Termina y guarda la sesión.")
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        PulsoCommandWriter.write("stop")
        return .result()
    }
}
