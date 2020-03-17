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

result = HighFiveUser.call # not passing user or user_id
result.failure?
# => true
result.valid?
# => false
result.errors
# => ["Required parameters: (user_id or user)"]
```

See Interactor's [README](https://github.com/collectiveidea/interactor/blob/master/README.md) for more information.

### Configuration
Metaractor is meant to be extensible (hence the 'meta').  You can add additional modules in the following way:

```ruby
# This is an example from Outstand's production app to add some sidekiq magic.
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

### Optional Parameters
As optional parameters have no enforcement, they are merely advisory.
```ruby
optional :enable_logging
```

### Skipping Blank Parameter Removal
By default Metaractor removes blank values that are passed in. You may skip this behavior on a per-parameter basis:
```ruby
allow_blank :name
```

You may check to see if a parameter exists via `context.has_key?`.

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

### Further Reading
For more examples of all of the above approaches, please see the specs.

## Development

- `docker-compose build --pull`
- `docker-compose run --rm metaractor` to run specs

To release a new version:
- Update the version number in `version.rb` and commit the result.
- `docker-compose build --pull`
- `docker-compose run --rm release`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/outstand/metaractor.

