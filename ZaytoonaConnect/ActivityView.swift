import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var model: ZaytoonaModel
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Activity").font(.system(size: 32, weight: .bold))
                Text("Zaytoona connection and parking history").font(.subheadline).foregroundStyle(.secondary)

                if model.activities.isEmpty {
                    GlassPanel {
                        VStack(spacing: 10) {
                            Image(systemName: "sparkles").font(.system(size: 28)).foregroundStyle(.zGold)
                            Text("No activity yet").font(.headline)
                            Text("Connections and saved parking events will appear here.").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }.frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(model.activities) { item in
                            HStack(spacing: 13) {
                                Image(systemName: item.symbol).foregroundStyle(.zGold).frame(width: 34, height: 34).background(Color.zGold.opacity(0.10), in: Circle())
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title).font(.headline)
                                    Text(item.detail).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(item.date.formatted(date: .omitted, time: .shortened)).font(.caption2).foregroundStyle(.secondary)
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 19))
                            .overlay(RoundedRectangle(cornerRadius: 19).stroke(Color.white.opacity(0.07)))
                        }
                    }
                }
            }
            .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 18)
        }
    }
}
