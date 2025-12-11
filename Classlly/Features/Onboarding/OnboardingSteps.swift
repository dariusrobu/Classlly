import SwiftUI

// MARK: - Screen 1: The Hook
struct StickyHookView: View {
    var onNext: () -> Void
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // "Chaos vs Order" Visual
            ZStack {
                // Background Chaos (Faded)
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 120))
                    .foregroundColor(.gray.opacity(0.2))
                    .rotationEffect(.degrees(-15))
                    .offset(x: -40, y: -20)
                
                // Foreground Order (Bright)
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.5), radius: 20)
            }
            .padding(.bottom, 40)
            
            Text("Stop guessing.\nStart passing.")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            Text("Set up your entire semester in 30 seconds.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Get Started")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.green)
                    .cornerRadius(28)
                    .scaleEffect(isPulsing ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPulsing)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear { isPulsing = true }
    }
}

// MARK: - Screen 2: The Input (Pain Points)
struct StickyPainPointView: View {
    @Binding var selected: OnboardingPainPoint?
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("What is your main pain?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                ForEach(OnboardingPainPoint.allCases) { point in
                    Button(action: {
                        selected = point
                        // Small delay to show selection before moving
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onNext()
                        }
                    }) {
                        HStack {
                            Image(systemName: point.icon)
                            Text(point.rawValue)
                            Spacer()
                            if selected == point {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .font(.headline)
                        .padding()
                        .frame(height: 64)
                        .background(selected == point ? Color.blue : Color(white: 0.15))
                        .foregroundColor(selected == point ? .white : .gray)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selected == point ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}

// MARK: - Screen 3: The Setup (Magic Trick)
struct StickySetupView: View {
    @Binding var endDate: Date
    @Binding var subjectCount: Double
    var onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("Let's build your base.")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Semester End
            VStack(alignment: .leading, spacing: 12) {
                Text("When does your semester end?")
                    .font(.caption).fontWeight(.bold).foregroundColor(.gray)
                
                DatePicker("", selection: $endDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding()
                    .background(Color(white: 0.15))
                    .cornerRadius(12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            
            // Subject Count
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("How many subjects?")
                        .font(.caption).fontWeight(.bold).foregroundColor(.gray)
                    Spacer()
                    Text("\(Int(subjectCount))")
                        .font(.title3).fontWeight(.bold).foregroundColor(.cyan)
                }
                
                Slider(value: $subjectCount, in: 1...10, step: 1)
                    .tint(.cyan)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: onGenerate) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Generate Study Plan")
                }
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.cyan)
                .cornerRadius(28)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Screen 4: The Payoff (Visual Confirmation)
struct StickyPayoffView: View {
    @Binding var showConfetti: Bool
    @Binding var showPopup: Bool
    var onNext: () -> Void
    
    // Mock data for visual preview
    let mockDays = ["Mon", "Tue", "Wed", "Thu", "Fri"]
    
    var body: some View {
        ZStack {
            // Background Dashboard Preview
            VStack(spacing: 16) {
                // Mock Header
                HStack {
                    Circle().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 40)
                    VStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(width: 100, height: 10)
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(width: 60, height: 10)
                    }
                    Spacer()
                }
                .padding(.top, 60)
                .padding(.horizontal)
                
                // Mock Calendar
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                    ForEach(mockDays, id: \.self) { day in
                        Text(day).font(.caption).foregroundColor(.gray)
                    }
                    ForEach(0..<20) { i in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(i % 3 == 0 ? Color.blue.opacity(0.6) : (i % 2 == 0 ? Color.purple.opacity(0.6) : Color(white: 0.1)))
                            .frame(height: 40)
                    }
                }
                .padding()
                
                Spacer()
            }
            .blur(radius: showPopup ? 3 : 0) // Blur when popup is active
            
            // Continue Button (Only appears after popup is dismissed, handled by main view logic or user tap)
            if !showPopup {
                VStack {
                    Spacer()
                    Button(action: onNext) {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .cornerRadius(28)
                    }
                    .padding(24)
                    .transition(.move(edge: .bottom))
                }
            }
        }
    }
}

// MARK: - Screen 5: The "Hard Ask"
struct StickyNotificationView: View {
    var onFinish: () -> Void
    @State private var showingAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
                .padding()
                .background(
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 150, height: 150)
                )
            
            Text("One last thing...")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("We can't force you to study,\nbut we can annoy you until you do.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    NotificationManager.shared.requestPermission()
                    // Finish after short delay to allow system prompt
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onFinish()
                    }
                }) {
                    Text("Turn on 'Annoy Me' Mode")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.yellow)
                        .cornerRadius(28)
                }
                
                Button("Maybe later") {
                    onFinish()
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// Simple Confetti View
struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50) { i in
                Circle()
                    .fill(Color(
                        hue: Double.random(in: 0...1),
                        saturation: 0.8,
                        brightness: 1
                    ))
                    .frame(width: 8, height: 8)
                    .offset(x: CGFloat.random(in: -200...200), y: animate ? 400 : -400)
                    .animation(
                        .linear(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: false)
                        .delay(Double.random(in: 0...1)),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
        .allowsHitTesting(false)
    }
}
