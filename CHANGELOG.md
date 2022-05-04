# Changelog

## Unrelease changes

## 0.2.0

- **Breaking change:** remove `scope` parameter in `Pages.Html`. Disambiguate `Pages.Html.find`
  into `find`, `find!`, and `all`. Finder must be called before passing into other functions
  such as `attr`.
- Add docs

## 0.1.0

- Initial release
