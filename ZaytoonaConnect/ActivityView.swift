import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var model: ZaytoonaModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Trips & Activity")
                                    .font(.largeTitle.bold())
                                Text("Parking, commands and Tahoe events")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.zMuted)
                            }
                            Spacer()
                        }

                        HStack(spacing: 10) {
                            statCard(icon: "parkingsign.circle.fill", value: model.parkingSession == nil ? "Idle" : "Active", title: "Parking")
                            statCard(icon: "paperplane.fill", value: "\(model.activity.count)", title: "Events")
                            statCard(icon: "antenna.radiowaves.left.and.right", value: model.isConnected ? "Online" : "Offline", title: "Tahoe")
                        }

                        if model.activity.isEmpty {
                            VStack(spacing: 14) {
                                Image(systemName: "map")
                                    .font(.system(size: 34))
                                    .foregroundStyle(Color.zCream)
                                Text("No trips yet")
                                    .font(.headline)
                                Text("Parking sessions, commands and Tahoe actions will appear here.")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Color.zMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 54)
                            .zCard()
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(model.activity.enumerated()), id: \.element.id) { index, item in
                                    HStack(alignment: .top, spacing: 13) {
                                        Circle()
                                            .fill(Color.zCream.opacity(0.18))
                                            .frame(width: 38, height: 38)
                                            .overlay(
                                                Image(systemName: icon(for: item.title))
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundStyle(Color.zCream)
                                            )

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title)
                                                .font(.subheadline.weight(.semibold))
                                            Text(item.detail)
                                                .font(.caption)
                                                .foregroundStyle(Color.zMuted)
                                            Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption2)
                                                .foregroundStyle(Color.zMuted.opacity(0.8))
                                        }

                                        Spacer()
                                    }
                                    .padding(.vertical, 14)

                                    if index < model.activity.count - 1 {
                                        Rectangle()
                                            .fill(Color.zBorder)
                                            .frame(height: 1)
                                            .padding(.leading, 51)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(Color.zPanel)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .stroke(Color.zBorder, lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func statCard(icon: String, value: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.zCream)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.zMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.zPanel)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.zBorder, lineWidth: 1)
                )
        )
    }

    private func icon(for title: String) -> String {
        let value = title.lowercased()
        if value.contains("parking") { return "parkingsign.circle.fill" }
        if value.contains("command") { return "paperplane.fill" }
        if value.contains("action") { return "car.side.fill" }
        return "sparkles"
    }
}
