import Testing
@testable import WallsyncCore

struct EasingTests {
    @Test func endpointsAndLinear() {
        for k in TransitionKind.allCases {
            #expect(k.curve(0) == 0)
            #expect(k.curve(1) == 1)
        }
        let linear = CubicBezier(0, 0, 1, 1)
        for t in stride(from: 0.0, through: 1.0, by: 0.05) {
            #expect(abs(linear(t) - t) < 1e-6)
        }
    }

    @Test func matchesCSSEase() {
        #expect(abs(CubicBezier(0.25, 0.1, 0.25, 1)(0.5) - 0.8024033877399112) < 1e-5)
    }

    @Test func monotonicAndSymmetric() {
        for k in TransitionKind.allCases {
            var last = 0.0
            for t in stride(from: 0.0, through: 1.0, by: 0.01) {
                let v = k.curve(t)
                #expect(v >= last - 1e-9)
                last = v
            }
        }
        let grow = TransitionKind.grow.curve
        #expect(abs(grow(0.5) - 0.5) < 1e-6)
        #expect(abs(grow(0.3) + grow(0.7) - 1) < 1e-6)
        #expect(TransitionKind.wipe.duration == 0.9 && TransitionKind.grow.duration == 1.1)
    }
}
