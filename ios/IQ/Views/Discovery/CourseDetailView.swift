import SwiftUI

// ── Course Detail — structured learning page with lessons ────────────────────

struct CourseDetailView: View {
    let course: ContentItem
    @ObservedObject var manager: ContentManager
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPremiumModal = false
    @State private var appeared = false

    private var prog: Double { manager.courseProgress(for: course.id) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                courseHeader
                courseBody
            }
        }
        .background(Color.white.ignoresSafeArea())
        .overlay(alignment: .topLeading) { backButton }
        .sheet(isPresented: $showPremiumModal) { premiumPreview }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    // ── Header ───────────────────────────────────────────────────────────────

    private var courseHeader: some View {
        ZStack(alignment: .bottomLeading) {
            (course.category.gradient.first ?? IQColors.lavender)
                .frame(height: 220)

            ZStack {
                Circle().fill(Color.white.opacity(0.1)).frame(width: 150, height: 150).offset(x: 120, y: -50)
                Image(systemName: course.icon)
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundColor(course.category.color.opacity(0.2))
                    .offset(x: 100, y: -60)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "book.fill").font(.system(size: 10, weight: .bold))
                    Text("COURSE").font(IQFont.bold(10)).tracking(1)
                }
                .foregroundColor(course.category.color)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.85)))

                Text(course.title)
                    .font(IQFont.bold(22))
                    .foregroundColor(IQColors.textPrimary)

                Text(course.description)
                    .font(IQFont.regular(13))
                    .foregroundColor(IQColors.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock").font(.system(size: 10))
                        Text(course.duration ?? "").font(IQFont.medium(11))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill").font(.system(size: 10))
                        Text("\(course.views) learners").font(IQFont.medium(11))
                    }
                    Text(course.difficulty.label)
                        .font(IQFont.bold(9))
                        .foregroundColor(course.difficulty.color)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(course.difficulty.color.opacity(0.1)))
                }
                .foregroundColor(IQColors.textMuted)
            }
            .padding(20)
        }
        .opacity(appeared ? 1 : 0.6)
    }

    // ── Body ─────────────────────────────────────────────────────────────────

    private var courseBody: some View {
        VStack(alignment: .leading, spacing: 20) {
            if prog > 0 {
                progressBar
            }

            expertSection

            lessonsSection

            Spacer(minLength: 60)
        }
        .padding(20)
    }

    // ── Progress Bar ─────────────────────────────────────────────────────────

    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Your Progress")
                    .font(IQFont.semibold(13))
                    .foregroundColor(IQColors.textPrimary)
                Spacer()
                Text("\(Int(prog * 100))%")
                    .font(IQFont.bold(13))
                    .foregroundColor(IQColors.lavenderDark)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(IQColors.border).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(IQColors.pink)
                        .frame(width: geo.size.width * prog, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    // ── Expert Section ───────────────────────────────────────────────────────

    private var expertSection: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(IQColors.lavender.opacity(0.3)).frame(width: 44, height: 44)
                Text("S").font(IQFont.bold(16)).foregroundColor(IQColors.lavenderDark)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Taught by Dr. Sarah Chen")
                    .font(IQFont.semibold(13)).foregroundColor(IQColors.textPrimary)
                Text("Gastroenterology • 15+ years")
                    .font(IQFont.regular(11)).foregroundColor(IQColors.textMuted)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "F5F4FF")))
    }

    // ── Lessons List ─────────────────────────────────────────────────────────

    private var lessonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lessons")
                .font(IQFont.bold(16))
                .foregroundColor(IQColors.textPrimary)

            ForEach(Array(course.lessons.enumerated()), id: \.element.id) { index, lesson in
                LessonItemView(
                    lesson: lesson,
                    index: index,
                    courseColor: course.category.color
                ) {
                    if lesson.isLocked {
                        showPremiumModal = true
                    } else {
                        manager.updateCourseProgress(course.id, lessonIndex: index, totalLessons: course.lessons.count)
                        manager.trackEvent("lesson_tap", itemId: lesson.id)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
                .animation(.easeOut(duration: 0.35).delay(0.05 * Double(index)), value: appeared)
            }
        }
    }

    // ── Back Button ──────────────────────────────────────────────────────────

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(IQColors.textPrimary)
                .padding(10)
                .background(Circle().fill(Color.white.opacity(0.9)).shadow(color: .black.opacity(0.1), radius: 6, y: 2))
        }
        .padding(.leading, 16).padding(.top, 8)
    }

    // ── Premium Preview Modal ────────────────────────────────────────────────

    private var premiumPreview: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 32))
                .foregroundColor(IQColors.lavenderDark)
                .padding(.top, 32)

            Text("Premium Content")
                .font(IQFont.bold(20))
                .foregroundColor(IQColors.textPrimary)

            Text("This lesson is part of the premium course. Unlock to access all lessons, personalized insights, and expert guidance.")
                .font(IQFont.regular(14))
                .foregroundColor(IQColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                showPremiumModal = false
                // TODO: Navigate to subscription / payment flow
                manager.trackEvent("premium_cta_tap", itemId: course.id)
            } label: {
                Text("Unlock Course")
                    .font(IQFont.bold(15))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(IQColors.pink)
                    )
            }
            .padding(.horizontal, 24)

            Button("Maybe Later") { showPremiumModal = false }
                .font(IQFont.medium(13))
                .foregroundColor(IQColors.textMuted)
                .padding(.bottom, 24)
        }
        .presentationDetents([.medium])
    }
}

// ── LESSON ITEM VIEW ─────────────────────────────────────────────────────────

struct LessonItemView: View {
    let lesson: CourseLesson
    let index: Int
    let courseColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(lesson.isCompleted ? courseColor.opacity(0.12) : IQColors.border.opacity(0.4))
                        .frame(width: 36, height: 36)
                    if lesson.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(courseColor)
                    } else if lesson.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(IQColors.textMuted)
                    } else {
                        Text("\(index + 1)")
                            .font(IQFont.semibold(13))
                            .foregroundColor(IQColors.textPrimary)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(lesson.title)
                        .font(IQFont.semibold(13))
                        .foregroundColor(lesson.isLocked ? IQColors.textMuted : IQColors.textPrimary)
                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Image(systemName: "clock").font(.system(size: 9))
                            Text(lesson.duration).font(IQFont.regular(10))
                        }
                        Image(systemName: lesson.type.icon)
                            .font(.system(size: 9))
                        Text(lesson.type.label)
                            .font(IQFont.regular(10))
                    }
                    .foregroundColor(IQColors.textMuted)
                }

                Spacer()

                if lesson.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(IQColors.textMuted.opacity(0.5))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(IQColors.textMuted)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12).fill(Color.white)
                    .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(lesson.isCompleted ? courseColor.opacity(0.2) : IQColors.border.opacity(0.4), lineWidth: 0.6)
            )
            .opacity(lesson.isLocked ? 0.7 : 1)
        }
        .buttonStyle(ContentPressStyle())
    }
}
