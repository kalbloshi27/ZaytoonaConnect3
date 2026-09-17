import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var model: ZaytoonaModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 15) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Trips")
                                    .font(.title2.bold())
                                Text("Tahoe activity and recent actions")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.zMuted)
                            }
                            Spacer()
                        }

                        HStack(spacing: 9) {
                            statCard(
                                icon: "parkingsign.circle.fill",
                                value: model.parkingSession == nil ? "Idle" : "Active",
                                title: "Parking"
                            )
                            statCard(
                                icon: "paperplane.fill",
                                value: "\(model.activity.count)",
                                title: "Events"
                            )
                            statCard(
                                icon: "antenna.radiowaves.left.and.right",
                                value: model.isConnected ? "Online" : "Offline",
                                title: "Tahoe"
                            )
                        }

                        if model.activity.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "map")
                                    .font(.system(size: 31))
                                    .foregroundStyle(Color.zCream)

                                Text("No activity yet")
                                    .font(.headline)

                                Text("Parking sessions and commands will appear here.")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Color.zMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                            .zCard()
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(model.activity.enumerated()), id: \.element.id) { index, item in
                                    HStack(alignment: .top, spacing: 12) {
                                        Circle()
                                            .fill(Color.zCream.opacity(0.10))
                                            .frame(width: 38, height: 38)
                                            .overlay(
                                                Image(systemName: icon(for: item.title))
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(Color.zCream)
                                            )

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(item.title)
                                                .font(.subheadline.weight(.semibold))
                                            Text(item.detail)
                                                .font(.caption)
                                                .foregroundStyle(Color.zMuted)
                                                .lineLimit(2)
                                            Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption2)
                                                .foregroundStyle(Color.zMuted.opacity(0.8))
                                        }

                                        Spacer()
                                    }
                                    .padding(.vertical, 13)

                                    if index < model.activity.count - 1 {
                                        Rectangle()
                                            .fill(Color.zBorder)
                                            .frame(height: 1)
                                            .padding(.leading, 50)
                                    }
                                }
                            }
                            .padding(.horizontal, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.zSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color.zBorder, lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 17)
                    .padding(.top, 16)
                    .padding(.bottom, 25)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func statCard(icon: String, value: String, title: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.zCream)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.zMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(Color.zSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
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
