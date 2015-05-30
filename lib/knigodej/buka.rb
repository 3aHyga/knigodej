#encoding: utf-8

require 'rltk'
require 'priehlazx'

module Knigodej
   class Buka
      class Lexer < RLTK::Lexer
         rule( '%' ) { :CMD }
         rule( /[А-ЯЁа-яё]+/ ) { |t| [ :WORD, t ] }
         rule( /\s+/ ) { :SPACE } ; end

      class Parser < RLTK::Parser
         class Environment < Environment
            Commands = {
               'цс' => [ :font, :font_path, size: :font_size ],
            } ; end

         list( :buka, :token, :SPACE )

         production( :token ) do
            clause( 'command' ) { |c| Environment::Commands[ c ] }
            clause( 'text' ) { |t| [ :text, [ :@plg, :go, t ] ] } ; end

         production( :command ) do
            clause( 'CMD WORD' ) { |_, c| c } ; end

         production( :text ) do
            clause( 'WORD' ) { |t| t }
            clause( 'SPACE' ) { |s| s } ; end

         finalize ; end

      attr_reader :f
      attr_writer :font_size
      attr_accessor :font_path, :page_height

      def initialize params = {}
         @font_size = '6%'
         @font_path = '/usr/share//fonts/ttf/church/HirmUcs8.ttf'
         @cp = 'hip'
         @plg = Priehlazx.new
         @plg.истокъ = 'UTF8/HIP'
         @plg.цѣль = 'UCS8'
         params.each { |k, v| self.instance_variable_set( "@#{k}", v ) } #TODO to lib
         end

      def font_size
         if @font_size =~ /(.*)%$/
            if @page_height.is_a? Numeric
               ( $1.to_f * @page_height / 100 ).to_i
            else
               raise "Page height wasn't defined" ; end
         else
            @font_size ; end ; end

      def parse_eval array
         array.map do |v|
            case v
            when Symbol
               self.send( v )
            when Hash
               v.map { |(k,v)| [ k, send( v ) ] }.to_h
            when Array
               self.instance_variable_get( v[ 0 ] ).send( *v[ 1..-1 ] )
            else
               v ; end ; end ; end

      def parse file
         f = IO.read file
         ast = Parser.parse Lexer.lex( f.strip )
         ast.each do |tokens|
            method = tokens.shift.to_sym
            @pdf.send method, *parse_eval( tokens ) ; end ; end ; end ; end
