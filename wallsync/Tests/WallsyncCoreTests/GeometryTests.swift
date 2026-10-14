import CoreGraphics
import Testing
@testable import WallsyncCore

struct GeometryTests {
    let size = CGSize(width: 1470, height: 956)

    @Test func wipeStartsHiddenAndEndsCovering() {
        let start = Geometry.wipe(0, size: size), end = Geometry.wipe(1, size: size)
        #expect(start.count == 4 && end.count == 4)
        #expect(start.allSatisfy { $0.x <= 0 })
        #expect(end[2].x >= size.width && end[3].x >= size.width && end[0].x <= 0)
        // The top edge leads the bottom edge (board A slant).
        #expect(Geometry.wipe(0.5, size: size)[2].x > Geometry.wipe(0.5, size: size)[3].x)
        #expect(abs(Geometry.wipe(0.5, size: size)[3].x - (-0.25 + 0.675) * size.width) < 1e-9)
    }

    @Test func growRadiusReachesFarthestCorner() {
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        #expect(abs(Geometry.growRadius(origin: centre, size: size) - hypot(size.width, size.height) / 2) < 1e-9)
        #expect(abs(Geometry.growRadius(origin: .zero, size: size) - hypot(size.width, size.height)) < 1e-9)
    }

    @Test func twoScreenOriginIsClampedToTheEdge() {
        let builtin = CGRect(x: 0, y: 0, width: 1470, height: 956)
        let external = CGRect(x: 1470, y: -124, width: 1920, height: 1080)
        let origin = CGPoint(x: 700, y: 500)
        #expect(Geometry.localOrigin(origin, screen: builtin) == CGPoint(x: 700, y: 500))
        #expect(Geometry.localOrigin(origin, screen: external) == CGPoint(x: 0, y: 624))
        #expect(Geometry.localOrigin(CGPoint(x: 100, y: 2000), screen: external) == CGPoint(x: 0, y: 1080))
    }

    @Test func fillMaxPixel() {
        let image = CGSize(width: 2940, height: 1912)
        #expect(Geometry.fillMaxPixel(image: image, target: CGSize(width: 2940, height: 1912)) == 2940)
        #expect(Geometry.fillMaxPixel(image: image, target: CGSize(width: 1920, height: 1080)) == 1920)
        #expect(Geometry.fillMaxPixel(image: image, target: CGSize(width: 1080, height: 1920)) == 2940)
        #expect(Geometry.fillMaxPixel(image: image, target: CGSize(width: 5880, height: 3824)) == 2940)
        #expect(Geometry.fillMaxPixel(image: image, target: CGSize(width: 546, height: 600)) == 923)
    }
}
