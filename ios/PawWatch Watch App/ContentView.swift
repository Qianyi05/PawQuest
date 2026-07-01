import SwiftUI

struct MainView: View {
    @EnvironmentObject var health: HealthModel

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                   
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Palette.accent)
                            Text(health.realCity)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.muted)
                                .lineLimit(1)
                        }
                        if health.weatherReady {
                            HStack(spacing: 3) {
                                Image(systemName: "thermometer.medium")
                                    .font(.system(size: 10))
                                    .foregroundColor(Palette.primary)
                                Text(health.temperature)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Palette.muted)
                            }
                        }
                    }
                    .padding(.top, 6)

                    
                    ZStack {
                        Circle().stroke(Palette.ring, lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: max(0, min(health.progress, 1)))
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [Palette.accent, Palette.primary]),
                                    center: .center,
                                    startAngle: .degrees(-90), endAngle: .degrees(270)),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 1) {
                            Text("\(health.steps)")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(Palette.text)
                                .minimumScaleFactor(0.5).lineLimit(1)
                            Text("steps today")
                                .font(.system(size: 11))
                                .foregroundColor(Palette.muted)
                        }
                        .padding(.horizontal, 22)
                    }
                    .frame(width: 130, height: 130)

                    Text("Daily goal \(health.dailyGoal)")
                        .font(.system(size: 11))
                        .foregroundColor(Palette.muted)

                    if !health.authorized {
                        Button("Allow Health") { health.start() }
                            .font(.system(size: 13, weight: .semibold))
                            .tint(Palette.primary)
                    } else {
                        Button { health.refresh() } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.system(size: 12))
                        }
                        .tint(Palette.primary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            }
        }
    }
}

struct ContentView: View {
    var body: some View { MainView() }
}

#Preview {
    let h = HealthModel()
    h.steps = 6200
    h.authorized = true
    h.realCity = "Milan"
    h.temperature = "22°C"
    h.weatherReady = true
    return MainView().environmentObject(h)
}
