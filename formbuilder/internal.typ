/// Define the form metadata, including position location.
///
/// - form-type (text): The type of the form, e.g., "short" or "checkbox".
/// - form-label (text): The unique label of this form element.
/// - radioGroup (text|none): The radio group that this belongs to. `form-type` must be "radio".
/// -> A metadata element.
#let metadata(
  form-type,
  form-label,
  radio-group: none,
) = box(
  width: 100%,
  height: 100%,
  layout(size => {
    let position = here().position()
    [#std.metadata((
        formItemIndex: counter("formItemIndex").get(),
        formType: form-type,
        formLabel: form-label,
        width: size.width.pt(),
        height: size.height.pt(),
        page: position.page,
        x: position.x.pt(),
        // We need to invert the y-coordinate for pdf-lib
        y: (page.height - position.y - size.height).pt(),
        radioGroup: radio-group,
      ))
      #label(form-label)]
  }),
)

/// Render out the item number for an item on the form.
///
/// - rowspan (int): The number of rows this needs to fill.
/// - style (dictionary): The global style dictionary.
/// - level (int): The level of this element. Either 1 or 2.
/// - step (boolean): Whether we need to step this here.
/// -> grid.cell
#let item-number(
  rowspan,
  style,
  level: 1,
  step: true,
  align: top + center,
) = grid.cell(
  align: align,
  rowspan: rowspan,
  {
    set text(..style.numbers.text)
    if step { counter("formItemIndex").step(level: level) }
    context numbering(
      style.numbers.numbering.at(level - 1),
      counter("formItemIndex").get().at(level - 1),
    )
  },
)

/// Render out a radio option circle.
///
/// - label (text): The unique label of this radio option.
/// - style (dictionary): The global style dictionary.
/// - radio-group (text): The radio group of this radio option.
/// -> grid.cell
#let radio-option(label, style, radio-group, align: top) = grid.cell(
  align: align,
  inset: style.elements.radio.button-inset,
  box(
    width: style.elements.radio.button-diameter,
    height: style.elements.radio.button-diameter,
    circle(
      height: 100%,
      stroke: style.elements.radio.button-stroke,
      inset: -1pt,
      metadata("radio", label, radio-group: radio-group),
    ),
  ),
)

/// Render out a checkbox box.
///
/// - label (text): The unique label of this checkbox.
/// - style (dictionary): The global style dictionary.
/// -> grid.cell
#let checkbox(label, style) = grid.cell(
  align: top + right,
  inset: style.elements.multi.checkbox-inset,
  {
    box(
      stroke: style.elements.multi.checkbox-stroke,
      width: style.elements.multi.checkbox-size,
      height: style.elements.multi.checkbox-size,
      metadata("checkbox", label),
    )
  },
)

/// Render out a 'specify' option for a checkbox or radio option.
///
/// - label (text): The label of the parent radio or checkbox.
/// - style (dictionary): The global style dictionary.
/// -> content
#let specify-short(label, style) = (
  h(style.specify.gap)
    + box(
      width: 1fr,
      // TODO: This probably isn't the right offset here; likely based on text size.
      place(dy: 0.2em - style.specify.line-height, box(
        width: 1fr,
        height: style.specify.line-height,
        stroke: (bottom: style.strokes.guide-line),
        metadata("short", label + "+specify"),
      )),
    )
)

/// Loads a raw value into a realized form.
///
/// The returned value is always of type `desired-type`.
///
/// `raw-type` can be any of the following:
///   - "csv"
///   - "ref"
///   - "markup"
///   - "csv,ref"
///   - "csv,markup"
///   - "markup"
///   - none
///
/// Callers should use this only for manual parsing of nodes that can't use a schema.
///
/// - raw-value (string): The KDL value.
/// - raw-type (string|none): The KDL annotated type.
/// - desired-type (type): The desired value type. The value will attempt to cast to this.
/// - csv-row (dictionary|none): The current CSV row context.
/// -> (value of type `desired-type`)
#let load-value(raw-value, raw-type, desired-type, csv-row) = {
  let raw-types = if raw-type == none { () } else { raw-type.split(",") }

  let raw-value = if not raw-types.contains("csv") { raw-value } else {
    let _ = raw-types.remove(raw-types.position(v => v == "csv"))
    if csv-row == none {
      panic("CSV type can only be used in a `for-each-csv` block")
    }
    if desired-type not in (str, content, int, bool) {
      panic("Type " + desired-type + " cannot load from CSV data")
    }
    if raw-value not in csv-row {
      panic("Column " + raw-value + " not in CSV data")
    }
    csv-row.at(raw-value)
  }

  if raw-types.contains("ref") and raw-types.contains("markup") {
    panic("Types `ref` and `markup` are mutually exclusive.")
  }

  let raw-value = if not raw-types.contains("ref") { raw-value } else {
    let _ = raw-types.remove(raw-types.position(v => v == "ref"))
    if desired-type != content {
      panic("Type " + desired-type + " cannot be a reference")
    }
    context numbering(
      style.numbers.numbering.join(),
      ..counter("formItemIndex").at(ref(raw-value)),
    )
  }

  let raw-value = if not raw-types.contains("markup") { raw-value } else {
    let _ = raw-types.remove(raw-types.position(v => v == "markup"))
    if desired-type != content {
      panic("Type " + desired-type + " cannot load markup")
    }
    eval(raw-value, mode: "markup")
  }

  if raw-types.len() > 0 {
    panic("Unknown types: " + raw-types.join(", "))
  }

  if desired-type == content { [#raw-value] } else if desired-type == bool {
    if type(raw-value) == bool {
      raw-value
    } else {
      panic("Value " + raw-value + " is not a bool")
    }
  } else { (desired-type)(raw-value) }
}


/// Converts a node with entries and children into a dictionary of arrays of
/// {type, value} objects.
///
/// This makes no guarantees about the returned values. Callers must perform
/// their own data loading and validation. Consider using
/// `extract-data-from-kdl` instead.
///
/// Values with names `none` are loaded to the name "-".
///
/// - node (dictionary): The KDL node to extract.
/// - panic-on-mixed (bool): If true, panic any time a node has entries and
///                          children with the same name.
/// -> dictionary: The type of this node and its contained data.
#let extract-data-from-node(node, panic-on-mixed: true) = {
  let data = (:)
  let defined-in-entries = (:)
  for entry in node.entries {
    let data-key = if entry.name == none { "-" } else { entry.name }
    let previous-data = data.at(data-key, default: ())
    data.insert(
      data-key,
      previous-data + ((type: entry.type, data: entry.value),),
    )
    defined-in-entries.insert(data-key, true)
  }
  for child in node.children {
    let data-key = child.name
    let previous-data = data.at(data-key, default: ())
    if panic-on-mixed and data-key in defined-in-entries {
      panic(
        "Key "
          + data-key
          + " of node "
          + node.name
          + " defined in both entries and children",
      )
    }
    let new-data = (
      extract-data-from-node(child, panic-on-mixed: panic-on-mixed),
    )
    let new-data = if new-data.at(0).data.keys() == ("-",) {
      new-data.at(0).data.at("-")
    } else { new-data }
    data.insert(
      data-key,
      previous-data + new-data,
    )
  }
  return (type: node.type, data: data)
}


/// Merges the realized values based on the policy of the desired type.
///
/// The policies are:
///   - str, content: join
///   - int, bool, dictionary: only allow one entry
///   - array: return as-is
#let merge-on-policy(desired-type, data-array) = {
  if desired-type in (str, content) {
    return data-array.join()
  }
  if desired-type in (int, bool, dictionary) {
    if data-array.len() > 1 {
      panic("Type " + desired-type + " can only be defined once")
    }
    return data-array.at(0)
  }
  if desired-type == array { return data-array }
  panic("Schema error: Inner type " + desired-type + " unknown.")
}


/// Loads a dataset against the given schema.
///
/// This is the next logical step after `extract-data-from-node`.
///
/// This generally needs to be followed by filling in default values.
#let load-data(raw-data, schema, csv-row) = {
  let final-data = (:)
  for (key, list-of-subdata) in raw-data.data.pairs() {
    let (final-key, key-schema) = {
      let maybe-match = schema
        .pairs()
        .find(((k, s)) => {
          let path = if key == "-" { none } else { key }
          s.path == path
        })
      if maybe-match == none {
        panic("Key " + key + " is unknown.")
      }
      maybe-match
    }
    let loaded-data = list-of-subdata.map(subdata => {
      // subdata: {type(str|none), data(dictionary|value)}
      if type(subdata.data) == dictionary {
        // subdata.data: {[index]: array({type(str|none), data(dictionary|value)})}
        // It's definitely a type we want.
        // TODO: This segment is bad!!!!!
        load-data(subdata, key-schema.subschema, csv-row)
      } else {
        let ty = if key-schema.type == array { key-schema.subtype } else {
          key-schema.type
        }
        load-value(subdata.data, subdata.type, ty, csv-row)
      }
    })
    let final-value = merge-on-policy(key-schema.type, loaded-data)
    final-data.insert(final-key, final-value)
  }
  return final-data
}


/// Fills in defaults based on the schema, panicking for missing keys.
#let load-defaults(loaded-data, schema, style) = {
  let final-data = (:)
  for (key, key-schema) in schema {
    if key-schema.type == array and key-schema.subtype == dictionary {
      final-data.insert(
        key,
        loaded-data
          .at(key, default: ())
          .map(loaded-subdata => load-defaults(
            loaded-subdata,
            key-schema.subschema,
            style,
          )),
      )
    } else if key-schema.type == dictionary {
      final-data.insert(key, load-defaults(
        loaded-data.at(key, default: (:)),
        key-schema.subschema,
        style,
      ))
    } else if key in loaded-data {
      final-data.insert(key, loaded-data.at(key))
    } else if "default" not in key-schema {
      panic("Key " + key + " has no default and must be provided")
    } else if type(key-schema.default) == function {
      final-data.insert(key, (key-schema.default)(style))
    } else {
      final-data.insert(key, key-schema.default)
    }
  }
  return final-data
}


/// Extracts the specified data construct from the given KDL node.
///
/// The `schema` element must be of the form ([key]: ExtractDef), where ExtractDef is:
///
///  `type`: One of `str`, `content`, `int`, `bool`, `dictionary`, or `array`
///          This affects how the data is loaded:
///            - Str and content nodes are concatenated.
///            - Int, bool, and dictionary nodes may only be defined once.
///            - Array nodes are distinct entries of one of the above.
///          and what custom parsers are allowed:
///            - Str, int, and bool accept `csv` types.
///            - Content accepts `csv` and `markup` types.
///            - Dictionary and array do not accept types.
///  `subtype`: Any accepted type except `array`. Only used for `array`.
///  `default`: A default value. Unavailable for `array` and `dictionary`.
///             May be a function taking in the style.
///  `path`: The KDL path from the root to obtain this item. Type `text|none`.
///  `subschema`: For `dictionary` and `array[dictionary]`.
///               A recursive `data`-style element to define the child (children).
///
/// - node (dictionary): The KDL node.
/// - data (dictionary): The data to extract. See the full documentation for more information.
/// - style (dictionary): The global style dictionary. May be used for defaults.
/// - csv-row (dictionary|none): The current CSV row, for extracting CSV data.
/// -> A populated data dictionary.
#let extract-data-from-kdl(node, schema, style, csv-row: none) = {
  let raw-data = extract-data-from-node(node)
  let provided-data = load-data(raw-data, schema, csv-row)
  let final-data = load-defaults(provided-data, schema, style)
  return final-data
}


/// Produce a colspan value that would cause this element to fill out the rest of its row.
///
/// - style (dictionary): The global style dictionary.
/// -> int
#let fill-row(style) = {
  // FIXME: We are encountering an issue with Typst's data model here:
  //   - You cannot context-wrap the calculation or it isn't an `int`.
  //   - You cannot context-wrap the grid.cell or colspan is ignored.
  //   - You cannot context-wrap the grid or updates are missed.
  panic("Default colspan is not currently supported")
  let row-fill = state("formCurrentRowFill", 0)
  style.columns - row-fill.get()
}


/// Update the `currentRowFill` state with this cell's colspan.
///
/// This *must* be invoked by all cells with colspan not equal to `style.columns`.
///
/// - style (dictionary): The global style dictionary.
/// - amount (int): The amount of this cell's colspan.
/// -> int
#let update-row-fill(style, amount) = {
  let row-fill = state("formCurrentRowFill", 0)
  row-fill.update(it => calc.rem(it + amount, style.columns))
}
