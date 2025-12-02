import SwiftUI
import Combine
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct ContentView: View {
    @StateObject private var game = TetrisGame()
    private let dragThreshold: CGFloat = 24

    var body: some View {
        ZStack {
            ColorPalette.backgroundGradient
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(colors: [Color.white.opacity(0.08), .clear], startPoint: .top, endPoint: .bottom)
                )

            VStack(spacing: 28) {
                header
                mainArea
                controlPad
            }
            .padding(32)
        }
        .onAppear { game.start() }
        .onDisappear { game.stop() }
        .overlay(keyboardCaptureView().allowsHitTesting(false))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Text("俄羅斯方塊")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("得分 \(game.score) · 等級 \(game.level) · 消除 \(game.linesCleared) 行")
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(ColorPalette.subtleText)
            }
            Spacer()
            Button {
                game.restart()
            } label: {
                Label("重新開始", systemImage: "arrow.clockwise")
                    .font(.system(.headline, design: .rounded))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(ColorPalette.accentPurple.gradient)
                    .clipShape(Capsule())
                    .shadow(color: ColorPalette.accentPurple.opacity(0.35), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
        }
    }

    private var mainArea: some View {
        HStack(alignment: .top, spacing: 28) {
            GameBoardView(game: game)
                .overlay(alignment: .center) {
                    if game.isGameOver {
                        VStack(spacing: 10) {
                            Text("遊戲結束")
                                .font(.system(.title2, design: .rounded).bold())
                            Text("按下重新開始繼續挑戰")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(ColorPalette.subtleText)
                        }
                        .padding(28)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: dragThreshold)
                        .onEnded(handleDrag)
                )
                .simultaneousGesture(
                    TapGesture().onEnded { game.rotate() }
                )
                .frame(maxWidth: 360)

            VStack(spacing: 20) {
                NextPiecePreview(type: game.nextPieceType)
                GlassCard(title: "狀態") {
                    FuturisticStatRow(title: "得分", value: "\(game.score)")
                    FuturisticStatRow(title: "等級", value: "\(game.level)")
                    FuturisticStatRow(title: "消除行數", value: "\(game.linesCleared)")
                    FuturisticStatRow(title: "下落間隔", value: game.fallIntervalText)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var controlPad: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ControlButton(
                    title: "左移",
                    systemName: "arrow.left",
                    shortcutSymbol: "←",
                    color: ColorPalette.accentBlue,
                    shortcut: KeyboardShortcut(.leftArrow)
                ) { game.moveLeft() }

                ControlButton(
                    title: "旋轉",
                    systemName: "arrow.triangle.2.circlepath",
                    shortcutSymbol: "SPACE",
                    color: ColorPalette.accentPurple,
                    shortcut: KeyboardShortcut(.space)
                ) { game.rotate() }

                ControlButton(
                    title: "右移",
                    systemName: "arrow.right",
                    shortcutSymbol: "→",
                    color: ColorPalette.accentBlue,
                    shortcut: KeyboardShortcut(.rightArrow)
                ) { game.moveRight() }
            }

            HStack(spacing: 16) {
                ControlButton(
                    title: "軟降",
                    systemName: "arrow.down",
                    shortcutSymbol: "↓",
                    color: ColorPalette.accentCyan,
                    shortcut: KeyboardShortcut(.downArrow)
                ) { game.softDrop() }

                ControlButton(
                    title: "硬降",
                    systemName: "arrow.down.to.line",
                    shortcutSymbol: "⌘↓",
                    color: ColorPalette.accentRed,
                    shortcut: KeyboardShortcut(.downArrow, modifiers: .command)
                ) { game.hardDrop() }
            }
        }
    }

    private func handleDrag(_ value: DragGesture.Value) {
        let horizontal = value.translation.width
        let vertical = value.translation.height
        if abs(horizontal) > abs(vertical) {
            if horizontal > dragThreshold {
                game.moveRight()
            } else if horizontal < -dragThreshold {
                game.moveLeft()
            }
        } else {
            if vertical > dragThreshold {
                game.softDrop()
            } else if vertical < -dragThreshold {
                game.rotate()
            }
        }
    }

    #if os(macOS)
    private func keyboardCaptureView() -> some View {
        KeyboardCaptureView { event in
            handleKeyEvent(event)
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let keyCode = event.keyCode
        let modifiers = event.modifierFlags

        switch keyCode {
        case 123:
            game.moveLeft()
        case 124:
            game.moveRight()
        case 125:
            if modifiers.contains(.command) {
                game.hardDrop()
            } else {
                game.softDrop()
            }
        case 49:
            game.rotate()
        default:
            break
        }
    }
    #else
    private func keyboardCaptureView() -> some View { EmptyView() }
    #endif
}

struct GameBoardView: View {
    @ObservedObject var game: TetrisGame

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 1.5
            let padding: CGFloat = 14
            let shortestSide = min(geometry.size.width, geometry.size.height)
            let cellSize = (shortestSide - padding * 2 - spacing * CGFloat(TetrisGame.columns - 1)) / CGFloat(TetrisGame.columns)
            let boardWidth = cellSize * CGFloat(TetrisGame.columns) + spacing * CGFloat(TetrisGame.columns - 1)
            let boardHeight = cellSize * CGFloat(TetrisGame.rows) + spacing * CGFloat(TetrisGame.rows - 1)
            let snapshot = game.boardSnapshot()

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(ColorPalette.boardSurface)
                    .shadow(color: Color.black.opacity(0.6), radius: 18, x: 0, y: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(ColorPalette.boardBorder, lineWidth: 1.2)
                    )

                VStack(spacing: spacing) {
                    ForEach(0..<TetrisGame.rows, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<TetrisGame.columns, id: \.self) { column in
                                CellView(state: snapshot[row][column])
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
                .padding(padding)
                .frame(width: boardWidth, height: boardHeight)
            }
            .frame(width: boardWidth + padding * 2, height: boardHeight + padding * 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(CGFloat(TetrisGame.columns) / CGFloat(TetrisGame.rows), contentMode: .fit)
    }
}

struct CellView: View {
    let state: TetrisGame.CellState

    var body: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(fillStyle)
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
                    .blendMode(.screen)
            )
            .shadow(color: borderColor.opacity(0.25), radius: state.isFilled ? 6 : 0)
    }

    private var fillStyle: LinearGradient {
        switch state {
        case .empty:
            return gradient(for: ColorPalette.boardCellEmpty, intensity: 0.8)
        case .ghost(let type):
            return gradient(for: type.color, intensity: 0.35)
        case .active(let type), .locked(let type):
            return gradient(for: type.color, intensity: 1.0)
        }
    }

    private var borderColor: Color {
        switch state {
        case .empty:
            return ColorPalette.boardBorder.opacity(0.3)
        case .ghost(let type):
            return type.color.opacity(0.4)
        case .active(let type), .locked(let type):
            return type.color.opacity(0.9)
        }
    }

    private func gradient(for color: Color, intensity: Double) -> LinearGradient {
        let primary = color.opacity(intensity)
        let secondary = color.opacity(intensity * 0.7)
        return LinearGradient(colors: [primary, secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private extension TetrisGame.CellState {
    var isFilled: Bool {
        switch self {
        case .active, .locked:
            return true
        default:
            return false
        }
    }
}

struct ControlButton: View {
    let title: String
    let systemName: String
    let shortcutSymbol: String?
    let color: Color
    let shortcut: KeyboardShortcut?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.system(.headline, design: .rounded))
                if let symbol = shortcutSymbol {
                    Text(symbol)
                        .font(.system(.caption, design: .rounded).monospaced())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: [color.opacity(0.95), color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.35), radius: 16, y: 12)
        }
        .buttonStyle(.plain)
        .optionalShortcut(shortcut)
    }
}

struct NextPiecePreview: View {
    let type: TetrominoType

    private var normalizedPoints: [GridPoint] {
        let base = type.rotations.first ?? []
        let minX = base.map(\.x).min() ?? 0
        let minY = base.map(\.y).min() ?? 0
        return base.map { GridPoint(x: $0.x - minX, y: $0.y - minY) }
    }

    var body: some View {
        GlassCard(title: "下個方塊") {
            VStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<4, id: \.self) { column in
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(cellColor(row: row, column: column))
                                .frame(width: 32, height: 32)
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private func cellColor(row: Int, column: Int) -> LinearGradient {
        if normalizedPoints.contains(where: { $0.x == column && $0.y == row }) {
            let base = type.color
            return LinearGradient(colors: [base.opacity(0.95), base.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        return LinearGradient(colors: [ColorPalette.mediumSurface.opacity(0.5), ColorPalette.mediumSurface.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct GlassCard<Content: View>: View {
    var title: String?
    private let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
            }
            content
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(ColorPalette.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 20, y: 14)
        )
    }
}

struct FuturisticStatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(ColorPalette.subtleText)
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
        }
    }
}

private struct OptionalShortcutModifier: ViewModifier {
    let shortcut: KeyboardShortcut?

    func body(content: Content) -> some View {
        if let shortcut {
            content.keyboardShortcut(shortcut)
        } else {
            content
        }
    }
}

private extension View {
    func optionalShortcut(_ shortcut: KeyboardShortcut?) -> some View {
        modifier(OptionalShortcutModifier(shortcut: shortcut))
    }
}

#if os(macOS)
private struct KeyboardCaptureView: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Void

    func makeNSView(context: Context) -> KeyCaptureNSView {
        let view = KeyCaptureNSView()
        view.onKeyDown = onKeyDown
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureNSView, context: Context) {
        nsView.onKeyDown = onKeyDown
        if nsView.window?.firstResponder !== nsView {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
}

private final class KeyCaptureNSView: NSView {
    var onKeyDown: (NSEvent) -> Void = { _ in }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        onKeyDown(event)
    }
}
#endif

final class TetrisGame: ObservableObject {
    static let columns = 10
    static let rows = 20

    @Published private(set) var board: [[TetrominoType?]] =
        Array(repeating: Array(repeating: nil, count: columns), count: rows)
    @Published private(set) var currentPiece: Tetromino?
    @Published private(set) var currentOrigin: GridPoint = GridPoint(x: 3, y: 0)
    @Published private(set) var nextPieceType: TetrominoType = TetrominoType.random()
    @Published private(set) var score = 0
    @Published private(set) var linesCleared = 0
    @Published private(set) var level = 1
    @Published private(set) var isGameOver = false

    private var timer: Timer?

    var hasActivePiece: Bool {
        currentPiece != nil && !isGameOver
    }

    var fallIntervalText: String {
        String(format: "%.2fs", fallInterval)
    }

    func start() {
        if currentPiece == nil || isGameOver {
            restart()
        } else {
            scheduleTimer()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func restart() {
        stop()
        board = Array(repeating: Array(repeating: nil, count: Self.columns), count: Self.rows)
        score = 0
        linesCleared = 0
        level = 1
        isGameOver = false
        currentPiece = nil
        nextPieceType = TetrominoType.random()
        spawnNextPiece()
        if !isGameOver {
            scheduleTimer()
        }
    }

    func moveLeft() {
        guard !isGameOver else { return }
        if move(by: GridPoint(x: -1, y: 0)) {
            SoundManager.shared.play(.move)
        }
    }

    func moveRight() {
        guard !isGameOver else { return }
        if move(by: GridPoint(x: 1, y: 0)) {
            SoundManager.shared.play(.move)
        }
    }

    func softDrop() {
        guard !isGameOver else { return }
        if move(by: GridPoint(x: 0, y: 1)) {
            score += 1
            SoundManager.shared.play(.softDrop)
        } else {
            lockCurrentPiece()
        }
    }

    func hardDrop() {
        guard !isGameOver else { return }
        var distance = 0
        while move(by: GridPoint(x: 0, y: 1)) {
            distance += 1
        }
        if distance > 0 {
            score += distance * 2
            SoundManager.shared.play(.hardDrop)
        }
        lockCurrentPiece()
    }

    func rotate() {
        guard let piece = currentPiece, !isGameOver else { return }
        let rotated = piece.rotated()
        let kicks = [
            GridPoint(x: 0, y: 0),
            GridPoint(x: 1, y: 0),
            GridPoint(x: -1, y: 0),
            GridPoint(x: 2, y: 0),
            GridPoint(x: -2, y: 0),
            GridPoint(x: 0, y: -1)
        ]

        var rotatedSuccessfully = false
        for kick in kicks {
            let newOrigin = currentOrigin.offset(by: kick)
            if canPlace(tetromino: rotated, at: newOrigin) {
                currentPiece = rotated
                currentOrigin = newOrigin
                rotatedSuccessfully = true
                break
            }
        }
        if rotatedSuccessfully {
            SoundManager.shared.play(.rotate)
        }
    }

    func boardSnapshot() -> [[CellState]] {
        var snapshot = Array(
            repeating: Array(repeating: CellState.empty, count: Self.columns),
            count: Self.rows
        )

        for row in 0..<Self.rows {
            for column in 0..<Self.columns {
                if let locked = board[row][column] {
                    snapshot[row][column] = .locked(locked)
                }
            }
        }

        guard let piece = currentPiece else { return snapshot }

        for point in ghostCells(for: piece, origin: currentOrigin) where isInsideBoard(point) {
            if snapshot[point.y][point.x].isEmpty {
                snapshot[point.y][point.x] = .ghost(piece.type)
            }
        }

        for point in activeCells(for: piece, origin: currentOrigin) where isInsideBoard(point) {
            snapshot[point.y][point.x] = .active(piece.type)
        }

        return snapshot
    }

    private var fallInterval: TimeInterval {
        max(0.12, 0.9 - Double(level - 1) * 0.06)
    }

    private func tick() {
        guard !isGameOver else { return }
        if !move(by: GridPoint(x: 0, y: 1)) {
            lockCurrentPiece()
        }
    }

    private func move(by offset: GridPoint) -> Bool {
        guard let piece = currentPiece else { return false }
        let newOrigin = currentOrigin.offset(by: offset)
        if canPlace(tetromino: piece, at: newOrigin) {
            currentOrigin = newOrigin
            return true
        }
        return false
    }

    private func scheduleTimer() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: fallInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func spawnNextPiece() {
        let newPiece = Tetromino(type: nextPieceType)
        currentPiece = newPiece
        currentOrigin = GridPoint(x: (Self.columns / 2) - 2, y: 0)
        nextPieceType = TetrominoType.random()
        if let piece = currentPiece, !canPlace(tetromino: piece, at: currentOrigin) {
            isGameOver = true
            stop()
        }
        SoundManager.shared.play(.spawn)
    }

    private func lockCurrentPiece() {
        guard let piece = currentPiece else { return }
        var reachedTop = false
        for point in activeCells(for: piece, origin: currentOrigin) {
            if point.y < 0 {
                reachedTop = true
                continue
            }
            if isInsideBoard(point) {
                board[point.y][point.x] = piece.type
            }
        }
        if reachedTop {
            isGameOver = true
            stop()
            SoundManager.shared.play(.gameOver)
            return
        }
        SoundManager.shared.play(.lock)
        clearCompletedLines()
        spawnNextPiece()
    }

    private func clearCompletedLines() {
        var newBoard: [[TetrominoType?]] = []
        var cleared = 0
        for row in board {
            if row.allSatisfy({ $0 != nil }) {
                cleared += 1
            } else {
                newBoard.append(row)
            }
        }
        while newBoard.count < Self.rows {
            newBoard.insert(Array(repeating: nil, count: Self.columns), at: 0)
        }
        board = newBoard
        guard cleared > 0 else { return }

        linesCleared += cleared
        score += scoreForLines(cleared)
        SoundManager.shared.play(.lineClear)
        let newLevel = max(1, linesCleared / 10 + 1)
        if newLevel != level {
            level = newLevel
            scheduleTimer()
        }
    }

    private func scoreForLines(_ count: Int) -> Int {
        switch count {
        case 1: return 100 * level
        case 2: return 300 * level
        case 3: return 500 * level
        case 4: return 800 * level
        default: return 0
        }
    }

    private func canPlace(tetromino: Tetromino, at origin: GridPoint) -> Bool {
        for point in activeCells(for: tetromino, origin: origin) {
            if point.x < 0 || point.x >= Self.columns { return false }
            if point.y >= Self.rows { return false }
            if point.y >= 0 && board[point.y][point.x] != nil { return false }
        }
        return true
    }

    private func activeCells(for piece: Tetromino, origin: GridPoint) -> [GridPoint] {
        piece.blocks.map { block in
            GridPoint(x: block.x + origin.x, y: block.y + origin.y)
        }
    }

    private func ghostCells(for piece: Tetromino, origin: GridPoint) -> [GridPoint] {
        var dropOrigin = origin
        while canPlace(tetromino: piece, at: dropOrigin.offset(dy: 1)) {
            dropOrigin = dropOrigin.offset(dy: 1)
        }
        return activeCells(for: piece, origin: dropOrigin)
    }

    private func isInsideBoard(_ point: GridPoint) -> Bool {
        point.y >= 0 && point.y < Self.rows && point.x >= 0 && point.x < Self.columns
    }

    deinit {
        stop()
    }
}

extension TetrisGame {
    enum CellState: Equatable {
        case empty
        case locked(TetrominoType)
        case active(TetrominoType)
        case ghost(TetrominoType)

        var isEmpty: Bool {
            if case .empty = self { return true }
            return false
        }
    }
}

struct GridPoint: Hashable {
    var x: Int
    var y: Int

    func offset(dx: Int = 0, dy: Int = 0) -> GridPoint {
        GridPoint(x: x + dx, y: y + dy)
    }

    func offset(by point: GridPoint) -> GridPoint {
        offset(dx: point.x, dy: point.y)
    }
}

struct Tetromino {
    let type: TetrominoType
    var rotationIndex: Int = 0

    var blocks: [GridPoint] {
        let rotations = type.rotations
        guard !rotations.isEmpty else { return [] }
        return rotations[rotationIndex % rotations.count]
    }

    func rotated() -> Tetromino {
        var copy = self
        copy.rotationIndex = (rotationIndex + 1) % type.rotations.count
        return copy
    }
}

enum TetrominoType: CaseIterable {
    case i, o, t, s, z, j, l

    var color: Color {
        switch self {
        case .i: return Color(red: 0.30, green: 0.85, blue: 1.0)
        case .o: return Color(red: 0.99, green: 0.89, blue: 0.28)
        case .t: return Color(red: 0.69, green: 0.48, blue: 1.0)
        case .s: return Color(red: 0.33, green: 0.89, blue: 0.53)
        case .z: return Color(red: 0.98, green: 0.45, blue: 0.54)
        case .j: return Color(red: 0.33, green: 0.65, blue: 1.0)
        case .l: return Color(red: 1.00, green: 0.61, blue: 0.36)
        }
    }

    var rotations: [[GridPoint]] {
        switch self {
        case .i:
            return [
                [GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 3, y: 1)],
                [GridPoint(x: 2, y: 0), GridPoint(x: 2, y: 1), GridPoint(x: 2, y: 2), GridPoint(x: 2, y: 3)]
            ]
        case .o:
            return [
                [GridPoint(x: 1, y: 0), GridPoint(x: 2, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1)]
            ]
        case .t:
            return [
                [GridPoint(x: 1, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1)],
                [GridPoint(x: 1, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 1, y: 2)],
                [GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 1, y: 2)],
                [GridPoint(x: 1, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 1, y: 2)]
            ]
        case .s:
            return [
                [GridPoint(x: 1, y: 0), GridPoint(x: 2, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1)],
                [GridPoint(x: 1, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 2, y: 2)]
            ]
        case .z:
            return [
                [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1)],
                [GridPoint(x: 2, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 1, y: 2)]
            ]
        case .j:
            return [
                [GridPoint(x: 0, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1)],
                [GridPoint(x: 1, y: 0), GridPoint(x: 2, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 1, y: 2)],
                [GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 2, y: 2)],
                [GridPoint(x: 1, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 0, y: 2), GridPoint(x: 1, y: 2)]
            ]
        case .l:
            return [
                [GridPoint(x: 2, y: 0), GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1)],
                [GridPoint(x: 1, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 1, y: 2), GridPoint(x: 2, y: 2)],
                [GridPoint(x: 0, y: 1), GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1), GridPoint(x: 0, y: 2)],
                [GridPoint(x: 0, y: 0), GridPoint(x: 1, y: 0), GridPoint(x: 1, y: 1), GridPoint(x: 1, y: 2)]
            ]
        }
    }

    static func random() -> TetrominoType {
        allCases.randomElement() ?? .i
    }
}

private enum ColorPalette {
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.05, green: 0.05, blue: 0.08), Color(red: 0.10, green: 0.11, blue: 0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let subtleText = Color.white.opacity(0.65)
    static let mediumSurface = Color(red: 0.18, green: 0.19, blue: 0.24)
    static let boardSurface = Color(red: 0.08, green: 0.09, blue: 0.14)
    static let boardCellEmpty = Color(red: 0.12, green: 0.13, blue: 0.19)
    static let boardBorder = Color(red: 0.28, green: 0.30, blue: 0.37)
    static let cardBackground = Color(red: 0.12, green: 0.13, blue: 0.2).opacity(0.9)

    static let accentBlue = Color(red: 0.17, green: 0.48, blue: 0.99)
    static let accentPurple = Color(red: 0.63, green: 0.36, blue: 0.94)
    static let accentCyan = Color(red: 0.13, green: 0.72, blue: 0.89)
    static let accentRed = Color(red: 0.94, green: 0.32, blue: 0.43)
    static var accentGreen: Color { Color(red: 0.35, green: 0.84, blue: 0.51) }
}

final class SoundManager {
    static let shared = SoundManager()

    enum Effect: CaseIterable {
        case move
        case softDrop
        case rotate
        case hardDrop
        case lineClear
        case spawn
        case lock
        case gameOver

        fileprivate var parameters: (frequency: Double, duration: Double, amplitude: Double) {
            switch self {
            case .move: return (frequency: 680, duration: 0.07, amplitude: 0.25)
            case .softDrop: return (frequency: 520, duration: 0.08, amplitude: 0.3)
            case .rotate: return (frequency: 890, duration: 0.09, amplitude: 0.3)
            case .hardDrop: return (frequency: 360, duration: 0.15, amplitude: 0.4)
            case .lineClear: return (frequency: 780, duration: 0.2, amplitude: 0.35)
            case .spawn: return (frequency: 600, duration: 0.07, amplitude: 0.22)
            case .lock: return (frequency: 440, duration: 0.12, amplitude: 0.28)
            case .gameOver: return (frequency: 250, duration: 0.35, amplitude: 0.4)
            }
        }
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let queue = DispatchQueue(label: "SoundManagerQueue")
    private let bufferFormat: AVAudioFormat
    private var buffers: [Effect: AVAudioPCMBuffer] = [:]

    private init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        self.bufferFormat = format

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
        } catch {
            print("[SoundManager] Engine start failed: \(error)")
        }
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            print("[SoundManager] Audio session error: \(error)")
        }
        #endif

        preloadBuffers()
    }

    func play(_ effect: Effect) {
        guard let buffer = buffers[effect] else { return }
        queue.async { [weak self] in
            guard let self else { return }
            self.player.scheduleBuffer(buffer, at: nil, options: []) {
                // no-op
            }
            if !self.player.isPlaying {
                self.player.play()
            }
        }
    }

    private func preloadBuffers() {
        Effect.allCases.forEach { effect in
            buffers[effect] = makeBuffer(for: effect)
        }
    }

    private func makeBuffer(for effect: Effect) -> AVAudioPCMBuffer? {
        let params = effect.parameters
        let sampleRate = bufferFormat.sampleRate
        let duration = params.duration
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: bufferFormat, frameCapacity: frameCount) else { return nil }

        buffer.frameLength = frameCount
        let thetaIncrement = 2.0 * Double.pi * params.frequency / sampleRate
        guard let channels = buffer.floatChannelData else { return nil }

        for sampleIndex in 0..<Int(frameCount) {
            let envelope = sin(Double(sampleIndex) / Double(frameCount) * Double.pi)
            let value = sin(thetaIncrement * Double(sampleIndex)) * params.amplitude * envelope
            let floatValue = Float(value)
            channels[0][sampleIndex] = floatValue
            channels[1][sampleIndex] = floatValue
        }
        return buffer
    }
}
