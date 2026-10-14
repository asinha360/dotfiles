import AppKit
import SwiftUI
import WallsyncCore

@Observable
final class PickerModel {
    static let sizes = [CGSize(width: 210, height: 300), CGSize(width: 160, height: 240),
                        CGSize(width: 124, height: 190), CGSize(width: 100, height: 150)]
    static let opacities = [1, 0.95, 0.85, 0.7]
    static let gap: CGFloat = 12
    static let reach = 4

    var paths: [String] = []
    var selected = 0
    var palette = Palette(H: 205, C: 0.2)
    var thumbs: [String: NSImage] = [:]
    /// Carousel frame in the hosting view's coordinates (top-left origin).
    @ObservationIgnored var carousel = CGRect.zero
    @ObservationIgnored var thumbDir = URL(fileURLWithPath: NSTemporaryDirectory())
    @ObservationIgnored var onApply: (String, CGPoint) -> Void = { _, _ in }
    @ObservationIgnored var onClose: () -> Void = {}
    @ObservationIgnored private var loading = Set<String>()

    struct Slot: Identifiable {
        let index: Int, offset: Int, path: String
        var id: String { path }
    }

    var slots: [Slot] {
        guard !paths.isEmpty else { return [] }
        let lo = max(0, selected - Self.reach), hi = min(paths.count - 1, selected + Self.reach)
        return (lo...hi).map { Slot(index: $0, offset: $0 - selected, path: paths[$0]) }
    }

    static func size(_ offset: Int) -> CGSize { sizes[min(abs(offset), 3)] }
    static func opacity(_ offset: Int) -> Double { opacities[min(abs(offset), 3)] }

    /// Horizontal centre of the card at `offset`, relative to the selected card's centre.
    static func x(_ offset: Int) -> CGFloat {
        let n = abs(offset)
        guard n > 0 else { return 0 }
        var x = sizes[0].width / 2
        for k in 1..<n { x += gap + size(k).width }
        x += gap + size(n).width / 2
        return offset < 0 ? -x : x
    }

    func move(_ delta: Int) {
        guard !paths.isEmpty else { return }
        selected = min(max(selected + delta, 0), paths.count - 1)
        loadThumbs()
    }

    /// Applies the card at `index`, growing from its centre, and selects it.
    func choose(_ index: Int) {
        guard paths.indices.contains(index) else { return }
        let centre = CGPoint(x: carousel.midX + Self.x(index - selected), y: carousel.midY)
        onApply(paths[index], centre)
        selected = index
        loadThumbs()
    }

    func loadThumbs() {
        let dir = thumbDir
        for slot in slots where thumbs[slot.path] == nil && !loading.contains(slot.path) {
            let path = slot.path
            loading.insert(path)
            Task {
                let url = await Task.detached(priority: .userInitiated) {
                    ImageDecode.thumbnail(for: URL(fileURLWithPath: path), cacheDir: dir)
                }.value
                loading.remove(path)
                if let url, let image = NSImage(contentsOf: url) { thumbs[path] = image }
            }
        }
    }
}

extension Color {
    init(_ c: RGB8, alpha: Double = 1) {
        self.init(.sRGB, red: Double(c.r) / 255, green: Double(c.g) / 255, blue: Double(c.b) / 255, opacity: alpha)
    }

    init(_ p: Palette, _ name: String) {
        let e = p.entry(name)
        self.init(e.rgb, alpha: e.alpha)
    }
}

/// Horizontal skew about the view's centre, like CSS `skewX`.
nonisolated struct SkewX: GeometryEffect {
    var degrees: Double

    func effectValue(size: CGSize) -> ProjectionTransform {
        let t = tan(degrees * .pi / 180)
        return ProjectionTransform(CGAffineTransform(a: 1, b: 0, c: t, d: 1, tx: -t * size.height / 2, ty: 0))
    }
}

struct PickerView: View {
    let model: PickerModel
    let topInset: CGFloat

    var body: some View {
        let p = model.palette
        ZStack {
            Color.black.opacity(0.28)
                .contentShape(Rectangle())
                .onTapGesture { model.onClose() }
            VStack(spacing: 26) {
                ZStack {
                    ForEach(model.slots) { slot in
                        card(slot, p)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: PickerModel.sizes[0].height)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { model.carousel = $0 }
                .animation(.easeInOut(duration: 0.45), value: model.selected)
                caption(p)
            }
            .padding(.top, topInset)
        }
        .ignoresSafeArea()
    }

    private func card(_ slot: PickerModel.Slot, _ p: Palette) -> some View {
        let size = PickerModel.size(slot.offset)
        return ZStack {
            Color(p, "solid")
            if let image = model.thumbs[slot.path] {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width * 1.3, height: size.height)
                    .modifier(SkewX(degrees: 8))
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .overlay {
            if slot.offset == 0 { Rectangle().strokeBorder(Color(p, "hi"), lineWidth: 2) }
        }
        .modifier(SkewX(degrees: -8))
        .shadow(color: .black.opacity(0.45), radius: 14, y: 8)
        .opacity(PickerModel.opacity(slot.offset))
        // Hit testing must precede .offset, or every card's hit area stays at the carousel centre.
        .contentShape(Rectangle())
        .onTapGesture { model.choose(slot.index) }
        .offset(x: PickerModel.x(slot.offset))
        .zIndex(Double(-abs(slot.offset)))
    }

    private func caption(_ p: Palette) -> some View {
        let name = model.paths.indices.contains(model.selected)
            ? URL(fileURLWithPath: model.paths[model.selected]).deletingPathExtension().lastPathComponent
            : "no wallpapers"
        return HStack(spacing: 10) {
            Text(name).foregroundStyle(Color(p, "hi"))
            Text("·").foregroundStyle(Color(p, "dim"))
            Text("h l move · ↵ apply").foregroundStyle(Color(p, "sub"))
            Text("·").foregroundStyle(Color(p, "dim"))
            Button { model.onClose() } label: {
                Text("esc")
                    .foregroundStyle(Color(p, "fg"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color(p, "line"), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .font(.custom("FiraCode Nerd Font", size: 11))
        .textCase(.uppercase)
        .tracking(0.6)
        .lineLimit(1)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(p, "pill")))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(p, "line"), lineWidth: 1))
    }
}
