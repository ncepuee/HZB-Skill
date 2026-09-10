# Academic Markdown/MathJax formula standard

## Delimiters and layout

- Use `$...$` for inline formulas. Do not use `\(...\)`.
- Put each `$$` delimiter on its own line and leave a blank line before and after a display-math block.
- Do not place Markdown prose, headings, list markers, or table separators on a `$$` delimiter line.
- In formal derivations and reviewer-response notes, place exactly one `\tag{...}` in every display-math block unless the active template explicitly permits unnumbered equations.
- Preserve the document's established tag prefix and keep the numerical suffix continuous and unique.

## Subscripts, superscripts, and operators

- Use `\text{...}` for descriptive words or abbreviations in subscripts and superscripts: `$x_{\text{ref}}$`, `$Z_{\text{grid}}$`, `$P_{\text{RHP}}$`.
- Keep genuine mathematical indices italic: `$x_i$`, `$a_{ij}$`, `$k=1,2,\ldots,n$`.
- Keep purely numeric subscripts in math style: `$f_0$`, `$Z_1$`.
- Use `^{\text{T}}` and `^{\text{H}}` for transpose and conjugate transpose.
- Use proper named operators such as `\operatorname{Re}`, `\operatorname{Im}`, `\det`, and `\lambda_{\min}`.
- Never leave malformed combinations such as `^_`, `_}`, `^{}`, or an unmatched brace.

## Mathematical typography

- Use upright imaginary units: `\mathrm{j}` rather than italic `j` when it denotes $\sqrt{-1}$.
- Use `\text{...}` for units: `$50\,\text{Hz}$`, `$2\pi\times10^{-3}\,\text{rad/s}$`, `$1\,\text{p.u.}$`.
- Use `\boldsymbol{...}` for vectors and matrices when the notation distinguishes them from scalars: `$\boldsymbol L_{dq}$`, `$\boldsymbol A_{\text{z}}$`.
- Use `\mathrm{e}` only for the exponential constant when that convention is needed; use `\exp(\cdot)` when clearer.
- Use `\text{...}` rather than `\mathrm{...}` for descriptive subscripts. Reserve `\mathrm` for mathematical symbols that must be upright.

## Matrices, brackets, and multiline formulas

- Pair every `\begin{...}` with the matching `\end{...}`.
- Separate matrix or aligned rows with `\\`, never a single trailing backslash.
- Pair `\left` and `\right`, and ensure braces, brackets, and parentheses are balanced.
- Use an appropriate environment such as `bmatrix`, `pmatrix`, `aligned`, or `cases`; do not simulate a matrix with prose lines.
- Keep punctuation consistent with the surrounding sentence when a displayed equation is grammatically part of it.

## Markdown boundaries

- Never reinterpret content inside fenced code blocks as mathematical notation.
- Leave YAML frontmatter keys and values untouched unless the task explicitly concerns frontmatter.
- Keep blank lines around tables and fenced code blocks so Markdown remains parseable.
- In tables, use inline math where possible. Avoid multiline display math inside cells.
- Save Markdown as UTF-8 and reject control characters or replacement characters.

## Evidence and claim discipline

- Distinguish exact derivation, fitted-model inference, sampled-frequency verification, sufficient conditions, simplified assumptions, and time-domain validation.
- Do not convert a numerical observation into an analytical proof.
- Do not claim global stability, passivity, causality, or universality beyond the established frequency range, parameter range, model order, or assumptions.
- When reporting fitted poles or zeros, state the fitted object, coordinate transformation, fitting order, stability constraint setting, frequency range, tolerance, and convergence evidence.

## Minimum acceptance checks

- Even and correctly nested `$`/`$$` delimiters.
- No `\(...\)` delimiters.
- Balanced braces and matched LaTeX environments.
- Exactly one unique display tag per required block; sequential suffixes when the scheme is numeric.
- No malformed `^_` sequence or single matrix-row slash.
- Textual subscripts use `\text{...}`; true indices remain mathematical.
- Imaginary units and units use upright notation.
- Code fences are even and code content is unchanged.
- Actual target is read back after any repair; backup and SHA-256 are reported.
