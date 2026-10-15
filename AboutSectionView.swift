import StoreKit
import SwiftUI

// MARK: - App Info Model

struct LowEffortApp: Identifiable {
    let id = UUID()
    let name: String
    let darkIconName: String
    let lightIconName: String
    let appStoreID: String

    init(name: String, darkIconName: String, lightIconName: String? = nil, appStoreID: String) {
        self.name = name
        self.darkIconName = darkIconName
        self.lightIconName = lightIconName ?? darkIconName
        self.appStoreID = appStoreID
    }

    func iconName(for colorScheme: ColorScheme) -> String {
        colorScheme == .dark ? darkIconName : lightIconName
    }

    /// The id-only App Store link. A name slug breaks on names like "Task(ed)".
    var appStoreURL: URL? {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)")
    }
}

// MARK: - App Catalog

enum LowEffortApps {
    static let tasked = LowEffortApp(name: "Task(ed)", darkIconName: "taskeddark", lightIconName: "taskedlight", appStoreID: "6755186421")
    static let aislewise = LowEffortApp(name: "AisleWise", darkIconName: "aislewisedark", lightIconName: "aislewiselight", appStoreID: "6755057084")
    static let muzzletoff = LowEffortApp(name: "Muzzletoff", darkIconName: "muzzletoffdark", lightIconName: "muzzletofflight", appStoreID: "6754781167")
    /// Relisted in 2026. The previous id, 6760272161, no longer opens the app.
    /// The icon imageset carries light and dark variants, the same way Offshoots does.
    static let weatherinwords = LowEffortApp(
        name: "Weather in Words",
        darkIconName: "weatherinwords",
        lightIconName: "weatherinwords",
        appStoreID: "6806063498"
    )
    static let all: [LowEffortApp] = [
        tasked, aislewise, muzzletoff, weatherinwords
    ]
}

// MARK: - About Section View

struct AboutSectionView: View {
    /// Pass the current app's name (for example, "Yes? No? Go!") to leave it out of "We Also Make".
    let currentAppName: String?

    /// Optional custom list of apps to display. If nil, shows all apps except the current one.
    let appsToShow: [LowEffortApp]?

    @Environment(\.requestReview) private var requestReview

    init(currentAppName: String? = nil, appsToShow: [LowEffortApp]? = nil) {
        self.currentAppName = currentAppName
        self.appsToShow = appsToShow
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    private var otherApps: [LowEffortApp] {
        if let appsToShow = appsToShow {
            return appsToShow
        }

        guard let currentAppName = currentAppName else {
            return LowEffortApps.all
        }

        return LowEffortApps.all.filter { $0.name != currentAppName }
    }

    var body: some View {
        Group {
            Section {
                ForEach(otherApps) { app in
                    OtherAppRow(app: app)
                }
            } header: {
                Text("We Also Make")
            }
            .listRowBackground(Palette.surface)

            Section {
                Button {
                    requestReview()
                }                 label: {
                    Label("Rate & Review", systemImage: "star")
                }

                LabeledContent("Version", value: "\(appVersion) (\(buildNumber))")

                SettingsLinkRow(title: "Company Website", url: LowEffortLinks.website)
                SettingsLinkRow(title: "Privacy Policy", url: LowEffortLinks.privacy)
                SettingsLinkRow(title: "Support", url: LowEffortLinks.support)
            } header: {
                Text("About")
            } footer: {
                Text("Enjoying the app? A review helps others discover it.")
            }
            .listRowBackground(Palette.surface)
        }
    }
}

// MARK: - Links

private enum LowEffortLinks {
    static let website = URL(string: "https://www.loweffortapps.app")!
    static let privacy = URL(string: "https://www.loweffortapps.app/privacy/")!
    static let support = URL(string: "https://www.loweffortapps.app/support/")!
}

private struct SettingsLinkRow: View {
    let title: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Other App Row

struct OtherAppRow: View {
    let app: LowEffortApp
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: openAppStore) {
            HStack(spacing: 12) {
                Image(app.iconName(for: colorScheme))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(app.name)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func openAppStore() {
        guard let url = app.appStoreURL else { return }

        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        Form {
            AboutSectionView(currentAppName: "Yes? No? Go!")
        }
        .navigationTitle("Settings")
    }
}
