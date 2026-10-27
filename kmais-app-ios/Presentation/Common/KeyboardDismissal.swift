import SwiftUI
import UIKit

extension View {
    func dismissesKeyboard() -> some View {
        scrollDismissesKeyboard(.immediately)
            .background(TapOutsideInstaller())
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { KeyboardDismissal.shared.dismiss() }
                }
            }
    }
}

final class KeyboardDismissal: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismissal()
    fileprivate static let recognizerName = "kmais.keyboard-dismissal"

    func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    @objc fileprivate func handleTap(_ recognizer: UITapGestureRecognizer) {
        recognizer.view?.endEditing(true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !sequence(first: touch.view, next: { $0?.superview })
            .contains { $0 is UITextField || $0 is UITextView }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

private struct TapOutsideInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> InstallerView { InstallerView() }
    func updateUIView(_ uiView: InstallerView, context: Context) {}

    final class InstallerView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window,
                  !(window.gestureRecognizers ?? []).contains(where: { $0.name == KeyboardDismissal.recognizerName })
            else { return }

            let tap = UITapGestureRecognizer(
                target: KeyboardDismissal.shared,
                action: #selector(KeyboardDismissal.handleTap(_:))
            )
            tap.name = KeyboardDismissal.recognizerName
            tap.cancelsTouchesInView = false
            tap.delegate = KeyboardDismissal.shared
            window.addGestureRecognizer(tap)
        }
    }
}
