#coding: utf-8

require "knigodej/version"
require 'mini_magick'
require 'prawn'
require 'rdoba'
require 'slavic'
Slavic.slovo

module Knigodej
   module XCF
      def self.init tmpfn, file
         xcf_image = MiniMagick::Image.open file
         bg_image = MiniMagick::Image.new tmpfn

         command = MiniMagick::CommandBuilder.new 'convert -background'
         command.push 'rgb(221,209,191)' #TODO make it changeable
         command.push '-flatten'
         command.push xcf_image.path
         command.push bg_image.path
         bg_image.run command ; end ; end

   module DJVU
      def self.xcf_page djvufn, tmpdir, tmpfn
#         log >> 'Generating DJVU page'
         outfn = File.join tmpdir, 'output.djvu'
         `cpaldjvu -dpi 150 -colors 4 '#{tmpfn}' '#{outfn}'`
         if File.exist?( djvufn )
            `djvm -c '#{djvufn}' '#{djvufn}' '#{outfn}'`
         else
            `djvm -c '#{djvufn}' '#{outfn}'` ; end ; end ; end

   module PDF
      def self.xcf_page pdf, tmpdir, tmpfn
         # Generating the PDF from .xcf
#         log >> 'Generating PDF page'
         tmp_image = MiniMagick::Image.open tmpfn
         pngfn = File.join tmpdir, 'output.png'
         png_image = MiniMagick::Image.new pngfn

         command = MiniMagick::CommandBuilder.new 'convert'
         command.push tmp_image.path
         command.push png_image.path
         tmp_image.run command

         # "A0" => [2383.94, 3370.39],
         pdf.start_new_page
         pdf.bounding_box( [0, pdf.cursor], :width => 2384, :height => 3371 ) do
            pdf.image pngfn, :fit => [2384, 3371] #TODO hardcoded remove
            end ; end ; end

   rdoba :log => { :functions => [ :info, :warn ] }, :slovo => true

   class Book
      rdoba :log => { :functions => [ :info, :warn ] }
      rdoba :mixin => [ :to_h ]

      attr_accessor :subject, :creator
      attr_reader :authors, :keywords, :pages, :name

      def make options = {}
         log + { options: options }
         log * { 'Making a book' => @name }

         pdffn = options[ :pdf ]
         djvufn = options[ :djvu ]
         if !pdffn && !djvufn
            raise "Neither PDF nor DJVU filename was specified" ; end

         isdjvu = djvufn
         if `which djvm`.empty?
            isdjvu = false ; end
         ispdf = pdffn
         log > { 'will make PDF?' => !!ispdf, 'target PDF file' => pdffn }
         log > { 'will make DJVU?' => !!isdjvu, 'target DJVU file' => djvufn }

         if isdjvu
            FileUtils.rm_f djvufn ; end

         if ispdf
            pdf = Prawn::Document.new(
                  :page_size => "A0", #TODO analyze
                  :margin => 0,
                  :info => {
                     :Title => @name,
                     :Author => @authors.join( ',' ),
                     :Subject => @subject,
                     :Keywords => @keywords.join( ',' ),
                     :Creator => @subject,
                     :Producer => "Prawn",
                     :CreationDate => Time.now } )

               # TODO add drawing title, authors, subject, and creator
               pdf.fill_color "dcd1bf"
               pdf.fill_polygon [ 0, 0 ], [ 2383, 0 ], [ 2383, 3370 ],
                     [ 0, 3370 ] ; end

         Dir.mktmpdir do |tmpdir|
            log >> { tmpdir: tmpdir }
            @pages.each_index do |i|
               xcf = @pages[ i ]
               log * { 'Processing page' => xcf }

               # 2512x3552 image size

               tmpfn = File.join tmpdir, 'output.ppm'
               begin
                  if xcf =~ /.xcf$/i
                     XCF.init tmpfn, xcf

                     if isdjvu
                        DJVU.xcf_page djvufn, tmpdir, tmpfn ; end

                     if ispdf
                        PDF.xcf_page pdf, tmpdir, tmpfn ; end ; end

               rescue
                  log.e ; end ; end

            pdf.render_file pdffn ; end

=begin
            outline.define do
            section("Section 1", :destination => 1) do
               page :title => "Page 2", :destination => 2
               page :title => "Page 3", :destination => 3
            end
            section("Section 2", :destination => 4) do
               page :title => "Page 5", :destination => 5
               section("Subsection 2.1", :destination => 6, :closed => true) do
                  page :title => "Page 7", :destination => 7
               end
            end
            end
=end
         log - {} ; end

      def authors= authors
         @authors = to_a authors ; end

      def keywords= keywords
         @keywords = to_a keywords ; end

   private

      def to_a value
         new = case value
                     when NilClass
                        []
                     when String
                        value.split(',').map {|s| s.strip }
                     when Array
                        value
                     else
                        value.to_a
                        end ; end

      def initialize name, b, path, sets
         log + { b: b, path: path, sets: sets }

         @pages = []
         if b.empty? || name.empty?
            return ; end

         @name = name
         self.authors = b[ 'авторы' ]
         self.keywords = b[ 'ключевые слова' ]
         @creator = b[ 'создатель' ]
         @subject = b[ 'предмет' ]

         (set, chapter, section) = [ nil, nil, nil ]
         b[ 'страницы' ].еже do |page|
            log > { page: page }
            if page =~ /(.*)\.(.*)\.(.*)\.(.*)/
               ( set, chapter, glas, section ) = [ $1.to_i - 1, $2.to_i, $3, $4 ]
            elsif page =~ /(.*)\.(.*)\.(.*)/
               ( set, chapter, glas, section ) = [ $1.to_i - 1, $2.to_i, nil, $3 ]
            elsif page =~ /(.*)\.(.*)/
               ( set, chapter, glas, section ) = [ $1.to_i - 1, nil, nil, $2 ]; end
            if !set
               next; end

#            dir = "./share/букы/#{s[ 'наборы' ][ set ]}/#{chapter}/"
            dir = File.join path, sets[ set ].to_s, chapter.to_s
            log > { dir: dir }

            clist = begin
               Dir.foreach( dir ).sort.map do |file|
                  if file =~ /(?:(\d)\. )?(\d?\d\d\d)\.xcf$/
                     [ [ $1, $2.to_i ], [ $1, file ] ]
                  end
               end.compact.to_h
            rescue Errno::ENOENT
               log.e
               {}
            end
            log >> { 'temporary list: ' => clist }

            section.split( /,/ ).еже do |sec|
               if sec =~ /(\d+)-(\d+)/
                  ($1.to_i..$2.to_i).еже do |i|
                     begin
                        if clist[ [ glas, i ] ]
                              @pages << File.join( dir, clist[ [ glas, i ] ][ 1 ] ) ; end
                     rescue
                        log.e
                     end
                  end
               elsif sec =~ /(\d+)/
                  begin
                     if clist[ [ glas, $1.to_i ] ]
                        @pages << File.join( dir, clist[ [ glas, $1.to_i ] ][ 1 ] ) ; end
                  rescue
                     log.e ; end ; end ; end ; end
         log >> { 'Book pages' => @pages } ; end ; end

   class BookShelf
      rdoba :log => { :functions => [ :info, :warn ] }

      attr_reader :books

      def make dir, specbook = nil
         log + { dir: dir, specbook: specbook }

         books = specbook.empty? && @books ||
               @books.select {|b| b.name == specbook }
         if books.empty? && !@books.include?(specbook)
            log % "Book '#{specbook}' wasn't found in the book list"
            end

         if dir.empty?
            dir = './' ; end
         books.еже do |book|
            log >> { book: book }
            pdffn = File.join dir, "#{book.name}.pdf"
            djvufn = File.join dir, "#{book.name}.djvu"
            book.make :pdf => pdffn, :djvu => djvufn ; end ; end

      def initialize s, basepath = './'
         log + { s: s }
         @books = []
         s[ 'книги' ].each_pair do |book, value|
            log > { book: book, value: value }
            if value.empty?
               next ; end
            path = s[ 'къбукы' ] =~ /^[\/~]/ && s[ 'къбукы' ] ||
                  File.join( basepath, s[ 'къбукы' ] )
            sets = s[ 'наборы' ]
            @books << Book.new( book, value, path, sets ) ; end
         log >> { :@books => @books } ; end ; end

   def self.book settings, dir, specbook = nil, basepath = './'
      log + { settings: settings }
      bs = BookShelf.new settings, basepath
      bs.make dir, specbook
   end ; end

