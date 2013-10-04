#coding: utf-8

require "knigodej/version"
require 'mini_magick'
require 'prawn'
require 'rdoba'

module Knigodej
   rdoba :log => { :functions => :basic }

   class Book
      rdoba :log => { :functions => :basic }
      rdoba :mixin => [ :to_h ]

      attr_accessor :authors, :creator, :keywords, :subject
      
      attr_reader :pages, :name

      def make options = {}
         log + { options: options }
         pdffn = options[ :pdf ]
         djvufn = options[ :djvu ]
         if !pdffn && !djvufn
            raise "Neither PDF nor DJVU filename was specified" ; end

         isdjvu = djvufn
         if `which djvm`.empty?
            isdjvu = false ; end
         ispdf = pdffn
         log > { 'will make PDF?' => !!ispdf, 'will make DJVU?' => !!isdjvu }

         if isdjvu
            FileUtils.rm_f djvufn ; end
   
         if ispdf
            pdf = Prawn::Document.new(
                  :page_size => "A0", #TODO analyze
                  :margin => 0,
                  :info => {
                     :Title => @name,
                     :Author => @authors.join( ',' ),
                     :Subject => @creator,
                     :Keywords => @keywords.join( ',' ),
                     :Creator => @subject,
                     :Producer => "Prawn",
                     :CreationDate => Time.now } )

               pdf.fill_color "dcd1bf"
               pdf.fill_polygon [ 0, 0 ], [ 2383, 0 ], [ 2383, 3370 ],
                     [ 0, 3370 ] ; end
      
         Dir.mktmpdir do |tmpdir|
            log >> { tmpdir: tmpdir }
            @pages.each_index do |i|
               xcf = @pages[ i ]
               log * { 'Processing file' => xcf }
         
               # 2512x3552 image size
               
               tmpfn = File.join tmpdir, 'output.ppm'
               begin
                  xcf_image = MiniMagick::Image.open xcf
                  bg_image = MiniMagick::Image.new tmpfn
         
                  command = MiniMagick::CommandBuilder.new 'convert -background'
                  command.push 'rgb(221,209,191)' #TODO make it changeable
                  command.push '-flatten'
                  command.push xcf_image.path
                  command.push bg_image.path
                  bg_image.run command

                  if isdjvu
                     outfn = File.join tmpdir, 'output.djvu'
                     `cpaldjvu -dpi 150 -colors 4 '#{tmpfn}' '#{outfn}'`
                     if File.exist?( djvufn )
                        `djvm -c '#{djvufn}' '#{djvufn}' '#{outfn}'`
                     else
                        `djvm -c '#{djvufn}' '#{outfn}'` ; end ; end
         
                  if ispdf
                     # Generating the PDF
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
                        end ; end
         
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
      

      def initialize name, b, path, sets
         log + { b: b, path: path, sets: sets }

         @pages = []
         if b.empty? || name.empty?
            return ; end

         @name = name
         @authors = b[ 'авторы' ]
         @creator = b[ 'создатель' ]
         @keywords = b[ 'ключевые слова' ]
         @subject = b[ 'предмет' ]

         (set, chapter, section) = [ nil, nil, nil ]
         b[ 'страницы' ].each do |page|
#         b[ 'страницы' ].пере(еже) do |page| TODO
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
      
            section.split( /,/ ).each do |sec|
               if sec =~ /(\d+)-(\d+)/
                  ($1.to_i..$2.to_i).each do |i|
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
      rdoba :log => { :functions => :basic }

      attr_reader :books

      def make dir, specbook = nil
         log + { dir: dir, specbook: specbook }

         books = specbook && @books.select {|b| b.name == specbook } || @books
         if dir.empty?
            dir = './' ; end
         books.each do |book|
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
#      log + { settings: settings } TODO
      bs = BookShelf.new settings, basepath
      bs.make dir, specbook
   end ; end

