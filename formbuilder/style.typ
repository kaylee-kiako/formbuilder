#let december2022 = (
  // How many columns we divide the layout into.
  columns: 6,
  // The text formatting used for most text items.
  // Note that `title-bar`, `part`, and `section` have local overrides.
  text: (size: 9pt),
  // How we format our numbers.
  numbers: (
    width: 1em,
    text: (weight: "bold", size: 9pt),
    numbering: ("1", "a"),
  ),
  // The paper size used.
  paper: "us-letter",
  // The margins used for the paper.
  paper-margin: 0.5in,
  // Shared border strokes.
  strokes: (
    // The thin border used between and within most elements.
    thin: 0.5pt + black,
    // The thick border used around `title-bar`, `part` and `signature` elements.
    thick: 1pt + black,
    // The underline guide-lines for multi-response items and for 'specify' fields on radios and checkboxes.
    guide-line: (dash: "dotted", thickness: 0.5pt, paint: black),
  ),
  specify: (
    gap: 1em,
    line-height: 1.5em,
  ),
  // (x, y) => (bottom: stroke) + if x > 0 { (left: stroke) },
  // Rules specific to certain elements.
  elements: (
    title-bar: (
      // The column spread for the three elements of the title bar.
      columns: (1fr, 4fr, 1fr),
      inset: 3pt,
      text: (
        form: (size: 24pt, weight: "extrabold"),
        title: (size: 14pt, weight: "bold"),
        corner: (size: 6.75pt),
      ),
    ),
    part: (
      text: (weight: "bold", size: 11pt),
      numbering: "I",
      supplement: "Part",
      inset: 0pt,
      number-box: (
        inset: (y: 3pt),
        width: 1fr,
      ),
      body-box: (
        inset: (x: 4.54545%, y: 3pt),
        width: 11fr,
      ),
    ),
    section: (
      text: (size: 10pt),
      numbering: "A",
      supplement: "Section",
      inset: 3pt,
    ),
    info: (
      text: (size: 9pt),
      inset: (x: 3pt, y: 6pt),
    ),
    fence: (
      inset: 3pt,
      text: (size: 11pt, weight: "bold"),
    ),
    unused: (
      fill: gray.lighten(70%),
    ),
    short: (
      inset: 3pt,
      line-height: 1.5em,
      body-inset: (left: 1em),
    ),
    long: (
      inset: 3pt,
      body-inset: (left: 1em),
      line-inset: (left: 1em, top: 3pt),
      line-height: 2em,
    ),
    number: (
      // The columns of the field and its numerical label.
      columns: (2em, 1in),
      inset: 3pt,
      body-inset: (left: 1em, rest: 3pt),
      line-height: 1.3em,
    ),
    radio: (
      // The stroke around the circular radio.
      inset: 3pt,
      body-inset: (left: 1em, bottom: 3pt),
      button-inset: 3pt,
      button-stroke: 1pt + black,
      button-diameter: 8pt,
      option-inset: 3pt,
    ),
    yes-no: (
      inset: 3pt,
      body-inset: (left: 1em),
      yes-no-width: 4em,
    ),
    multi: (
      inset: 3pt,
      body-inset: (left: 1em, bottom: 3pt),
      option-inset: 3pt,
      checkbox-inset: 3pt,
      checkbox-stroke: 1pt + black,
      checkbox-size: 8pt,
    ),
    signature: (
      hint-width: 1fr,
      signature-width: 6fr,
      date-width: 3fr,
      gap-width: 1fr,
      margin-width: 0.5fr,
      line-height: 2.5em,
      hint-inset: (y: 3pt),
      body-inset: 3pt,
      signature-inset: 3pt,
      date-inset: 3pt,
      hint-text: (size: 11pt, weight: "bold"),
    ),
  ),
)
