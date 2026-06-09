import PhotosUI
import SwiftUI

struct LeafImagePicker: View {
    @Binding var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
            Label("Import Leaf Image", systemImage: "photo.badge.plus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}

