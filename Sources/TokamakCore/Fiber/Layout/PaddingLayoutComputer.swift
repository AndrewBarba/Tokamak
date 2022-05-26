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
//  Created by Carson Katri on 5/24/22.
//

import Foundation

private extension EdgeInsets {
  func size(with edges: Edge.Set) -> CGSize {
    .init(
      width: (edges.contains(.leading) ? leading : 0) +
        (edges.contains(.trailing) ? trailing : 0),
      height: (edges.contains(.top) ? top : 0) + (edges.contains(.bottom) ? bottom : 0)
    )
  }
}

/// A `LayoutComputer` that applies padding to its children.
final class PaddingLayoutComputer: LayoutComputer {
  let proposedSize: CGSize
  let edges: Edge.Set
  let insets: EdgeInsets
  let insetSize: CGSize

  init(proposedSize: CGSize, edges: Edge.Set, insets: EdgeInsets?) {
    self.proposedSize = proposedSize
    self.edges = edges
    let insets = insets ?? EdgeInsets(_all: 10)
    self.insets = insets
    insetSize = insets.size(with: edges)
  }

  func proposeSize<V>(for child: V, at index: Int, in context: LayoutContext) -> CGSize
    where V: View
  {
    .init(
      width: proposedSize.width - insetSize.width,
      height: proposedSize.height - insetSize.height
    )
  }

  func position(_ child: LayoutContext.Child, in context: LayoutContext) -> CGPoint {
    .init(
      x: edges.contains(.leading) ? insets.leading : 0,
      y: edges.contains(.top) ? insets.top : 0
    )
  }

  func requestSize(in context: LayoutContext) -> CGSize {
    let childSize = context.children.reduce(CGSize.zero) {
      .init(
        width: max($0.width, $1.dimensions.width),
        height: max($0.height, $1.dimensions.height)
      )
    }
    return .init(
      width: childSize.width + insetSize.width,
      height: childSize.height + insetSize.height
    )
  }
}

public extension _PaddingLayout {
  static func _makeView(_ inputs: ViewInputs<_PaddingLayout>) -> ViewOutputs {
    .init(
      inputs: inputs
    ) { proposedSize in
      PaddingLayoutComputer(
        proposedSize: proposedSize,
        edges: inputs.view.edges,
        insets: inputs.view.insets
      )
    }
  }
}
