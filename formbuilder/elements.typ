#import "internal.typ" as internal

/// A simple title bar element.
///
/// The title bar consists of:
///   * a title,
///   * a form number,
///   * a form type (e.g., Report, Form, Ballot)
///   * a revision, indicating when the *layout* was last changed.
///   * a special field tentatively referred to as the owner.
///     this is typically best used for things like:
///       * "Office of the President"
///       * "For Internal Use Only"
///       * "Edition 2026-03-03" (for CSV-sourced items)
///     some inspirations leave this area blank. use it as you need it.
///
/// The title bar always has `span == style.columns`.
#let title-bar = (
  /// The data required by the render function.
  /// See `internal.extract-data-from-kdl`.
  schema: (
    title: (
      type: content,
      path: "title",
    ),
    revision: (
      type: content,
      default: none,
      path: "revision",
    ),
    type: (
      type: content,
      default: "Form",
      path: "type",
    ),
    id: (
      type: content,
      path: "id",
    ),
    owner: (
      type: content,
      default: none,
      path: "owner",
    ),
  ),
  /// Render this element.
  ///
  /// - data (dictionary): The data for this element.
  /// - style (dictionary): The global style dictionary.
  /// -> grid.cell
  render: (data, style) => grid.cell(
    stroke: (bottom: style.strokes.thick),
    colspan: style.columns,
    {
      // Check that our style is valid.
      if style.elements.title-bar.columns.len() != 3 {
        panic("`elements.title-bar.style` must have exactly 3 lengths.")
      }
      // Maximum of one title.
      let form-has-title = state("formHasTitle", false)
      context if form-has-title.get() {
        panic("Cannot have more than one `title-bar` per document.")
      }
      state("formHasTitle").update(_ => true)
      // Render the title.
      grid(
        columns: style.elements.title-bar.columns,
        // Top-left corner: Form number and revision.
        grid.cell(
          align: bottom,
          inset: (
            right: style.elements.title-bar.inset,
            bottom: style.elements.title-bar.inset,
          ),
          {
            set text(..style.elements.title-bar.text.corner)
            [#data.type #text(..style.elements.title-bar.text.form, data.id)]
            if "revision" in data [\ (Rev. #data.revision)]
          },
        ),
        // Top-middle: Title!
        grid.cell(
          align: center + horizon,
          inset: (
            x: style.elements.title-bar.inset,
            bottom: style.elements.title-bar.inset,
          ),
          stroke: (x: style.strokes.thick),
          {
            show title: set text(..style.elements.title-bar.text.title)
            show title: it => it.body
            title(data.title)
          },
        ),
        // Top-right: What we're tentatively calling "owner".
        grid.cell(
          align: center + horizon,
          text(..style.elements.title-bar.text.corner, data.owner),
        )
      )
    },
  ),
)

/// A "Part"-style divider.
///
/// Note that, for accessibility, we attempt to use semantic headings.
/// As a result, whichever gets used first between `part` and `section` will
/// be given the top-level heading. Since part is considered higher order than
/// section, we will force a panic if the first part appears after a section(s),
/// since this violates accessibility standards.
#let part = (
  /// The data required by the render function.
  /// See `internal.extract-data-from-kdl`.
  schema: (
    body: (
      type: content,
      path: none,
    ),
  ),
  /// Render this element.
  ///
  /// - data (dictionary): The data for this element.
  /// - style (dictionary): The global style dictionary.
  /// -> grid.cell
  render: (data, style) => grid.cell(
    colspan: style.columns,
    stroke: (
      top: style.strokes.thick,
      bottom: style.strokes.thin,
    ),
    inset: style.elements.part.inset,
    {
      // Confirm that the firt part does not appear after any sections.
      let form-uses-parts = state("formUsesParts", none)
      context if form-uses-parts.get() == false {
        panic("First 'part' element must appear before any 'section' elements.")
      }
      form-uses-parts.update(val => if val == none { true } else { false })
      counter(heading).step()
      set text(..style.elements.part.text)
      {
        // The "Part I" box.
        box(
          fill: black,
          ..style.elements.part.number-box,
          align(center, text(
            fill: white,
            {
              style.elements.part.supplement
              " "
              context numbering(
                style.elements.part.numbering,
                counter(heading).get().at(0),
              )
            },
          )),
        )
        // The actual body.
        box(
          ..style.elements.part.body-box,
          data.body,
        )
      }
    },
  ),
)

/// A "Section"-style divider.
///
/// Note that, for accessibility, we attempt to use semantic headings.
/// As a result, whichever gets used first between `part` and `section` will
/// be given the top-level heading. Since part is considered higher order than
/// section, we will force a panic if the first part appears after a section(s),
/// since this violates accessibility standards.
#let section = (
  /// The data required by the render function.
  /// See `internal.extract-data-from-kdl`.
  schema: (
    body: (
      type: content,
      path: none,
    ),
  ),
  /// Render this element.
  ///
  /// - data (dictionary): The data for this element.
  /// - style (dictionary): The global style dictionary.
  /// -> grid.cell
  render: (data, style) => grid.cell(
    colspan: style.columns,
    inset: style.elements.section.inset,
    stroke: (y: style.strokes.thin),
    align: center,
    {
      let form-uses-parts = state("formUsesParts", none)
      form-uses-parts.update(val => if val == none { false } else { true })
      set text(..style.elements.section.text)
      show heading: set text(..style.elements.section.text)
      show heading: it => it.body
      context {
        let level = if form-uses-parts.get() { 2 } else { 1 }
        counter(heading).step(level: level)
      }
      context {
        let level = if form-uses-parts.get() { 2 } else { 1 }
        heading({
          (
            style.elements.section.supplement
              + " "
              + numbering(
                style.elements.section.numbering,
                counter(heading).get().at(level - 1),
              )
              + sym.dash.em
              + heading(data.body)
          )
        })
      }
    },
  ),
)

/// An informational or instructional text box, with no form fields.
#let info = (
  /// The data required by the render function.
  /// See `internal.extract-data-from-kdl`.
  schema: (
    body: (
      type: content,
      path: none,
    ),
    span: (
      type: int,
      // default: internal.fill-row,
      path: "span",
    ),
  ),
  /// Render this element.
  ///
  /// - data (dictionary): The data for this element.
  /// - style (dictionary): The global style dictionary.
  /// -> grid.cell
  render: (data, style) => grid.cell(
    colspan: data.span,
    inset: style.elements.info.inset,
    {
      internal.update-row-fill(style, data.span)
      set text(..style.elements.info.text)
      data.body
    },
  ),
)

/// A barrier 'fence'.
///
/// Fences are used to communicate important instructions, typically something
/// along the lines of "For Internal Use Only".
#let fence = (
  /// The data required by the render function.
  /// See `internal.extract-data-from-kdl`.
  schema: (
    /// The text content of this element.
    body: (
      type: content,
      path: none,
    ),
  ),
  /// Render this element.
  ///
  /// - data (dictionary): The data for this element.
  /// - style (dictionary): The global style dictionary.
  /// -> grid.cell
  render: (data, style) => grid.cell(
    colspan: style.columns,
    inset: style.elements.fence.inset,
    stroke: (y: style.strokes.thin),
    fill: black,
    align: center,
    text(fill: white, ..style.elements.fence.text, data.body),
  ),
)

/// A greyed-out, unused cell.
///
/// Typst's layout engine requires each cell to be able to fit greedily into the
/// next available cell position. The 'unused' cell allows us to fill space
/// without having to enlarge any form boxes.
///
/// Because of how we're drawing our borders, there's some limitations on where
/// and how often you can use these. Where at all possible, try to structure your
/// form to not require these at all.
#let unused = (
  /// The data required by the render function.
  /// See `internal.extract-data-from-kdl`.
  schema: (
    span: (
      type: int,
      // default: internal.fill-row,
      path: "span",
    ),
  ),
  /// Render this element.
  ///
  /// - data (dictionary): The data for this element.
  /// - style (dictionary): The global style dictionary.
  /// -> grid.cell
  render: (data, style) => grid.cell(
    colspan: data.span,
    fill: style.elements.unused.fill,
    internal.update-row-fill(style, data.span),
  ),
)

/// A short text response, with a form-fillable short-response field.
///
/// The 'body' is placed just above the text, left aligned. To help with
/// alignment, this should either:
///
///   * span the entire width of the column, or
///   * be only one line long.
///
/// I recommend using 'info' elements and footnote where these limitations
/// cannot otherwise be met.
#let short = (
  /// The data required by the render function.
  /// See `internal.extract-data-from-kdl`.
  schema: (
    label: (
      type: str,
      path: "label",
    ),
    body: (
      type: content,
      path: none,
    ),
    span: (
      type: int,
      // default: internal.fill-row,
      path: "span",
    ),
  ),
  /// Render this element.
  ///
  /// - data (dictionary): The data for this element.
  /// - style (dictionary): The global style dictionary.
  /// -> grid.cell
  render: (data, style) => grid.cell(
    colspan: data.span,
    inset: style.elements.short.inset,
    {
      internal.update-row-fill(style, data.span)
      set text(..style.text)
      grid(
        columns: (style.numbers.width, 1fr),
        rows: (auto, style.elements.short.line-height),
        internal.item-number(2, style),
        grid.cell(inset: style.elements.short.body-inset, data.body),
        grid.cell(internal.metadata("short", data.label)),
      )
    },
  ),
)

/// A long text response, with a form-fillable multiline response field.
///
/// The body is placed just above the text, left aligned.
/// To help with alignment, this should either:
///
///   * span the entire width of the column, or
///   * have a very carefully-considered description and number of lines.
#let long = (
  /// The data required by the render function.
  /// See `internal.extract-data-from-kdl`.
  schema: (
    label: (
      type: str,
      path: "label",
    ),
    body: (
      type: content,
      path: none,
    ),
    rows: (
      type: int,
      path: "rows",
    ),
    span: (
      type: int,
      // default: internal.fill-row,
      path: "span",
    ),
  ),
  /// Render this element.
  ///
  /// - data (dictionary): The data for this element.
  /// - style (dictionary): The global style dictionary.
  /// -> grid.cell
  render: (data, style) => grid.cell(
    colspan: data.span,
    inset: style.elements.long.inset,
    {
      internal.update-row-fill(style, data.span)
      set text(..style.text)
      grid(
        columns: (style.numbers.width, 1fr),
        rows: (auto, style.elements.long.line-height * data.rows),
        internal.item-number(2, style),
        grid.cell(inset: style.elements.long.body-inset, data.body),
        grid.cell(internal.metadata("long", data.label)),
      )
    },
  ),
)

/// A short text response optimized for writing numbers that might need to be
/// manipulated later.
#let number = (
  /// The data required by the render function.
  /// See `internal.extract-data-from-kdl`.
  schema: (
    label: (
      type: str,
      path: "label",
    ),
    body: (
      type: content,
      path: none,
    ),
    span: (
      type: int,
      // default: internal.fill-row,
      path: "span",
    ),
  ),
  /// Render this element.
  ///
  /// - data (dictionary): The data for this element.
  /// - style (dictionary): The global style dictionary.
  /// -> grid.cell
  render: (data, style) => grid.cell(
    colspan: data.span,
    {
      internal.update-row-fill(style, data.span)
      set text(..style.text)
      grid(
        columns: (style.numbers.width, 1fr) + style.elements.number.columns,
        inset: (x, y) => if x == 0 or x == 2 {
          style.elements.number.inset
        } else { 0pt },
        internal.item-number(1, style),
        grid.cell(
          stroke: (right: style.strokes.thin),
          inset: style.elements.number.body-inset,
          data.body,
        ),
        internal.item-number(1, style, step: false, align: bottom + center),
        grid.cell(align: bottom, stroke: (left: style.strokes.thin), box(
          width: 1fr,
          height: style.elements.number.line-height,
          internal.metadata("number", data.label),
        ))
      )
    },
  ),
)

/// A radio selection element.
///
/// Radio selections only allow a single item to be chosen. If you want any number
/// of items able to be chosen, see the 'multi' element.
///
/// This is intended for a variable number of flexible radio responses. If you
/// are asking a yes/no question, see the 'yes-no' element.
#let radio = (
  /// The data required by the render function.
  /// See `internal.extract-data-from-kdl`.
  schema: (
    radio-group: (
      type: str,
      path: "group",
    ),
    body: (
      type: content,
      path: none,
    ),
    span: (
      type: int,
      // default: internal.fill-row,
      path: "span",
    ),
    cols: (
      type: int,
      default: 1,
      path: "cols",
    ),
    options: (
      type: array,
      subtype: dictionary,
      path: "option",
      subschema: (
        label: (
          type: str,
          path: "label",
        ),
        body: (
          type: content,
          path: none,
        ),
        span: (
          type: int,
          default: 1,
          path: "span",
        ),
        specify: (
          type: bool,
          default: false,
          path: "specify",
        ),
      ),
    ),
  ),
  /// Render this element.
  ///
  /// - data (dictionary): The data for this element.
  /// - style (dictionary): The global style dictionary.
  /// -> grid.cell
  render: (data, style) => grid.cell(
    colspan: data.span,
    inset: style.elements.radio.inset,
    {
      internal.update-row-fill(style, data.span)
      set text(..style.text)
      grid(
        columns: (style.numbers.width,) + (auto, 1fr) * data.cols,
        internal.item-number(1 + calc.ceil(data.options.len() / data.cols)),
        grid.cell(
          inset: style.elements.radio.body-inset,
          colspan: data.cols * 2,
          data.body,
        ),
        ..data
          .options
          .map(option => (
            internal.radio-option(option.label, style, data.radio-group),
            grid.cell(
              inset: style.elements.radio.option-inset,
              colspan: option.span * 2 - 1,
              option.body + internal.specify-short(option.label, style),
            ),
          ))
          .flatten()
      )
    },
  ),
)

/// A radio selection optimized for simple yes-no questions.
///
/// In some cases it may be preferred to use a 'multi' element, especially if
/// you have multiple related yes/no questions.
#let yes-no = (
  /// The data required by the render function.
  /// See `internal.extract-data-from-kdl`.
  schema: (
    radio-group: (
      type: str,
      path: "group",
    ),
    body: (
      type: content,
      path: none,
    ),
    span: (
      type: int,
      // default: internal.fill-row,
      path: "span",
    ),
  ),
  /// Render this element.
  ///
  /// - data (dictionary): The data for this element.
  /// - style (dictionary): The global style dictionary.
  /// -> grid.cell
  render: (data, style) => grid.cell(
    colspan: data.span,
    {
      internal.update-row-fill(style, data.span)
      set text(..style.text)
      grid(
        inset: style.elements.yes-no.inset,
        columns: (style.numbers.width, 1fr)
          + 2 * (auto, style.elements.yes-no.yes-no-width),
        internal.item-number(1, style),
        grid.cell(inset: style.elements.yes-no.body-inset, data.body),
        internal.radio-option(
          "yes",
          style,
          data.radio-group,
          align: bottom + right,
        ),
        grid.cell(align: bottom, "Yes"),
        internal.radio-option(
          "no",
          style,
          data.radio-group,
          align: bottom + right,
        ),
        grid.cell(align: bottom, "No"),
      )
    },
  ),
)

/// A multiple-selection element.
///
/// Multi-selection elements allow any number of items to be chosen. If you want
/// to only allow a single item to be chosen, see the 'radio' element.
///
/// If you only have a single option in a multi element, you may want to use a
/// yes/no element instead.
#let multi = (
  /// The data required by the render function.
  /// See `internal.extract-data-from-kdl`.
  schema: (
    body: (
      type: content,
      path: none,
    ),
    span: (
      type: int,
      // default: internal.fill-row,
      path: "span",
    ),
    cols: (
      type: int,
      default: 1,
      path: "cols",
    ),
    options: (
      type: array,
      subtype: dictionary,
      path: "option",
      subschema: (
        label: (
          type: str,
          path: "label",
        ),
        body: (
          type: content,
          path: none,
        ),
        span: (
          type: int,
          default: 1,
          path: "span",
        ),
        specify: (
          type: bool,
          default: false,
          path: "specify",
        ),
      ),
    ),
  ),
  /// Render this element.
  ///
  /// - data (dictionary): The data for this element.
  /// - style (dictionary): The global style dictionary.
  /// -> grid.cell
  render: (data, style) => grid.cell(
    colspan: data.span,
    inset: style.elements.multi.inset,
    {
      internal.update-row-fill(style, data.span)
      set text(..style.text)
      counter("formItemIndex").step()
      grid(
        inset: style.elements.multi.inset,
        columns: (style.numbers.width,)
          + (style.numbers.width, auto, 1fr) * data.cols,
        internal.item-number(
          1 + calc.ceil(data.options.len() / data.cols),
          style,
          step: false,
        ),
        grid.cell(
          inset: style.elements.multi.body-inset,
          colspan: data.cols * 3,
          data.body,
        ),
        ..data
          .options
          .map(option => (
            internal.item-number(1, style, level: 2),
            internal.checkbox(option.label, style),
            grid.cell(
              inset: style.elements.multi.option-inset,
              colspan: option.span * 3 - 2,
              option.body
                + if option.specify {
                  internal.specify-short(option.label, style)
                },
            ),
          ))
          .flatten(),
      )
    },
  ),
)

/// A signature box with a date field.
#let signature = (
  /// The data required by the render function.
  /// See `internal.extract-data-from-kdl`.
  schema: (
    hint: (
      type: content,
      path: "hint",
    ),
    body: (
      type: content,
      path: none,
    ),
    signature: (
      type: dictionary,
      path: "signature",
      subschema: (
        label: (
          type: str,
          path: "label",
        ),
        body: (
          type: content,
          path: none,
        ),
      ),
    ),
    date: (
      type: dictionary,
      path: "date",
      subschema: (
        label: (
          type: str,
          path: "label",
        ),
        body: (
          type: content,
          path: none,
        ),
      ),
    ),
  ),
  /// Render this element.
  ///
  /// - data (dictionary): The data for this element.
  /// - style (dictionary): The global style dictionary.
  /// -> grid.cell
  // TODO: Implement `render`.
  // signature[; body], date[label; body]
  render: (data, style) => grid.cell(
    colspan: style.columns,
    stroke: (y: style.strokes.thick),
    {
      set text(..style.text)
      grid(
        columns: (
          style.elements.signature.hint-width,
          style.elements.signature.margin-width,
          style.elements.signature.signature-width,
          style.elements.signature.gap-width,
          style.elements.signature.date-width,
          style.elements.signature.margin-width,
        ),
        rows: (auto, style.elements.signature.line-height, auto),
        grid.cell(
          rowspan: 3,
          inset: style.elements.signature.hint-inset,
          align: horizon,
          stroke: (right: style.strokes.thin),
          text(..style.elements.signature.hint-text, data.hint),
        ),
        grid.cell(
          colspan: 5,
          inset: style.elements.signature.body-inset,
          data.body,
        ),
        grid.cell(x: 2, y: 1, internal.metadata("short", data.signature.label)),
        grid.cell(
          x: 2,
          y: 2,
          inset: style.elements.signature.signature-inset,
          stroke: (top: style.strokes.thin),
          data.signature.body,
        ),
        grid.cell(x: 4, y: 1, internal.metadata("short", data.date.label)),
        grid.cell(
          x: 4,
          y: 2,
          inset: style.elements.signature.date-inset,
          stroke: (top: style.strokes.thin),
          data.date.body,
        ),
      )
    },
  ),
)
