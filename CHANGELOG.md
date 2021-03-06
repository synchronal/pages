# Changelog

## Unreleased changes

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

- **Breaking change:** remove `scope` parameter in `Pages.Html`. Disambiguate `Pages.Html.find`
  into `find`, `find!`, and `all`. Finder must be called before passing into other functions
  such as `attr`.
- Add docs

## 0.1.0

- Initial release
