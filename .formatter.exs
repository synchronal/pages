# Used by "mix format"
[
  inputs: [
    "CHANGELOG.md",
    "LICENSE.md",
    "{config,lib,test}/**/*.{ex,exs}",
    "{mix,.formatter,.credo}.exs"
  ],
  line_length: 120,
  markdown: [line_length: 120],
  plugins: [MarkdownFormatter]
]
