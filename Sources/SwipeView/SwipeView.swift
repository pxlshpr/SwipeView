import SwiftUI
import SwiftHaptics

extension Notification.Name {
    static var mealDragBegan: Notification.Name { return .init("mealDragBegan") }
}

public struct SwipeView<Content: View>: View {
    
    let mealDragBegan = NotificationCenter.default.publisher(for: .mealDragBegan)
    
    //TODO: Make this an optional parameter
//    @State var spacingBetweenContentAndDeleteButton: CGFloat = 16
    @State var spacingBetweenContentAndDeleteButton: CGFloat

    var content: () -> Content
    
    public init(spacingBetweenContentAndDeleteButton: CGFloat = 0, content: @escaping () -> Content) {
        self.content = content
        _spacingBetweenContentAndDeleteButton = State(initialValue: spacingBetweenContentAndDeleteButton)
    }

    public var body: some View {
        ZStack {
            Group(content: content)
                .offset(x: offset)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !isDragging && offset != 0 {
//                        log.debug("Resetting Offset")
                        resetOffset()
                    }
                }
            deleteButton
                .frame(width: deleteWidth)
                .frame(maxHeight: .infinity)
                .background(Color.red)
                .offset(x: width/2.0 + (deleteWidth/2.0) + spacingBetweenContentAndDeleteButton)
                .offset(x: offset)
        }
        .simultaneousGesture(dragGesture)
        .background(GeometryReader { geometry in
            Color.clear.preference(
                key: WidthPreferenceKey.self,
                value: geometry.size.width
            )
        })
        .onPreferenceChange(WidthPreferenceKey.self) {
            width = $0
        }
        .onReceive(mealDragBegan, perform: mealDragBegan)
    }
    
    var deleteButton: some View {
        ZStack {
            Color.red
            HStack {
                Spacer()
                    .frame(width: deleteLeftSpacerWidth)
                Image(systemName: "trash.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                Spacer()
                    .frame(width: deleteRightSpacerWidth)
            }
        }
        .onTapGesture {
            if !isDragging {
                delete()
            }
        }
    }
    
    var dragGesture: some Gesture {
        DragGesture().updating($gestureOffset, body: { value, out, _ in
            out = value.translation.width
            onDragChanged(value: value)
        }).onEnded { value in
            onDragEnded(value: value)
        }
    }
    
    private func onDragChanged(value: DragGesture.Value) {
        
        DispatchQueue.main.async {
            isDragging = true
            NotificationCenter.default.post(name: .mealDragBegan, object: nil)

            let belowMaximumPoint = -offset <= deleteDragMaximumPoint
            withAnimation(.interactiveSpring()) {
                if !(gestureOffset == 0 && lastOffset == 0) {
                    self.offset = gestureOffset + lastOffset
//                    log.debug("Offset set to \(self.offset) = gestureOffset \(gestureOffset) + lastOffset \(lastOffset)")
                }
            }
            if (belowMaximumPoint && deleteDraggedPastMaximum)
                ||
                (!belowMaximumPoint && !deleteDraggedPastMaximum)
            {
//                log.debug("AT MAXIMUM")
                Haptics.feedback(style: .heavy)
            }
            self.lastDragValue = value
//            log.verbose("Offset: \(offset)")
        }
    }

    private func onDragEnded(value: DragGesture.Value) {
        guard let lastDragPosition = self.lastDragValue else {
            return
        }
        let timeDiff = value.time.timeIntervalSince(lastDragPosition.time)
        let speed = CGFloat(value.translation.width - lastDragPosition.translation.width) / CGFloat(timeDiff)

        DispatchQueue.main.async {
            
            isDragging = false
            Haptics.feedback(style: .soft)
//            log.debug("Ended with speed: \(speed)")
            withAnimation(.interactiveSpring()) {
                if deleteDraggedPastMaximum {
                    delete()
                } else if deleteDraggedPastMinimum || speed < -500 {
                    offset = -100
                } else {
//                    log.debug("Offset was: \(offset), so setting to 0")
                    offset = 0
                }
                lastOffset = offset
            }
        }
    }
    
    func delete() {
        withAnimation(.interactiveSpring()) {
            offset = -width
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                //TODO: actually delete it here
//                log.debug("Delete")
            }
        }
    }
    
    @GestureState var gestureOffset: CGFloat = 0
    @State var offset: CGFloat = 0
    @State var lastOffset: CGFloat = 0
    @State var lastDragValue: DragGesture.Value? = nil

    @State var width: CGFloat = 0
    @State var isDragging: Bool = false

    var deleteWidth: CGFloat {
        if deleteDraggedPastMinimum {
            return -offset
        }
        return 100
    }

    var deleteDraggedPastMinimum: Bool {
        -offset > 100
    }
    var deleteDraggedPastMaximum: Bool {
        -offset > deleteDragMaximumPoint
    }
    var deleteDragMaximumPoint: CGFloat {
        width * 0.75
    }
    var deleteLeftSpacerWidth: CGFloat {
        if deleteDraggedPastMinimum && !deleteDraggedPastMaximum {
            return -offset-100
        }
        return 0
    }

    var deleteRightSpacerWidth: CGFloat {
        if deleteDraggedPastMaximum {
            return -offset-100
        }
        return 0
//        if -offset > 100 {
//            return -offset
//        }
//        return 100
    }
    
    private func mealDragBegan(notification: Notification) {
        if !isDragging && offset != 0 {
            DispatchQueue.main.async {
                resetOffset()
            }
        }
    }
    
    private func resetOffset() {
        withAnimation(.interactiveSpring()) {
            offset = 0
            lastOffset = offset
        }
    }
}

struct WidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat,
                       nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

