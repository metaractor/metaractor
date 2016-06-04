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

## Development

- `docker build -t outstand/metaractor .`
- `docker run -it --rm -v $(pwd):/metaractor outstand/metaractor` to run specs

To release a new version:
- Update the version number in `version.rb` and commit the result.
- `docker build -t outstand/metaractor .`
- `docker run -it --rm -v ~/.gitconfig:/root/.gitconfig -v ~/.gitconfig.user:/root/.gitconfig.user -v ~/.ssh/id_rsa:/root/.ssh/id_rsa -v ~/.gem:/root/.gem outstand/metaractor rake release`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/outstand/metaractor.

