# luvit-sax

This is an experimental implementation of SAX parser for luvit.

Currently, this is a proof of concept for an application of luvit-hsm.
Interconnected state machines are working cooperatively with events.

And the parser works well with luvit's non-blocking IO model.
The parser can take partial inputs, need not to take whole input at once.

## TODO
### near
* entity reference
* support all characters in NameStartChar and NameChar

### far (maybe)
* validation
* namespace

## LICENSE

MIT license, for more info see [LICENSE](https://raw.github.com/hnakamur/luvit-sax/master/LICENSE).
