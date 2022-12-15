# Changelog

## Unreleased changes

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
