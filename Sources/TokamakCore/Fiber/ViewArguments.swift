// Copyright 2021 Tokamak contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Created by Carson Katri on 2/7/22.
//

import Foundation

/// Data passed to `_makeView` to create the `ViewOutputs` used in reconciling/rendering.
public struct ViewInputs<V: View> {
  let view: V
  /// The size proposed by this view's parent.
  let proposedSize: CGSize?
  let environment: EnvironmentBox
}

/// Data used to reconcile and render a `View` and its children.
public struct ViewOutputs {
  /// A container for the current `EnvironmentValues`.
  /// This is stored as a reference to avoid copying the environment when unnecessary.
  let environment: EnvironmentBox
  let preferences: _PreferenceStore
  /// The size requested by this view.
  let size: CGSize
  /// The `LayoutComputer` used to propose sizes for the children of this view.
  let layoutComputer: LayoutComputer?
}

final class EnvironmentBox {
  let environment: EnvironmentValues

  init(_ environment: EnvironmentValues) {
    self.environment = environment
  }
}

extension ViewOutputs {
  init<V: View>(
    inputs: ViewInputs<V>,
    environment: EnvironmentValues? = nil,
    preferences: _PreferenceStore? = nil,
    size: CGSize? = nil,
    layoutComputer: LayoutComputer? = nil
  ) {
    // Only replace the EnvironmentBox when we change the environment. Otherwise the same box can be reused.
    self.environment = environment.map(EnvironmentBox.init) ?? inputs.environment
    self.preferences = preferences ?? .init()
    self.size = size ?? inputs.proposedSize ?? .zero
    self.layoutComputer = layoutComputer
  }
}

public extension View {
  // By default, we simply pass the inputs through without modifications
  // or layout considerations.
  static func _makeView(_ inputs: ViewInputs<Self>) -> ViewOutputs {
    .init(inputs: inputs)
  }
}

public extension ModifiedContent where Content: View, Modifier: ViewModifier {
  static func _makeView(_ inputs: ViewInputs<Self>) -> ViewOutputs {
    // Update the environment if needed.
    var environment = inputs.environment.environment
    if let environmentWriter = inputs.view.modifier as? EnvironmentModifier {
      environmentWriter.modifyEnvironment(&environment)
    }
    return .init(inputs: inputs, environment: environment)
  }

  func _visitChildren<V>(_ visitor: V) where V: ViewVisitor {
    // Visit the computed body of the modifier.
    visitor.visit(modifier.body(content: .init(modifier: modifier, view: content)))
  }
}
