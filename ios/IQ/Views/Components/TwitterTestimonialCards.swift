import SwiftUI

// MARK: - Models

struct TestimonialCard: Identifiable {
    let id = UUID()
    var avatar: String? = nil
    var username: String = "User"
    var handle: String = "@user"
    var content: String = "This is amazing!"
    var date: String = "Jan 5, 2026"
    var verified: Bool = true
    var likes: Int = 142
    var retweets: Int = 23
    var tweetUrl: String = "https://x.com"
}

// MARK: - Verified Badge

struct VerifiedBadge: View {
    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .foregroundColor(Color(red: 0.114, green: 0.608, blue: 0.941))
            .font(.system(size: 14))
    }
}

// MARK: - Single Card View

struct TestimonialCardView: View {
    let card: TestimonialCard
    var isActive: Bool = false
    var onTap: (() -> Void)? = nil

    @State private var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack(alignment: .top, spacing: 10) {
                Group {
                    if let avatarUrl = card.avatar, let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.purple.opacity(0.3)
                        }
                    } else {
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(card.username)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        if card.verified {
                            VerifiedBadge()
                        }
                    }
                    Text(card.handle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "bird.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 10)

            // Content
            Text(card.content)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)

            // Footer
            HStack {
                Text(card.date)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.system(size: 14))
                        Text("\(card.likes)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.2.squarepath")
                            .font(.system(size: 14))
                        Text("\(card.retweets)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(isHovered ? 0.15 : 0.08), radius: isHovered ? 16 : 8, x: 0, y: isHovered ? 8 : 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isActive ? Color.accentColor.opacity(0.5) : Color(.separator).opacity(0.4), lineWidth: isActive ? 2 : 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Stacked Testimonials View

struct TestimonialsView: View {
    var cards: [TestimonialCard] = TestimonialsView.defaultCards
    @State private var activeIndex: Int? = nil

    private var isExpanded: Bool { activeIndex != nil }

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(Array(cards.enumerated().reversed()), id: \.offset) { index, card in
                TestimonialCardView(
                    card: card,
                    isActive: activeIndex == index,
                    onTap: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            if isExpanded {
                                activeIndex = nil
                            } else {
                                activeIndex = index
                            }
                        }
                    }
                )
                .offset(y: cardOffset(for: index))
                .zIndex(zIndex(for: index))
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: activeIndex)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: containerHeight)
    }

    private var containerHeight: CGFloat {
        if isExpanded {
            return CGFloat(cards.count) * 160 + 20
        } else {
            return 180
        }
    }

    private func cardOffset(for index: Int) -> CGFloat {
        if isExpanded {
            return CGFloat(index) * 160
        }
        // Stacked: slight peek
        switch index {
        case 0: return 0
        case 1: return 16
        case 2: return 32
        default: return CGFloat(index) * 16
        }
    }

    private func zIndex(for index: Int) -> Double {
        if isExpanded {
            return Double(cards.count - index)
        }
        // In stack: first card on top
        return Double(cards.count - index)
    }

    static let defaultCards: [TestimonialCard] = [
        TestimonialCard(
            avatar: nil,
            username: "Sarah Chen",
            handle: "@sarahchen",
            content: "This component is exactly what I needed for my landing page. The stacked effect is beautiful!",
            date: "Jan 3, 2026",
            verified: true,
            likes: 42,
            retweets: 8,
            tweetUrl: "https://x.com"
        ),
        TestimonialCard(
            avatar: nil,
            username: "Mike Johnson",
            handle: "@mikej_dev",
            content: "The hover interactions are so smooth. Love how the cards spread apart to reveal the ones behind. Great UX thinking!",
            date: "Jan 2, 2026",
            verified: true,
            likes: 28,
            retweets: 5,
            tweetUrl: "https://x.com"
        ),
        TestimonialCard(
            avatar: nil,
            username: "Alex Rivera",
            handle: "@alexrivera",
            content: "Finally a testimonial component that feels native! Dark mode support is chef's kiss",
            date: "Jan 1, 2026",
            verified: true,
            likes: 156,
            retweets: 23,
            tweetUrl: "https://x.com"
        ),
    ]
}
