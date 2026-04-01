import SwiftUI

// MARK: - Letter Patterns

private let letterPatterns: [Character: [Int]] = [
    "A": [1,2,3,50,100,150,200,250,300,54,104,154,204,254,304,151,152,153],
    "B": [0,1,2,3,4,50,100,150,151,200,250,300,301,302,303,304,54,104,152,153,204,254,303],
    "C": [0,1,2,3,4,50,100,150,200,250,300,301,302,303,304],
    "D": [0,1,2,3,50,100,150,200,250,300,301,302,54,104,154,204,254,303],
    "E": [0,1,2,3,4,50,100,150,200,250,300,301,302,303,304,151,152],
    "F": [0,1,2,3,4,50,100,150,200,250,300,151,152,153],
    "G": [0,1,2,3,4,50,100,150,200,250,300,301,302,303,153,204,154,304,254],
    "H": [0,50,100,150,200,250,300,151,152,153,4,54,104,154,204,254,304],
    "I": [0,1,2,3,4,52,102,152,202,252,300,301,302,303,304],
    "J": [0,1,2,3,4,52,102,152,202,250,252,302,300,301],
    "K": [0,4,50,100,150,200,250,300,151,152,103,54,203,254,304],
    "L": [0,50,100,150,200,250,300,301,302,303,304],
    "M": [0,50,100,150,200,250,300,51,102,53,4,54,104,154,204,254,304],
    "N": [0,50,100,150,200,250,300,51,102,153,204,4,54,104,154,204,254,304],
    "O": [1,2,3,50,100,150,200,250,301,302,303,54,104,154,204,254],
    "P": [0,50,100,150,200,250,300,1,2,3,54,104,151,152,153],
    "Q": [1,2,3,50,100,150,200,250,301,302,54,104,154,204,202,253,304],
    "R": [0,50,100,150,200,250,300,1,2,3,54,104,151,152,153,204,254,304],
    "S": [1,2,3,4,50,100,151,152,153,204,254,300,301,302,303],
    "T": [0,1,2,3,4,52,102,152,202,252,302],
    "U": [0,50,100,150,200,250,301,302,303,4,54,104,154,204,254],
    "V": [0,50,100,150,200,251,302,4,54,104,154,204,253],
    "W": [0,50,100,150,200,250,301,152,202,252,4,54,104,154,204,254,303],
    "X": [0,50,203,254,304,4,54,152,101,103,201,250,300],
    "Y": [0,50,101,152,202,252,302,4,54,103],
    "Z": [0,1,2,3,4,54,103,152,201,250,300,301,302,303,304],
    "0": [1,2,3,50,100,150,200,250,301,302,303,54,104,154,204,254],
    "1": [1,52,102,152,202,252,302,0,2,300,301,302,303,304],
    "2": [0,1,2,3,54,104,152,153,201,250,300,301,302,303,304],
    "3": [0,1,2,3,54,104,152,153,204,254,300,301,302,303],
    "4": [0,50,100,150,4,54,104,151,152,153,154,204,254,304],
    "5": [0,1,2,3,4,50,100,151,152,153,204,254,300,301,302,303],
    "6": [1,2,3,50,100,150,151,152,153,200,250,301,302,204,254,303],
    "7": [0,1,2,3,4,54,103,152,201,250,300],
    "8": [1,2,3,50,100,151,152,153,200,250,301,302,303,54,104,204,254],
    "9": [1,2,3,50,100,151,152,153,154,204,254,304,54,104],
    " ": [],
]

// MARK: - Commits Grid View

struct CommitsGrid: View {
    let text: String

    private let commitColors: [Color] = [
        Color(red: 0.282, green: 0.835, blue: 0.365),
        Color(red: 0.004, green: 0.427, blue: 0.196),
        Color(red: 0.051, green: 0.267, blue: 0.161),
    ]

    private func cleanString(_ str: String) -> String {
        let upper = str.uppercased()
        let normalized = upper.folding(options: .diacriticInsensitive, locale: .current)
        return normalized.filter { letterPatterns[$0] != nil }
    }

    private func generateGrid() -> (cells: Set<Int>, width: Int, height: Int) {
        let cleaned = cleanString(text)
        let width = max(cleaned.count * 6, 6) + 1
        let height = 9
        var highlighted = Set<Int>()
        var currentPosition = 1

        for char in cleaned {
            if let pattern = letterPatterns[char] {
                for pos in pattern {
                    let row = pos / 50
                    let col = pos % 50
                    let cellIndex = (row + 1) * width + col + currentPosition
                    highlighted.insert(cellIndex)
                }
            }
            currentPosition += 6
        }

        return (highlighted, width, height)
    }

    var body: some View {
        let (highlightedCells, gridWidth, gridHeight) = generateGrid()
        let totalCells = gridWidth * gridHeight

        let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: gridWidth)

        LazyVGrid(columns: columns, spacing: 3) {
            ForEach(0..<totalCells, id: \.self) { index in
                let isHighlighted = highlightedCells.contains(index)
                let shouldFlash = !isHighlighted && (Int.random(in: 0...2) == 0)
                let randomColor = commitColors.randomElement() ?? commitColors[0]
                let randomDelay = Double.random(in: 0...0.6)

                CommitCell(
                    isHighlighted: isHighlighted,
                    shouldFlash: shouldFlash,
                    color: randomColor,
                    delay: randomDelay
                )
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Commit Cell

struct CommitCell: View {
    let isHighlighted: Bool
    let shouldFlash: Bool
    let color: Color
    let delay: Double

    @State private var animatedColor: Color = Color(.systemBackground)

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(animatedColor)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color(.separator).opacity(0.25), lineWidth: 0.5)
            )
            .onAppear {
                if isHighlighted {
                    withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                        animatedColor = color
                    }
                } else if shouldFlash {
                    withAnimation(.easeInOut(duration: 0.3).delay(delay)) {
                        animatedColor = color
                    }
                    withAnimation(.easeInOut(duration: 0.3).delay(delay + 0.3)) {
                        animatedColor = Color(.systemBackground)
                    }
                } else {
                    animatedColor = Color(.systemBackground)
                }
            }
    }
}
