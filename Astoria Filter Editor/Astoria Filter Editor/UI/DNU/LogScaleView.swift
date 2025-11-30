import SwiftUI
import Foundation

func mapToLogScale(_ input: Double) -> Double {
    let clamped = max(0, min(127, input))
    let minValue = 0.002
    let midValue = 1.0
    let maxValue = 60.0

    if clamped <= 64 {
        let t = clamped / 64.0
        let logMin = log(minValue)
        let logMid = log(midValue)
        return exp(logMin + (logMid - logMin) * t)
    } else {
        let t = (clamped - 64.0) / (127.0 - 64.0)
        let logMid = log(midValue)
        let logMax = log(maxValue)
        return exp(logMid + (logMax - logMid) * t)
    }
}

func mapFromLogScale(_ value: Double) -> Double {
    let minValue = 0.002
    let midValue = 1.0
    let maxValue = 60.0

    if value <= midValue {
        let logMin = log(minValue)
        let logMid = log(midValue)
        let t = (log(value) - logMin) / (logMid - logMin)
        return t * 64.0
    } else {
        let logMid = log(midValue)
        let logMax = log(maxValue)
        let t = (log(value) - logMid) / (logMax - logMid)
        return 64.0 + t * (127.0 - 64.0)
    }
}

struct LogScaleView: View {
    @State private var midiValue: Double = 64

    private var mappedTime: Double {
        mapToLogScale(midiValue)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Logarithmic Scale Mapping")
                .font(.headline)

            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height

//                Path { path in
//                    for i in 0...127 {
//                        let x = Double(i) / 127.0 * width
//                        let yValue = mapToLogScale(Double(i))
//                        
//                        let normalizedY = 1 - (log(yValue) - log(0.002)) / (log(60.0) - log(0.002))
//                        let y = normalizedY * height
//
//                        if i == 0 {
//                            path.move(to: CGPoint(x: x, y: y))
//                        }
//                        else {
//                            path.addLine(to: CGPoint(x: x, y: y))
//                        }
//                    }
//                }
//                .stroke(Color.blue, lineWidth: 2)

                let currentX = midiValue / 127.0 * width
                let currentYValue = mapToLogScale(midiValue)
                let normalizedY = 1 - (log(currentYValue) - log(0.002)) / (log(60.0) - log(0.002))
                let currentY = normalizedY * height

                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .position(x: currentX, y: currentY)
            }
            .frame(height: 200)
            .padding(.horizontal)

            VStack {
                Slider(value: $midiValue, in: 0...127)
                Text(String(format: "Input: %.0f  →  %.3f s", midiValue, mappedTime))
                    .font(.system(.body, design: .monospaced))
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    LogScaleView()
}
