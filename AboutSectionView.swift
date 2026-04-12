import SwiftUI
import StoreKit

// MARK: - App Info Model

struct LowEffortApp: Identifiable {
    let id = UUID()
    let name: String
    let darkIconName: String
    let lightIconName: String
    let appStoreID: String
    let slug: String?

    init(name: String, darkIconName: String, lightIconName: String? = nil, appStoreID: String, slug: String? = nil) {
        self.name = name
        self.darkIconName = darkIconName
        self.lightIconName = lightIconName ?? darkIconName
        self.appStoreID = appStoreID
        self.slug = slug
    }

    func iconName(for colorScheme: ColorScheme) -> String {
        colorScheme == .dark ? darkIconName : lightIconName
    }

    var appStoreURL: URL? {
        let urlSlug = slug ?? name.lowercased().replacingOccurrences(of: " ", with: "-")
        return URL(string: "https://apps.apple.com/us/app/\(urlSlug)/id\(appStoreID)")
    }
}

// MARK: - App Catalog

enum LowEffortApps {
    static let tasked = LowEffortApp(name: "Task(ed)", darkIconName: "taskeddark", lightIconName: "taskedlight", appStoreID: "6755186421")
    static let aislewise = LowEffortApp(name: "AisleWise", darkIconName: "aislewisedark", lightIconName: "aislewiselight", appStoreID: "6755057084")
    static let muzzletoff = LowEffortApp(name: "Muzzletoff", darkIconName: "muzzletoffdark", lightIconName: "muzzletofflight", appStoreID: "6754781167")
    static let weatherinwords = LowEffortApp(name: "Weather in Words", darkIconName: "weatherinwordsdark", lightIconName: "weatherinwordslight", appStoreID: "6760272161")
    static let all: [LowEffortApp] = [
       tasked, aislewise, muzzletoff, weatherinwords
    ]
}

// MARK: - About Section View

struct AboutSectionView: View {
    /// The bundle identifier prefix to exclude the current app from "Other Apps"
    /// Pass your app's name (e.g., "Task(ed)") to exclude it from the list
    let currentAppName: String?

    /// Optional custom list of apps to display. If nil, shows all apps except current.
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
            // MARK: - We Also Make Section
            Section {
                ForEach(otherApps) { app in
                    OtherAppRow(app: app)
                }
            } header: {
                Text("Our Other Apps")
            }

            // MARK: - Rate & Review
            Section {
                Button {
                    requestReview()
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text("Rate & Review")
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
            } footer: {
                Text("Enjoying the app? A review helps others discover it.")
            }

            // MARK: - About Section
            Section {
                // Version & Build
                HStack {
                    Text("Version")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(appVersion) (\(buildNumber))")
                        .foregroundStyle(.secondary)
                }

                // Company Website
                Link(destination: URL(string: "https://www.loweffortapps.app")!) {
                    HStack {
                        Text("Company Website")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Privacy Policy
                Link(destination: URL(string: "https://www.loweffortapps.app/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Support
                Link(destination: URL(string: "https://www.loweffortapps.app/support/")!) {
                    HStack {
                        Text("Support")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Substack
                Link(destination: URL(string: "https://loweffortgeoff.substack.com/")!) {
                    HStack {
                        Text("Read My Substack")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("About")
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
            AboutSectionView(currentAppName: "Task(ed)")
        }
        .navigationTitle("Settings")
    }
}
