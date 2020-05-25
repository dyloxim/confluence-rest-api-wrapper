# Confluence REST API Wrapper

## Overview
This is an API for the confluence REST API. It is written to be used within a ruby REPL environment.

## Example

```ruby
$ pry -I . -r /setup.rb
[1] pry(main)> CM = ConfluenceManager.new('production_profile')
=> #<ConfluenceManager:0x00007fd8dba987e0 @profile_name="prod">

[2] pry(main)> page = CM.search('title = "wrong title"').first
TASK INFO: [get] request to '/rest/api/content/search' returned 200 response code.
=> #<Page:0x00007fd8dbb2a820 @cached={}, @id="199692279", @profile_name="prod", @title="bad title">

[3] pry(main)> page.title = 'right title'
TASK INFO: [get] request to '/rest/api/content/199692279' returned 200 response code.
TASK INFO: [put] request to '/rest/api/content/199692279' returned 200 response code.
=> "right title"
```

## Requirements
* Ruby version >=2.7
* Pry version >=0.13
* bundler version >=2.1.4

Note: I had some trouble getting Pry (ruby REPL environment) to use the correct ruby version, but using rvm sorted this out for me.

## Usage
First, clone this repo, run `bundle install` to get the dependencies, then make a new file in the root directory called `profiles.yml`.

Define the profile/profiles you will use to interact with the confluence REST API here.

Example:
```
---
production_profile: {
  confluence_instance: 'https://root.domain.of.your.confluence.instance',
  credentials: {
    username: 'your_username',
    password: 'your_password'
    },
  space: 'PROD'
  }
development_profile: {
  confluence_instance: 'https://root.domain.of.your.confluence.instance',
  credentials: {
    username: 'your_username',
    password: 'your_password'
    },
  space: 'DEV'
  }
```

With profiles defined you can then either write a script that which uses the API - creating the file in the root of this directory (by just including the line `include `./setup.rb` at the top of the file), or you can load up an interactive session with Pry, like so:

```
$ pry -I . -r ./setup.rb
```

And then run commands one at a time and see their results.

## Reference Manual

TODO: add documentation of all the available methods for creating/reading/uploading/deleting pages & other assets with this API.
