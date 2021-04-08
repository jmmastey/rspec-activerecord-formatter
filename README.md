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

Normal bundle stuff. You'll almost certainly need to add this gem to your
bundle at least temporarily, since you'll be running rspec using bundler.

    gem 'rspec-activerecord-formatter', require: false


Usage
------------

The current answer is to change your `.rspec` initializer to include the following:

    --require rspec-activerecord-formatter
    --require rails_helper
    --format ActiveRecordDocumentationFormatter

We have to include the rails_helper so that ActiveRecord is loaded prior to trying to load the
formatter. That way, we can hook into AR creations.

You can also run the formatter as a one-off option to rspec:

    rspec path/to/example_spec.rb --require rspec-activerecord-formatter --require rails_helper --format ActiveRecordDocumentationFormatter

Once you set the formatter, you should now see the number of objects created and total queries
for each of your tests:

![Tests with AR annotations.](https://github.com/jmmastey/rspec-activerecord-formatter/raw/master/doc/images/demo_2.png "Tests with AR annotations.")

You'll also get a summary at the end of your test run:

![Test summary.](https://github.com/jmmastey/rspec-activerecord-formatter/raw/master/doc/images/demo_1.png "Test summary.")

The formatter will spit out a report with more data at the end of your run:


If you want less granularity, you can also use the progress formatter:

    --require rspec-activerecord-formatter
    --require rails_helper
    --format ActiveRecordProgressFormatter

Contributing
------------

Contributions are very welcome. Fork, fix, submit pulls.

Contribution is expected to conform to the [Contributor Covenant](https://github.com/jmmastey/rspec-activerecord-formatter/blob/master/CODE_OF_CONDUCT.md).

License
------------

This software is released under the [MIT License](https://github.com/jmmastey/rspec-activerecord-formatter/blob/master/MIT-LICENSE).
