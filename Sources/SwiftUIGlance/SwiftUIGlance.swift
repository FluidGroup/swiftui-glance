import SwiftUI
import SwiftUISnapDraggingModifier
import SwiftUISupport

struct BookGlanceDisplay: View, PreviewProvider {
  var body: some View {
    RootContent()
  }

  static var previews: some View {
    Self()
  }

  private struct RootContent: View {

    @State var count: Int = 0
    @State var topViews: [ContentWrapper<BarStyleView>] = []
    @State var middleViews: [ContentWrapper<PopView>] = []
    @State var bottomViews: [ContentWrapper<BarStyleView>] = []

    var body: some View {
      ZStack {

        HStack {
          Spacer()
          VStack {
            Button("Top") {
              count += 1
              topViews.append(.init { BarStyleView(label: count.description) })
            }
            Button("Middle") {
              count += 1
              middleViews.append(.init { PopView(label: count.description) })
            }
            Button("Bottom") {
              count += 1
              bottomViews.append(.init { BarStyleView(label: count.description) })
            }
          }
        }

        BookGlanceDisplay.DisplayView(
          topViews: $topViews,
          middleViews: $middleViews,
          bottomViews: $bottomViews
        )
      }
    }

  }

  struct DisplayView<
    TopView: View,
    MiddleView: View,
    BottomView: View
  >: View {

    @Binding var topViews: [ContentWrapper<TopView>]
    @Binding var middleViews: [ContentWrapper<MiddleView>]
    @Binding var bottomViews: [ContentWrapper<BottomView>]

    var body: some View {
      ZStack {

        BookGlanceDisplay.TopDisplayView(items: $topViews)

        BookGlanceDisplay.MiddleDisplayView(items: $middleViews)

        BookGlanceDisplay.BottomDisplayView(items: $bottomViews)

      }

    }
  }

  struct Indexed<T: Equatable>: Equatable {
    let index: Int
    let value: T
  }

  struct TopDisplayView<DisplayView: View>: View {

    @Binding var items: [ContentWrapper<DisplayView>]

    @State var displayItems: [Indexed<ContentWrapper<DisplayView>>] = []

    var body: some View {
      // Top
      VStack {

        ForEach.init(displayItems, id: \.value.id) { (item) in
          item.value
            .zIndex(-CGFloat(item.index))
            .environment(
              \.glanceContext,
               .init(onDismiss: {
                 items.removeAll { $0 == item.value }
               })
            )
        }

        Spacer(minLength: 0)
      }
      // animation for condencing views
      .animation(.spring(), value: displayItems)
      .onChange(of: items) { views in

        displayItems = views.prefix(3).enumerated().map {
          .init(index: $0.offset, value: $0.element)
        }

      }

    }
  }

  struct MiddleDisplayView<DisplayView: View>: View {

    @Binding var items: [ContentWrapper<DisplayView>]

    @State var displayItem: ContentWrapper<DisplayView>?

    var body: some View {

      ZStack {

        if let displayItem {
          displayItem
            .environment(
              \.glanceContext,
               .init(onDismiss: {

                 Task {
                   self.displayItem = nil
                   try? await Task.sleep(nanoseconds: 500_000_000)
                   items.removeAll { $0 == displayItem }
                 }

               })
            )
        }

      }
      .onChange(of: items) { views in

        displayItem = views.prefix(1).first

      }
    }
  }

  struct BottomDisplayView<DisplayView: View>: View {

    @Binding var items: [ContentWrapper<DisplayView>]

    @State var displayItems: [Indexed<ContentWrapper<DisplayView>>] = []

    var body: some View {
      // Top
      VStack {

        Spacer(minLength: 0)

        ForEach.init(displayItems, id: \.value.id) { (item) in
          item.value
            .zIndex(-CGFloat(item.index))
            .environment(
              \.glanceContext,
               .init(onDismiss: {
                 items.removeAll { $0 == item.value }
               })
            )
        }

      }
      // animation for condencing views
      .animation(.spring(), value: displayItems)
      .onChange(of: items) { views in

        displayItems = views.prefix(3).enumerated().map {
          .init(index: $0.offset, value: $0.element)
        }

      }

    }
  }

  // MARK: - Components

  /// A wrapper view that distinguishes between views with the same type.
  struct ContentWrapper<Body: View>: View, Equatable, Identifiable {

    var id: UUID {
      identifier
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.identifier == rhs.identifier
    }

    let identifier: UUID = .init()
    let _body: Body

    init(@ViewBuilder body: () -> Body) {
      self._body = body()
    }

    var body: Body {
      _body
    }

  }

  struct BarStyleView: View {

    @Environment(\.glanceContext) var context

    let label: String

    var body: some View {

      ZStack {
        RoundedRectangle(cornerRadius: 10)
          .fill(Color.white)
          .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 0)

        VStack {

          Text("Bar \(label)")
            .font(.title)
            .fontWeight(.bold)

        }
        .padding(8)

      }
      .fixedSize(horizontal: false, vertical: true)
      .modifier(
        SnapDraggingModifier(
          axis: .horizontal,
          horizontalBoundary: .init(min: 0, max: .infinity, bandLength: 50),
          handler: .init(onEndDragging: { velocity, offset, contentSize in

            print(velocity, offset, contentSize)

            if velocity.dx > 50 || offset.width > (contentSize.width / 2) {
              print("remove")
              // TODO: Use velocity
              context?.dismiss()
              return .init(width: contentSize.width, height: 0)
            } else {
              print("stay")
              return .zero
            }
          })
        )
      )
      // transition for view insertion and deletion
      .transition(
        .asymmetric(
          insertion: .modifier(
            active: StyleModifier(opacity: 0, scale: .init(width: 0.8, height: 0.8)),
            identity: StyleModifier.identity
          )
          .animation(.spring(response: 0.2)),
          removal: .modifier(
            active: StyleModifier(opacity: 0, scale: .init(width: 0.8, height: 0.8)),
            identity: StyleModifier.identity
          )
          .animation(.spring(response: 0.4))
        )
      )

      .onTapGesture {
        //        context?.dismiss()
      }
      //      .onAppear {
      //        Task {
      //          try? await Task.sleep(nanoseconds: 1_000_000_000)
      //          context?.dismiss()
      //        }
      //      }

    }

  }

  struct PopView: View {

    @Environment(\.glanceContext) var context

    let label: String

    var body: some View {

      ZStack {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(Color.white)
          .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 0)

        VStack {

          Text("Pop \(label)")
            .font(.title)
            .fontWeight(.bold)

        }
        .padding(8)

      }
      .fixedSize(horizontal: true, vertical: true)
      // transition for view insertion and deletion
      .transition(
        .opacity
          .combined(with: .scale(scale: 0.85, anchor: .center))
          .animation(.spring(response: 0.2, dampingFraction: 0.6))
      )
      .onTapGesture {
        context?.dismiss()
      }

    }

  }

}

public struct GlanceContext {

  private let _dismiss: () -> Void

  init(onDismiss: @escaping () -> Void) {
    self._dismiss = onDismiss
  }

  public func dismiss() { _dismiss() }
}

private enum GlanceContextKey: EnvironmentKey {

  typealias Value = GlanceContext?

  static var defaultValue: GlanceContext? {
    nil
  }

}

extension EnvironmentValues {

  public var glanceContext: GlanceContext? {
    get {
      self[GlanceContextKey.self]
    }
    set {
      self[GlanceContextKey.self] = newValue
    }
  }
}

