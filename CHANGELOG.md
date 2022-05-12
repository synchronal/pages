# Changelog

## Unreleased changes

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
