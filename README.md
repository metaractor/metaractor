# Metaractor
Adds parameter validation and error control to [interactor](https://github.com/collectiveidea/interactor).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'metaractor'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install metaractor

## Usage
```ruby
class HighFiveUser
  include Metaractor

  required or: [:user_id, :user]

  before do
    context.user ||= User.find(context.user_id)
    context.user_id ||= context.user.id
  end

  def call
    context.user.update_attributes!(high_five: true)
    # If using rails, you can add private delegates for required parameters.
    # user.update_attributes!(high_five: true)
  end

  # private
  # delegate :user, to: context
end
```

See Interactor's [README](https://github.com/collectiveidea/interactor/blob/master/README.md) for more information.

Metaractor is meant to be extensible (hence the 'meta').  You can add additional modules in the following way:

```ruby
# This is an example from Outstand's production app to add some sidekiq magic.
# Feel free to place this in start up code or a Rails initializer.
Metaractor.configure do |config|
  config.prepend_module Metaractor::SidekiqCallbacks
  config.include_module Metaractor::SidekiqBatch
end
```

## Development

- `docker build -t outstand/metaractor .`
- `docker run -it --rm -v $(pwd):/metaractor outstand/metaractor` to run specs

To release a new version:
- Update the version number in `version.rb` and commit the result.
- `docker build -t outstand/metaractor .`
- `docker run -it --rm -v ~/.gitconfig:/home/metaractor/.gitconfig -v ~/.gitconfig.user:/home/metaractor/.gitconfig.user -v ~/.ssh/id_rsa:/home/metaractor/.ssh/id_rsa -v ~/.gem:/home/metaractor/.gem outstand/metaractor rake release`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/outstand/metaractor.

