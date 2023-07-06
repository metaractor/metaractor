![logo-color](https://user-images.githubusercontent.com/146013/225313017-ea1e42d6-741d-4db6-a492-a1e75106d720.png)

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

result = HighFiveUser.call # not passing user or user_id
result.failure?
# => true
result.valid?
# => false
result.error_messages
# => ["Required parameters: (user_id or user)"]
```

See Interactor's [README](https://github.com/collectiveidea/interactor/blob/master/README.md) for more information.

### Configuration
Metaractor is meant to be extensible (hence the 'meta').  You can add additional modules in the following way:

```ruby
# This is an example from a production app to add some sidekiq magic.
# Feel free to place this in start up code or a Rails initializer.
Metaractor.configure do |config|
  config.prepend_module Metaractor::SidekiqCallbacks
  config.include_module Metaractor::SidekiqBatch
end
```

### Required Parameters
Metaractor supports complex required parameter statements and you can chain these together in any manner using `and`, `or`, and `xor`.
```ruby
required and: [:token, or: [:recipient_id, :recipient] ]
```

You can also mark a parameter as required with the `required` option:
```ruby
parameter :user, required: true
```

### Optional Parameters
As optional parameters have no enforcement, they are merely advisory.
```ruby
optional :enable_logging
```

### Parameter Options
Metaractor supports arbitrary parameter options. The following are currently built in.
Note that you can specify a block of `required` or `optional` parameters and then use
`parameter` or `parameters` to add options to one or more of them.

#### Skipping Blank Parameter Removal
By default Metaractor removes blank values that are passed in. You may skip this behavior on a per-parameter basis:
```ruby
parameter :name, allow_blank: true
```

You may check to see if a parameter exists via `context.has_key?`.

#### Default Values
You can specify a default value for a parameter:
```ruby
optional :role, default: :user
```

This works with `allow_blank` and can also be anything that responds to `#call`.
```ruby
parameter :role, allow_blank: true, default: -> { context.default_role }
```

#### Typecasting/Coersion
You can supply Metaractor with a callable that will typecast incoming parameters:
```ruby
optional :needs_to_be_a_string, type: ->(value) { value.to_s }
```

You can also configure Metaractor with named types and use them:
```ruby
Metaractor.configure do |config|
  config.register_type(:boolean, ->(value) { ActiveModel::Type::Boolean.new.cast(value) })
end
```
```ruby
required :is_awesome, type: :boolean
```

**Note**: Typecasters will _not_ be called on `nil` values.

### Custom Validation
Metaractor supports doing custom validation before any user supplied before_hooks run.
```ruby
validate_parameters do
  if context.foo == :bar
    require_parameter :bar, message: 'optional missing parameter message'
  end

  unless context.user.admin?
    add_parameter_error param: :user, message: 'User must be an admin'
  end
end
```

If you need to require a parameter from a `before_hook` for any reason, use the bang version of the method:
```ruby
before do
  # Be careful with this approach as some user code may run before the parameter validation
  require_parameter! :awesome if context.mode == :awesome
end
```

### Structured Errors
As of v2.0.0, metaractor supports structured errors.
```ruby
class UpdateUser
  include Metaractor

  optional :is_admin
  optional :user

  def call
    fail_with_error!(
      errors: {
        base: 'Invalid configuration',
        is_admin: 'must be true or false',
        user: [ title: 'cannot be blank', username: ['must be unique', 'must not be blank'] ]
      }
    )
  end
end

result = UpdateUser.call
result.error_messages
# => [
#      'Invalid configuration',
#      'is_admin must be true or false',
#      'user.title cannot be blank',
#      'user.username must be unique',
#      'user.username must not be blank'
#    ]

result.errors.full_messages_for(:user)
# => [
#      'title cannot be blank',
#      'username must be unique',
#      'username must not be blank'
#    ]

# The arguments to `slice` are a list of paths.
# In this case we're asking for the errors under `base` and also
# the errors found under user _and_ title.
result.errors.slice(:base, [:user, :title])
# => {
#      base: 'Invalid configuration',
#      user: { title: 'cannot be blank' }
#    }

result.errors.to_h
# => {
#      base: 'Invalid configuration',
#      is_admin: 'must be true or false',
#      user: {
#        title: 'cannot be blank',
#        username: ['must be unique', 'must not be blank']
#      }
#    }
```

### I18n
As of v3.0.0, metaractor supports i18n along with structured errors.
```ruby
module Users
  class UpdateUser
    include Metaractor

    optional :is_admin
    optional :user

    def call
      fail_with_error!(
        errors: {
          base: :invalid_configuration,
          is_admin: :true_or_false,
          user: [ title: :blank, username: [:unique, :blank] ]
        }
      )
    end
  end
end
```

Locale:
```yaml
en:
  errors:
    parameters:
      invalid_configuration: 'Invalid configuration'
      blank: '%{parameter} cannot be blank'
      unique: '%{parameter} must be unique'

      users:
        is_admin:
          true_or_false: 'must be true or false'
      user:
        username:
          unique: 'Username has already been taken'
```

Metaractor will attempt to use the namespace of the code that reported the error.
You can see that above with the `users` key in the locale.

The i18n integration will walk its way from the most specific message to the least specific one, stopping at the first one it can find.
We currently expose the following variables for use in the message:
- `error_key`: the error we added (ex: `blank` or `invalid_configuration`)
- `parameter`: the name of the parameter

You can also use this feature to work with machine readable keys:
```ruby
result = Users::UpdateUser.call
if result.failure? &&
  result.errors[:is_admin].include?(:true_or_false)

  # handle this specific case
end
```

### Spec Helpers
Enable the helpers and/or matchers:
```ruby
RSpec.configure do |config|
  config.include Metaractor::Spec::Helpers
  config.include Metaractor::Spec::Matchers
end
```

#### Helpers
- `context_creator`
```ruby
# context_creator(error_message: nil, error_messages: [], errors: [], valid: nil, invalid: nil, success: nil, failure: nil, **attributes)

# Create a blank context:
context_creator

# Create a context with some data:
context_creator(message: message, user: user)

# Create an invalid context:
context_creator(error_message: "invalid context", invalid: true)

# Create a context with string errors:
context_creator(error_messages: ["That didn't work", "Neither did this"])

# Create a context with structured errors:
context_creator(
  user: user,
  errors: {
    user: {
      email: 'must be unique'
    },
    profile: {
      first_name: 'cannot be blank'
    }
  }
)
```

#### Matchers
- `include_errors`
```ruby
result = context_creator(
  errors: {
    user: [
      title: 'cannot be blank',
      username: ['must be unique', 'must not be blank']
    ]
  }
)

expect(result).to include_errors(
  'username must be unique',
  'username must not be blank'
).at_path(:user, :username)

expect(result).to include_errors('user.title cannot be blank')
```

### Hash Formatting
Metaractor customizes the output for `Metaractor::Errors#inspect` and `Interactor::Failure`:
```
Interactor::Failure:
       Errors:
       {:base=>"NOPE"}

       Previously Called:
       Chained

       Context:
       {:parent=>true, :chained=>true}
```

You can further customize the hash formatting:
```ruby
Metaractor.configure do |config|
  # Configure Metaractor to use awesome_print
  config.hash_formatter = ->(hash) { hash.ai }
end
```

### Further Reading
For more examples of all of the above approaches, please see the specs.

## Development

- Install nix:
```sh
sh <(curl -L https://nixos.org/nix/install)
```

- Configure nix:
```sh
sudo tee -a /etc/nix/nix.conf <<EOF
auto-optimise-store = true
bash-prompt-prefix = (nix:$name)\040
experimental-features = nix-command flakes
extra-nix-path = nixpkgs=flake:nixpkgs
trusted-users = root $USER
EOF

sudo pkill nix-daemon
```

- Set up cachix:
```sh
nix profile install 'nixpkgs#cachix'
cachix use devenv
```

- Install devenv:
```sh
nix profile install --accept-flake-config github:cachix/devenv/latest
```

- Install direnv:
```sh
brew install direnv
```

- Add the following lines to your ~/.zshrc:
```sh
# Nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
# End Nix

export DIRENV_LOG_FORMAT=
eval "$(direnv hook zsh)"
```

- `direnv allow`
- `rspec spec` to run specs

To release a new version:
- Update the version number in `version.rb` and commit the result.
- `rake release`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/metaractor/metaractor.

