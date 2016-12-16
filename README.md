RSpec Active Record Formatter
=============

Adds a new formatting option to rspec that counts your ActiveRecord queries
and object creations.

Why? Because database interaction is really slow, and careless creation of large
graphs of objects is a primary cause of insanely slow test suites. This project
can help you diagnose where you're doing the most damage so that you can
start to fix it.

This library plays nicely with DatabaseCleaner.

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

Once you set the formatter, you should now see the number of objects created and total queries
for each of your tests:

![Tests with AR annotations.](https://github.com/jmmastey/rspec-activerecord-formatter/raw/master/doc/images/demo_2.png "Tests with AR annotations.")

You'll also get a summary at the end of your test run:

![Test summary.](https://github.com/jmmastey/rspec-activerecord-formatter/raw/master/doc/images/demo_1.png "Test summary.")

Next Steps
------------
* The method I was using to count AR objects doesn't work well with DatabaseCleaner when not explicitly wiring the library into `before` blocks.
  I'd like to be able to go back to a method other than scanning for `INSERT INTO` strings.
* Configuration, especially of the aligning of the metric output (to outdent it optionally).
* Add a `--profile`-like behavior to output the most offending tests.
* Current dependencies are a vague guess. They could clearly be more lenient, but I don't have time at the moment to look into which version of ActiveSupport, for instance, is required.
* I dunno, tests.

Contributing
------------

Contributions are very welcome. Fork, fix, submit pulls.

Contribution is expected to conform to the [Contributor Covenant](https://github.com/jmmastey/rspec-activerecord-formatter/blob/master/CODE_OF_CONDUCT.md).

License
------------

This software is released under the [MIT License](https://github.com/jmmastey/rspec-activerecord-formatter/blob/master/MIT-LICENSE).
