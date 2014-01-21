# fluent-plugin-reemit

[![Build Status](https://secure.travis-ci.org/sonots/fluent-plugin-reemit.png?branch=master)](http://travis-ci.org/sonots/fluent-plugin-reemit)

Fluentd plugin to re-emit messages avoiding infinity match loop

## Installation

Use RubyGems:

    gem install fluent-plugin-reemit

## Configuration

Example:

This example applies [flowcounter](https://github.com/tagomoris/fluent-plugin-flowcounter) plugin for all messages, then re-emit messages.
But, the re-emitted messages will skip the identical match directive (the first one) to avoid an infinity loop. 

```apache
<match flowcount>
  type stdout
</match>

<match **>
  type copy
  <store>
    type flowcounter
    count_keys *
  </store>
  <store>
    type reemit
  </store>
</match>

<match **>
  type stdout
</match>
```

## Option Parameters

None

## ChangeLog

See [CHANGELOG.md](CHANGELOG.md) for details.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new [Pull Request](../../pull/new/master)

## Copyright

Copyright (c) 2013 Naotoshi Seo. See [LICENSE](LICENSE) for details.
