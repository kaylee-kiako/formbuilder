# Requirements

- Typst (to render the PDF)
- Deno (to modify the PDF with `lib-pdf` to add form fields)
- Yarn (to install `lib-pdf`)

# Usage

To run the program, simply run:

```sh
yarn # Install dependencies
deno run build.ts # Run build script.
```

You will be prompted for a form to build. Inputting `sample` will cause the program to use the file `sample.kdl` as input and write to `sample.pdf` as output.

> [!warning]
> Any KDL values typed as `content` will be evaluated as Typst markup! Make sure you trust any and all `content`-typed values in the supplied `.kdl` document.

# Questions

> Hey, these look a lot like \[INSERT FAVORITE TAX FORM\]...

Yes! It was entirely my intention to reproduce the style of certain IRS Tax Forms. In particular, I took a lot of inspiration from the following:

- IRS Form 56-F, Rev. December 2022
- IRS Form 433-A, Rev. July 2022 (table support eventually™!)
- IRS Form 461, Rev. February 2025

*Please*, do not create forms purporting to be published by the IRS. The IRS performs a public service, and taxes can be difficult enough to navigate without fake forms floating about.

(My favorite form is Form 172, Rev. December 2024; in particular, Part I. What is even going on here? I must know how this was determined to be the best representation.)
