# Pages

[![CI](https://github.com/synchronal/pages/actions/workflows/tests.yml/badge.svg "CI")](https://github.com/synchronal/pages/actions)
[![Hex pm](http://img.shields.io/hexpm/v/pages.svg?style=flat "Hex version")](https://hex.pm/packages/pages)
[![API docs](https://img.shields.io/hexpm/v/pages.svg?label=hexdocs "API docs")](https://hexdocs.pm/pages/Pages.html)
[![License](http://img.shields.io/github/license/synchronal/pages.svg?style=flat "License")](https://github.com/synchronal/pages/blob/main/LICENSE.md)

An Elixir implementation of the [Page Object](https://martinfowler.com/bliki/PageObject.html) pattern for interacting
with websites. This library can be used to facilitate testing of Phoenix controllers and LiveView pages in the context
of ExUnit, and may be used as the basis of other drivers.

**Note**: prior to the release of `1.0.0`, minor releases of this library may include
breaking changes. While new, this library is undergoing rapid development. A goal is
to reach a stable API and a `1.0.0` release as soon as possible.

See the [API reference](https://hexdocs.pm/pages/api-reference.html) for more info, specifically the docs for the
[Pages](https://hexdocs.pm/pages/Pages.html) module.

## Installation

```elixir
def deps do
  [
    {:pages, "~> 0.5", only: :test}
  ]
end
```

## Usage

The typical usage is to create a module for each page of your web app, with functions for each action that a user can
take on that page, and then to call those functions in a test. Note that in this example, `Web` and `Test` are
top-level modules in the app that's being tested.

```elixir
defmodule Web.HomeLiveTest do
  use Test.ConnCase, async: true
  
  test "has login button", %{conn: conn} do
    conn
    |> Pages.new()
    |> Test.Pages.HomePage.assert_here()
    |> Test.Pages.HomePage.click_login_link()
    |> Test.Pages.LoginPage.assert_here()
  end
end
```

Here is the definition of the `HomePage` module that's used in the test above. This test uses `assert_eq/3` from the
[Moar](https://hexdocs.pm/moar/Moar.Assertions.html#assert_eq/3) library, and `find/2` & `attr/2` from the
[HtmlQuery](https://hexdocs.pm/html_query/HtmlQuery.html) library.

```elixir
defmodule Test.Pages.HomePage do
  import Moar.Assertions
  alias HtmlQuery, as: Hq

  @spec assert_here(Pages.Driver.t()) :: Pages.Driver.t()
  def assert_here(%Pages.Driver.LiveView{} = page) do
    page
    |> Hq.find("[data-page]")
    |> Hq.attr("data-page")
    |> assert_eq("home", returning: page)
  end

  @spec click_login_link(Pages.Driver.t()) :: Pages.Driver.t()
  def click_login_link(page),
    do: page |> Pages.click("Log In", test_role: "login-link")

  @spec visit(Pages.Driver.t()) :: Pages.Driver.t()
  def visit(page),
    do: page |> Pages.visit("/")
end
```

A page module that you define can work with either a controller-based page or a LiveView-based page, and a test can
test workflows that use both controllers and LiveViews.


## Under the hood

This library uses functions from [Phoenix.ConnTest](https://hexdocs.pm/phoenix/Phoenix.ConnTest.html) and
from [Phoenix.LiveViewTest](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html) to simulate a user clicking
around and therefore can't test any Javascript functionality. To fix this, a driver for browser-based testing via
[Wallaby](https://github.com/elixir-wallaby/wallaby) or
[Playwright Elixir](https://github.com/geometerio/playwright-elixir) would be needed, but one does not yet exist. The
upside is that Pages-based tests are extremely fast.





