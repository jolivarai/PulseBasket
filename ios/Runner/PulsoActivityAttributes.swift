import ActivityKit
import Foundation

/// Contrato de datos entre la app y la Live Activity.
///
/// IMPORTANTE: este archivo pertenece a LOS DOS targets.
///   - Runner      -> lo usa `LiveActivityBridge`
///   - PulsoWidget -> lo usan la vista de bloqueo y la Dynamic Island
///
/// Ya está declarado en ambos `PBXSourcesBuildPhase` del proyecto, así que
/// compila una copia en cada módulo (es el patrón oficial de Apple: el tipo
/// `ActivityAttributes` debe ser idéntico en app y extensión).
@available(iOS 16.1, *)
struct PulsoActivityAttributes: ActivityAttributes {

    /// Parte dinámica: es lo que se refresca cada segundo.
    struct ContentState: Codable, Hashable {
        var distance: String   // "3,4 km"
        var pace: String       // "5'32\"" o "18,4 km/h"
        var remaining: String  // "Faltan 1,6 km"
        var progress: Double   // 0...1
        var paused: Bool
    }

    /// Parte estática: no cambia durante la sesión.
    var title: String          // "Carrera 4 km"
}
