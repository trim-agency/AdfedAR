import Foundation

enum UserInstructions: String {
    case none                   = ""
    case lookingForSymbol       = "align either rune to the guides"
    case lookingForRectangle    = "Now pull back and pan to the left or right"
    case lookingForPlane        = "PUT THE WHOLE BOOK IN THE RECTANGLE"
    case tapForVideo            = "Tap the 3D text to learn more"
}
