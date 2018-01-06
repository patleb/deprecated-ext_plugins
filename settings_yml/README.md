# SettingsYml

### Installation

As a global gem:

    $ gem install settings_yml

In your `Gemfile`:

```ruby
# Gemfile

gem 'settings_yml'
```

### Usage

#### Rails

Create a `settings.yml` in your project `config` directory:

```yaml
# app_root/config/settings.yml

shared:
  name_1: value_1

development:
  name_2: value_2

production:
  name_2: value_3
```

and access your settings through the `SettingsYml` class:

```ruby
SettingsYml[:name_1] # => 'value_1'
```

#### Ruby

For a ruby script outside of the Rails context, but running at the root of the project,
you must specify the environment either by passing it as `env` parameter to `with`:

```ruby
require 'settings_yml'

settings = SettingsYml.with(env: fetch(:stage))

settings['name]      # => 'value'

SettingsYml['name']  # => 'value'
```

or to `RAILS_ENV` environment variable on the command line:

    $ RAILS_ENV=production ruby_script

If the script is running outside of the project root,
then the project path must be specified either by passing it as `root` parameter to `with`:

```ruby
SettingsYml.with(env: stage, root: '/path/to/base/dir')
```

or to `RAILS_ROOT` environment variable on the command line:

    $ RAILS_ENV=production RAILS_ROOT=/path/to/base/dir ruby_script

### Settings in gems

#### Rails

It is possible to reference gems that might have some shared settings with the project
by specifying them with the `gems` key within the project `settings.yml`

```yaml
# app_root/config/settings.yml

shared:
  gems:
    - gem_name
    - other_gem_name
```

```yaml
# gem_name/config/settings.yml

development:
  key: value1

production:
  key: value2
```

#### Ruby

For a ruby script outside of the Rails context, `SettingsYml` should be configured
through the method `with_clean_env`, even if `env` and `root` are passed by
the command line:

```ruby
SettingsYml.with_clean_env

SettingsYml[:key]    # => 'value_2'
```

The reason being that there is no easy way to be sure that the gems loaded within the
script are the same as the ones in project and `with_clean_env` will run
`bundle show gem_name` at the root of the project to find the correct path.

If you do not configure through `with_clean_env`, you must run your script
at the root of the project with a `bundle exec`:

    $ bundle exec bin/ruby_script

That way, you project gems will be available to your script.

### Files loaded (merged in that order for the *.yml)

* `/.../app_root/config/secrets.yml` if it exists

* `/.../app_root/config/database.yml` if it exists and keys will be scoped with a `db_` prefix

* `/.../any/gem_root/config/settings.yml` if it exists in the `gem`

* `/.../app_root/config/settings.yml`

### Database secrets

In case you want to keep your production `database.yml` values within your `secrets.yml`,
it can be done like this:

```ruby
# app_root/config/database.yml

production:
  database: <%= Rails.application.secrets.db_database %>
  username: <%= Rails.application.secrets.db_username %>
  password: <%= Rails.application.secrets.db_password %>
```

```ruby
# app_root/config/secrets.yml

production:
  db_database: name
  db_username: user
  db_password: pwd
```

It is important to note, that the `database.yml` file isn't parsed as ERB,
this syntax is merely to allow the usage outside the Rails context.

So any other tags different from `<%= Rails.application.secrets.config_name[:nested_config] %>` won't be parsed.

### Encrypted secrets

You can keep encrypted secrets in `settings.yml`, but a `secret_key_base` must be defined in `secrets.yml`.
Available rake tasks to help encrypt/decrypt with the first argument as the environment are:

    $ rake settings_yml:encrypt[production,'file/path']

    $ rake settings_yml:encrypt[production] DATA='newline-escaped-data'

    $ rake settings_yml:decrypt[production,key_name]

    $ rake settings_yml:decrypt[production,key_name,'file/path']

### Version lock

The current loaded `SettingsYml::VERSION` and the `lock` key in your project `settings.yml` must match,
otherwise an error is raised.

```yaml
# app_root/config/settings.yml

shared:
  lock: 2.5.0
```

### Alias

The alias `all` is available as an alternative to `with` if the name is more appropriate to the context.

### License

This project rocks and uses MIT-LICENSE.
