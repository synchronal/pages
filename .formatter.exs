# Used by "mix format"
[
  inputs: [
    "CHANGELOG.md",
    "LICENSE.md",
    "{config,lib,test}/**/*.{ex,exs}",
    "{mix,.formatter,.credo}.exs"
  ],
  line_length: 125,
  markdown: [line_length: 120],
  plugins: [Phoenix.LiveView.HTMLFormatter, MarkdownFormatter]
]
