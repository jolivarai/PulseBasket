import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var liveActivityChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "pulso/live_activity",
                binaryMessenger: controller.binaryMessenger
            )

            channel.setMethodCallHandler { call, result in
                guard #available(iOS 16.1, *) else {
                    // iOS antiguo: no hay Live Activities, pero la app funciona.
                    result(nil)
                    return
                }

                let args = call.arguments as? [String: Any] ?? [:]
                switch call.method {
                case "start":
                    LiveActivityBridge.shared.start(
                        title: args["title"] as? String ?? "Entreno",
                        targetMeters: args["targetMeters"] as? Double ?? 0
                    )
                    result(nil)

                case "update":
                    LiveActivityBridge.shared.update(
                        distance: args["distance"] as? String ?? "",
                        pace: args["pace"] as? String ?? "",
                        remaining: args["remaining"] as? String ?? "",
                        progress: args["progress"] as? Double ?? 0,
                        paused: args["paused"] as? Bool ?? false
                    )
                    result(nil)

                case "end":
                    LiveActivityBridge.shared.end(
                        summary: args["summary"] as? String ?? "Sesión finalizada"
                    )
                    result(nil)

                default:
                    result(FlutterMethodNotImplemented)
                }
            }
            liveActivityChannel = channel

            if #available(iOS 16.1, *) {
                // Los App Intents del widget escriben en el App Group; este
                // sondeo los convierte en eventos para Dart.
                LiveActivityBridge.shared.startPolling { [weak channel] command in
                    channel?.invokeMethod("onCommand", arguments: command)
                }
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    /// Fallback iOS 16: los botones del widget abren la app con
    /// `pulso://pause`, `pulso://resume` o `pulso://stop`.
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        if url.scheme == "pulso" {
            let command = url.host ?? ""
            if !command.isEmpty {
                liveActivityChannel?.invokeMethod("onCommand", arguments: command)
            }
            return true
        }
        return super.application(app, open: url, options: options)
    }
}
