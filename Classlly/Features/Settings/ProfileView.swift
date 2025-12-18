import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Bindable var profile: StudentProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: AppTheme
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack {
                        if let selectedImage {
                            selectedImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else if let data = profile.profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Text("Edit Photo")
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.selectedTheme.primaryColor)
                        }
                        .padding(.top, 8)
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
            
            Section(header: Text("Personal Info")) {
                TextField("Full Name", text: $profile.name)
                    .textContentType(.name)
                
                TextField("Email", text: $profile.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }
            
            Section(header: Text("Academic Info")) {
                TextField("University/School", text: $profile.university)
                TextField("Major", text: $profile.major)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.bold)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        selectedImage = Image(uiImage: uiImage)
                        profile.profileImageData = data
                    }
                }
            }
        }
    }
}
