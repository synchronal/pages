# Pages

[![CI](https://github.com/synchronal/pages/actions/workflows/tests.yml/badge.svg "CI")](https://github.com/synchronal/pages/actions)
[![Hex pm](http://img.shields.io/hexpm/v/pages.svg?style=flat "Hex version")](https://hex.pm/packages/pages)
[![API docs](https://img.shields.io/hexpm/v/pages.svg?label=hexdocs "API docs")](https://hexdocs.pm/pages/Pages.html)
[![License](http://img.shields.io/github/license/synchronal/pages.svg?style=flat "License")](https://github.com/synchronal/pages/blob/main/LICENSE.md)

_Pages_ is a tool for testing Phoenix web applications purely in fast asynchronous Elixir tests, without the need for a
web browser. It can seamlessly move between LiveView-based pages (via
[Phoenix.LiveViewTest](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html)) and controller-based pages
(via [Phoenix.ConnTest](https://hexdocs.pm/phoenix/Phoenix.ConnTest.html)), so web tests are as fast as all other unit
tests.

Pages has been used for testing multiple applications over the past 2+ years without much need for API changes.

This library is tested against the latest 3 major versions of Elixir.

## Sponsorship 💕

This library is part of the [Synchronal suite of libraries and tools](https://github.com/synchronal)
which includes more than 15 open source Elixir libraries as well as some Rust libraries and tools.

You can support our open source work by [sponsoring us](https://github.com/sponsors/reflective-dev).
If you have specific features in mind, bugs you'd like fixed, or new libraries you'd like to see,
file an issue or contact us at [contact@reflective.dev](mailto:contact@reflective.dev).

## Quick Overview

### Interacting With A Web App

The `Pages.new/1` function creates a new `Pages.Driver` struct from the conn, and most of the rest of the `Pages`
functions expect that driver to be passed in as the first argument and will return that driver:

```elixir
profile_page =
  conn
  |> Pages.new()
  |> Pages.visit(Web.Paths.auth())
  |> Pages.submit_form("[test-role=auth]", :user, name: "alice", password: "password1234")
  |> Pages.click("[test-role=my-profile-button]")

# `profile_page` now references a `Pages.Driver.LiveView` struct.
```

(Curious about `Web.Paths.auth()` above? Read this article: [Web.Paths](https://eahanson.com/articles/web-paths).)

See Pages' [API reference](https://hexdocs.pm/pages/api-reference.html) for more info, specifically the docs for the
[Pages](https://hexdocs.pm/pages/Pages.html) module.

### Finding Elements On A Page

Instead of having a bespoke API for parsing HTML, Pages allows you to use your favorite HTML parsing
library.

We naturally recommend the one we built: [`HtmlQuery`](https://hexdocs.pm/html_query/readme.html). It and its XML
counterpart [`XmlQuery`](https://hexdocs.pm/xml_query/readme.html) have the same concise API. The main functions are:
`all/2`, `find/2`, `find!/2`, `attr/2`, and `text/1`.

You can use a different library or your own code. The drivers (`Pages.Driver.Conn` and `Pages.Driver.LiveView`)
implement the `String.Chars` protocol, so you can call `to_string/0` on any page to get its rendered result.

Here's an example of using `HtmlQuery` to get all the email addresses from the `profile_page`:

```elixir
alias HtmlQuery, as: Hq

# ...

email_addresses =
  dashboard_page
  |> Hq.all("ul[test-role=email-addresses] li")
  |> Enum.map(&Hq.text/1)

assert email_addresses == ["alice@example.com", "alice@example.net"]
```

## Optional: Taming Complexity With The Page Object Pattern

In a large web application, test complexity becomes an issue. One way to solve web test complexity is by using
the [Page Object](https://martinfowler.com/bliki/PageObject.html) pattern for encapsulating each page's content,
actions, and assertions in its own module.

Using the Pages library does not require implementing the page object pattern, and implementing the page object
pattern doesn't necessitate using the Pages library. However, we find it to be an extremely effective way to keep
tests simple so we'll provide an example of implementing the pattern with Pages.

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

### The Context

If you have information you'd like to keep while stepping through multiple pages, you can assign it to the
context from functions like `Pages.new` and `Pages.visit`:

```elixir
page =
  conn
  |> Pages.visit("/live/form", some_key: "some_value")
  |> Pages.update_form("#form", foo: [action: "redirect"])
  |> assert_here("pages/show")

assert page.context == %{some_key: "some_value"}
```

## Installation

```elixir
def deps do
  [
    {:pages, "~> 3.4", only: :test}
  ]
end
```

Configure your endpoint in `config/test.exs`:

```elixir
config :pages, :phoenix_endpoint, Web.Endpoint
```

## Alternatives

The relatively recent [`phoenix_test`](https://github.com/germsvel/phoenix_test) library is similar in that it handles
controller- and LiveView-based tests. Its API style is quite different that Pages' API.

For tests that run in a real browser, the venerable [`Wallaby`](https://github.com/elixir-wallaby/wallaby) is
the only production-ready choice at the moment.

[`playwright-elixir`](https://github.com/mechanical-orchard/playwright-elixir) is an Elixir driver for Playwright.
Its readme says that "the features are not yet at parity with other Playwright implementations" but it might be
worth checking out.


## Under the hood

This library uses functions from [Phoenix.ConnTest](https://hexdocs.pm/phoenix/Phoenix.ConnTest.html) and
from [Phoenix.LiveViewTest](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html) to simulate a user clicking
around and therefore can't test any Javascript functionality. To fix this, a driver for browser-based testing via
[Wallaby](https://github.com/elixir-wallaby/wallaby) or
[Playwright Elixir](https://github.com/geometerio/playwright-elixir) would be needed, but one does not yet exist. The
upside is that Pages-based tests are extremely fast.
