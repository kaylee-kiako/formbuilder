#import "elements.typ" as elements
#import "internal.typ" as internal
#import "style.typ" as styles

#let form(style: "december2022", ..rest) = {
  /// Get our style
  let style = if type(style) == str {
    import "style.typ" as styles
    dictionary(styles).at(style)
  } else if type(style) == dictionary {
    style
  } else {
    panic("Style must be a string or dictionary.")
  }

  grid(
    columns: (1fr,) * style.columns,
    stroke: (x, y) => (
      (bottom: style.strokes.thin) + if x > 0 { (left: style.strokes.thin) }
    ),
    ..rest
  )
}

#let from-kdl(kdl, style: "december2022") = {
  // Define our style.
  let style = if type(style) == str {
    dictionary(styles).at(style)
  } else if type(style) == dictionary {
    style
  } else {
    panic("Style must be str or dictionary.")
  }

  // All of our elements, as a dictionary.
  let form-elements = {
    let elements = dictionary(elements)
    let _ = elements.remove("internal")
    elements
  }

  import "@preview/kuddle:0.1.0" as kuddle
  form(
    style: style,
    ..kuddle
      .parse-kdl(kdl)
      .map(node => {
        if not (node.name in form-elements) {
          panic("Unknown node name: " + node.name)
        }
        let element = form-elements.at(node.name)
        let data = internal.extract-data-from-kdl(
          node,
          element.schema,
          style,
        )
        (element.render)(data, style)
      })
      .flatten(),
  )
}


// #from-kdl("title-bar")
