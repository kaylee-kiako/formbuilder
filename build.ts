import { PDFDocument, PDFRadioGroup, TextAlignment } from "pdf-lib";

// Step 1: Determine form to build.
// Step 1: Built Typst intermediate file.

const template = prompt("Which form should we build?");
if (template === null) {
  console.log("No form given. Are we in an interactive prompt?");
  Deno.exit(1);
}

const compileResult = new Deno.Command("typst", {
  args: [
    "compile",
    "--root=./.",
    "--font-path=fonts",
    "--ignore-system-fonts",
    `--input=kdl-source=${template}.kdl`,
    "./build.typ",
    "./build.pdf",
  ],
}).outputSync();

if (compileResult.code != 0) {
  console.log(
    "Unable to build the PDF:",
    new TextDecoder().decode(compileResult.stderr),
  );
  Deno.exit(2);
}

if (!confirm("Would you like to attach form fields to the PDF?")) {
  console.log(
    "Form fields will not be added. Copying temporary file to final destination.",
  );
  Deno.copyFile("build.pdf", `${template}.pdf`);
  Deno.exit(0);
}

/// The types of form elements we can handle.
type FormType =
  | "short"
  | "long"
  | "number"
  | "radio"
  | "checkbox";

interface Metadata {
  /// The number (hierarchy) of this form element.
  formIndex: number[];
  /// The type of form element that this is.
  formType: FormType;
  /// The (semi-)unique label for this elements (or elements).
  formLabel: string;
  /// The page that this element appears on.
  page: number;
  /// The x-coordinate of the top-left corner of this element.
  x: number;
  /// The y-coordinate of the top-left corner of this element.
  y: number;
  /// The width of this element.
  width: number;
  /// The height of this element.
  height: number;
  /// If this is a radio, a unique label for this specific option.
  radioGroup?: string;
}

interface Options {
  x: number;
  y: number;
  width: number;
  height: number;
  borderWidth: number;
}
function intoOptions(fieldData: Metadata): Options {
  return {
    x: fieldData.x + 0.5,
    y: fieldData.y + 0.5,
    width: fieldData.width - 1,
    height: fieldData.height - 1,
    borderWidth: 0,
  };
}

const formData: Metadata[] = JSON.parse(new TextDecoder().decode(
  new Deno.Command("typst", {
    args: [
      "query",
      "--root=./.",
      "--font-path=fonts",
      "--ignore-system-fonts",
      `--input=kdl-source=${template}.kdl`,
      "./build.typ",
      "metadata",
    ],
  }).outputSync().stdout,
)).map((it: { func: "metadata"; value: Metadata }) => it.value);

const pdfDoc = await PDFDocument.load(Deno.readFileSync("./build.pdf"));
const radios: { [key: string]: PDFRadioGroup } = {};

const form = pdfDoc.getForm();

for (const fieldData of formData) {
  switch (fieldData.formType) {
    case "short": {
      const field = form.createTextField(fieldData.formLabel);
      field.addToPage(
        pdfDoc.getPage(fieldData.page - 1),
        intoOptions(fieldData),
      );
      break;
    }
    case "number": {
      const field = form.createTextField(fieldData.formLabel);
      field.addToPage(
        pdfDoc.getPage(fieldData.page - 1),
        intoOptions(fieldData),
      );
      field.setAlignment(TextAlignment.Right);
      break;
    }
    case "long": {
      const field = form.createTextField(fieldData.formLabel);
      field.enableMultiline();
      field.addToPage(
        pdfDoc.getPage(fieldData.page - 1),
        intoOptions(fieldData),
      );
      field.setFontSize(9);
      break;
    }
    case "radio": {
      if (!(fieldData.radioGroup as string in radios)) {
        radios[fieldData.radioGroup as string] = form.createRadioGroup(
          fieldData.radioGroup as string,
        );
      }
      const group = radios[fieldData.radioGroup as string];
      group.addOptionToPage(
        fieldData.formLabel as string,
        pdfDoc.getPage(fieldData.page - 1),
        intoOptions(fieldData),
      );
      break;
    }
    case "checkbox": {
      const field = form.createCheckBox(fieldData.formLabel);
      field.addToPage(
        pdfDoc.getPage(fieldData.page - 1),
        intoOptions(fieldData),
      );
      break;
    }
  }
}

Deno.writeFileSync(`${template}.pdf`, await pdfDoc.save());
