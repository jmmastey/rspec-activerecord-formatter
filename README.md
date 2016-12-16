RSpec Active Record Formatter
=============

Adds a new formatting option to rspec that counts your ActiveRecord queries
and object creations.

Why? Because database interaction is really slow, and careless creation of large
graphs of objects is a primary cause of insanely slow test suites. This project
can help you diagnose where you're doing the most damage so that you can
start to fix it.

Installation
------------

Normal bundle stuff.

    gem rspec-activerecord-formatter


Usage
------------

The current answer appears to be changing your `.rspec` initializer to include the following:

      --require rails_helper
      --format ActiveRecordFormatter

We have to include the rails_helper so that ActiveRecord is loaded prior to trying to load the
formatter. That way, we can hook into AR creations.


Contributing
------------

Contributions are very welcome. Fork, fix, submit pulls.

Contribution is expected to conform to the [Contributor Covenant](https://github.com/jmmastey/bundler-stats/blob/master/CODE_OF_CONDUCT.md).

License
-------

This software is released under the [MIT License](https://github.com/jmmastey/bundler-stats/blob/master/MIT-LICENSE).
