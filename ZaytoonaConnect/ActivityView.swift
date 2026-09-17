import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var model: ZaytoonaModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zBackground.ignoresSafeArea()
                Group {
                    if model.activity.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.zGold)
                            Text("No activity yet").font(.headline)
                            Text("Commands, parking events, and Tahoe actions will appear here.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.zMuted)
                                .padding(.horizontal, 30)
                        }
                    } else {
                        List(model.activity) { item in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.title).font(.headline)
                                Text(item.detail).font(.subheadline).foregroundStyle(.secondary)
                                Text(item.date, style: .relative).font(.caption).foregroundStyle(.secondary)
                            }
                            .listRowBackground(Color.zPanel)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Activity")
        }
    }
}
