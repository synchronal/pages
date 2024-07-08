# Changelog

## Unreleased changes

- Allow `Pages.visit/2` to be called with a `Plug.Conn`.

## 1.0.3

- Fix documentation links to `Phoenix.LiveView` and `Phoenix.HTML`.

## 1.0.2

- Loosen version restrictions for gestalt.

## 1.0.1

- Readme updates

## 1.0.0

- Verify support for Elixir 1.17.0.
- *Breaking*: Drop support for Elixir older than 1.15.0.

## 0.14.0

- Add `Pages.handle_redirect/1` and callback in `Pages.Driver.LiveView`, for cases when `handle_info/2` may issue a
  redirect to the client.
- **Breaking change:** Drop support for Elixir 1.13.

## 0.13.4

- Retain connect params (including sessions, for instance) when redirecting from a LiveView.

## 0.13.3

- Recycle the conn when redirecting (not live_redirecting) from a LiveView.

## 0.13.2

- Update documentation for `Pages.Driver.LiveView.live_redirect/2` to note how to set up tests for live redirects to work
  between live sessions.

## 0.13.1

- Update `HtmlQuery` dependency to a new major version.

## 0.13.0

- Add `t:Pages.result/0` to reflect that any function may return an error.
- Pages return `{:error, :external, url}` when given a non-local URL.

## 0.12.0

- Add options to `Pages.update_form/5`, with ability to specify the field `:target`.

## 0.11.1

- Add necessary configuration to readme.

## 0.11.0

- When a LiveView page navigates to a controller page, `{:error, :nosession}` may be returned when accessing the page via
  LiveViewTest functions. In that case, we reinitialize our page—it comes back as a `t:Pages.Driver.Conn.t/0`.

## 0.10.1

- Ensure connect params persists through clicks and trigger actions.

## 0.10.0

- Navigating between pages automatically retains any params set via `Phoenix.LiveViewTest.put_connect_params/2`.
- Add `Pages.clear_connect_params/1` for manually resetting connect params on a page.

## 0.9.0

- `Pages.render_hook/4` includes an optional keyword of options. `target: selector` sends the event to a nested live
  component.
- LiveView page can handle a non-liveview redirect.

## 0.8.0

- `Pages.submit_form` takes an optional 5th parameter which can be used to set hidden fields.

## 0.7.1

- Conn driver automatically follows 301 redirects.

## 0.7.0

- The `title` param in `Pages.click` is now optional. Thanks Andrew!
- Added `Pages.render_hook/3` and `Pages.render_upload/4`. Thanks Andrew!

## 0.6.2

- Properly handle LiveView redirects. Thanks Andrew!

## 0.6.1

- Handle multiple redirects in a row in a LiveView.

## 0.6.0

- Add `Pages.render_change/3` which is similar to `Phoenix.LiveViewTest.render_change/2`.

## 0.5.7

- Use phoenix 1.6.14 in development to handle audit warning.
- `Pages.with_child_component/3` raises a `Pages.Error` if no child is found.

## 0.5.6

- Documentation of drivers links back towards `Pages`.

## 0.5.5

- Add text to documentation for interacting wth forms and sub-components.
- Recycle the `conn` before starting a new live view.

## 0.5.4

- Relax phoenix_live_view version restriction to allow for v0.18

## 0.5.3

- Fix callback definition for `c:Pages.Driver.click/4`.

## 0.5.2

- `Pages.click` can accept a `:post` param to click on links whose data-method is "post"

## 0.5.1

- Documentation updates.

## 0.5.0

- Add `Pages.with_child_component/3` for acting on nested live views.

## 0.4.3

- Remove unused explicit dependency on Floki.

## 0.4.2

- Support LiveView 0.17.10, and allow future updates.

## 0.4.1

- Support LiveView 0.16 as well as 0.17.

## 0.4.0

- Extract `Pages.Html` and `Pages.Css` into new `html_query` hex package.

## 0.3.1

- `Pages.Driver.LiveView` response handlers catch more cases
  - `:live_redirect` loads directly into another `Pages.Driver.LiveView`
  - `:redirect` loads calls `Pages.new/1`, as the next page may not be a live view
  - `Pages.Driver.LiveView.live_redirect/2` handles case where the next page loads.

## 0.3.0

- add `Pages.Driver.LiveView.live_redirect/2`

## 0.2.6

- add `t:Floki.html_node/1` to possible `t:Pages.Html.html/0` types.

## 0.2.5

- add `Pages.rerender` to re-render the page.

## 0.2.4

- relax compatibility requirements of `Moar` package version.

## 0.2.3

- `Pages.Driver.LiveView.visit/2` handles redirect responses.

## 0.2.2

- Update `Moar` dependency to v1.0.0.

## 0.2.1

- Replace `Euclid` dependency with `Moar`

## 0.2.0

- **Breaking change:** remove `scope` parameter in `Pages.Html`. Disambiguate `Pages.Html.find` into `find`, `find!`, and
  `all`. Finder must be called before passing into other functions such as `attr`.
- Add docs

## 0.1.0

- Initial release
