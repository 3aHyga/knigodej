# Knigodej

[![Dependency Status](https://gemnasium.com/3aHyga/knigodej.png)](https://gemnasium.com/3aHyga/knigodej)
[![Gem Version](https://badge.fury.io/rb/knigodej.png)](http://badge.fury.io/rb/knigodej)
[![Build Status](https://travis-ci.org/3aHyga/knigodej.png?branch=master)](https://travis-ci.org/3aHyga/knigodej)
[![Coverage Status](https://coveralls.io/repos/3aHyga/knigodej/badge.png)](https://coveralls.io/r/3aHyga/knigodej)
[![Endorse Count](http://api.coderwall.com/3aHyga/endorsecount.png)](http://coderwall.com/3aHyga)

Knigodej gem is a tool to make a PDF, and DJVU books from the XCF (GIMP image) source images.
Now, only two or many layered XCF images are allowed.

## Installation

Add this line to your application's Gemfile:

    gem 'knigodej', :git => 'git@github.com:3aHyga/knigodej.git'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install knigodej

## Usage

### API

Here is how to use the Knigodej's API:

    dir = 'books/pdfdjvu'
    schema = 'books/schema.bs.yml'
    specbook = 'Specfied Book 1'
    
    settings = YAML::load( open schema )
    basepath = File.dirname( schema )
    bs = BookShelf.new settings, basepath
    bs.make dir, specbook

### Scheme

To build a book thou requirest the book shelf schema file. It is a YAML-config file composed in cyrillic (for now). Sample schema is shewn below:

    ---
    къбукы: path/to/texts
    наборы:
      - Scribings 1
      - Scribings 2
    главы:
      1: Chapter 1
      15: Chapter 2
    разделы:
      1: Section 1
      2: Section 2
      15: Section 1
    книги:
      Specified Book 1:
        авторы:
          - Author Name 1
          - Author Name 2
        предмет: Subject
        ключевые слова:
          - keyword 1
          - keyword 2
        создатель: Creator Name
        страницы:
          - 1.1.1-4
          - 1.2.1-3
          - 2.15.1

It is applied to file structure that resided itself along the path specified in 'къбукы' parameter: _path/to/texts_. The file structire is shewn below:

    /
     \Scribings 1
      \1
       \1.01. Scribing Page. 0001.xcf
       \1.01. Scribing Page. 0002.xcf
       \1.01. Scribing Page. 0003.xcf
       \1.01. Scribing Page. 0004.xcf
      \2
       \1.02. Scribing Page. 0001.xcf
       \1.02. Scribing Page. 0002.xcf
       \1.02. Scribing Page. 0003.xcf
     \Scribings 2
      \15
       \
        \2.15. Scribing Page. 0001.xcf

The filename in the strcuture consists in follows:

    <chapter index>.<section index>. Page Name. <4 index digits>.xcf

### Binary

Here is how to use the Knigodej's binary file. I order to get help issue the following in a command line, and thou wilst get the answer shewn below, which is the help of the knigodej binary:

    $ bin/knigodej -h
    This is a knigodej script, how to use it see below
        -v, --verbose 1                  enable verbose output, values: 0 to 5
        -s, --schema                     set bookshelf schema YAML-file to proceed
        -b, --book                       make a book specified by name
        -d, --dir                        set base dir to store results
        -l, --log                        set output flow to a file
        -h, --help                       Show this message
        -V, --version                    Print version

Sample run of the knigodej script with the schema file that is shewn above:

    $ bundle exec bin/knigodej -v 5 -s path/to/book/shelf/newbooks.bs.yml -b "Specific Book 1"

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

