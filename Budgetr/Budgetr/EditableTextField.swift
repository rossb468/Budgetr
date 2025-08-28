import SwiftUI

struct EditableTextField: View {
    @State private var editing = false
    @State private var tempValue: String = ""
    @Binding var text: String

    var body: some View {
        if editing {
            TextField("", text: $tempValue, onEditingChanged: { isEditing in
                if !isEditing {
                    text = tempValue
                    editing = false
                }
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
        } else {
            Text(text)
                .onTapGesture {
                    tempValue = text
                    editing = true
                }
        }
    }
}
