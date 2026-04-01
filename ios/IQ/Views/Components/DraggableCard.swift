import SwiftUI

// MARK: - Draggable Card Body

struct DraggableCardBody<Content: View>: View {
    let content: Content
    var className: String? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var currentDragOffset: CGSize = .zero
    @State private var rotateX: Double = 0
    @State private var rotateY: Double = 0
    @State private var glareOpacity: Double = 0
    @State private var cardOpacity: Double = 1
    @State private var isDragging: Bool = false
    @State private var scale: Double = 1.0

    init(className: String? = nil, @ViewBuilder content: () -> Content) {
        self.className = className
        self.content = content()
    }

    var body: some View {
        ZStack {
            content

            // Glare overlay
            Color.white
                .opacity(glareOpacity)
                .allowsHitTesting(false)
        }
        .frame(width: 320, height: 384)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 24, x: 0, y: 12)
        .opacity(cardOpacity)
        .scaleEffect(scale)
        .rotation3DEffect(
            .degrees(rotateX),
            axis: (x: 1, y: 0, z: 0)
        )
        .rotation3DEffect(
            .degrees(rotateY),
            axis: (x: 0, y: 1, z: 0)
        )
        .offset(dragOffset)
        .gesture(
            DragGesture(coordinateSpace: .global)
                .onChanged { value in
                    isDragging = true
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = CGSize(
                            width: currentDragOffset.width + value.translation.width,
                            height: currentDragOffset.height + value.translation.height
                        )
                        let normalizedX = Double(value.translation.width / 150)
                        let normalizedY = Double(value.translation.height / 150)
                        rotateY = normalizedX * 25
                        rotateX = -normalizedY * 25
                        glareOpacity = abs(normalizedX) * 0.2
                        cardOpacity = 1 - abs(normalizedX) * 0.15
                    }
                }
                .onEnded { value in
                    isDragging = false
                    currentDragOffset = dragOffset

                    let velocityX = value.predictedEndTranslation.width - value.translation.width
                    let velocityY = value.predictedEndTranslation.height - value.translation.height

                    withAnimation(.interpolatingSpring(stiffness: 50, damping: 15, initialVelocity: 5)) {
                        dragOffset = CGSize(
                            width: currentDragOffset.width + velocityX * 0.3,
                            height: currentDragOffset.height + velocityY * 0.3
                        )
                    }
                    currentDragOffset = dragOffset

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        rotateX = 0
                        rotateY = 0
                        glareOpacity = 0
                        cardOpacity = 1
                    }
                }
        )
    }
}

// MARK: - Draggable Card Container

struct DraggableCardContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
