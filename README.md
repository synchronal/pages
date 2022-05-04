# Pages

[![CI](https://github.com/synchronal/pages/actions/workflows/tests.yml/badge.svg)](https://github.com/synchronal/pages/actions)
[![Hex pm](http://img.shields.io/hexpm/v/pages.svg?style=flat)](https://hex.pm/packages/pages)

A Page Object pattern for interacting with websites. This library can be used to
facilitate testing of Phoenix controllers and LiveView pages in the context of ExUnit,
and may be used as the basis of other drivers.

**Note**: prior to the release of `1.0.0`, minor releases of this library may include
breaking changes. While new, this library is undergoing rapid development. A goal is
to reach a stable API and a `1.0.0` release as soon as possible.

## Installation

```elixir
def deps do
  [
    {:pages, "~> 0.1.0", only: :test}
  ]
end
```


