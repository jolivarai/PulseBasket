import SwiftUI
import WidgetKit

/// Punto de entrada de la extensión.
///
/// El deployment target de este target es iOS 16.1, así que no hace falta
/// comprobar disponibilidad aquí: `PulsoLiveActivity` ya es visible.
@main
struct PulsoWidgetBundle: WidgetBundle {
    var body: some Widget {
        PulsoLiveActivity()
    }
}
