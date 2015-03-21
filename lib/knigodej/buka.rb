require 'pry'
require 'rltk'

module Knigodej
   class Buka
      class Lexer < RLTK::Lexer
         rule( '%' ) { :CMD }
         rule( /[А-ЯЁа-яё]+/ ) { |t| [ :WORD, t ] }
         rule( /\s+/ ) { :SPACE }
      end

      class Parser < RLTK::Parser
         class Environment < Environment
            def font_size
               400
            end

            def font_path
               '/usr/share//fonts/ttf/church/HirmUcs8.ttf'
            end
         end

         list( :buka, :token, :SPACE )

         production( :token ) do
            clause( 'command' ) { |c| [ :font, font_path, size: font_size ] }
            clause( 'text' ) { |t| [ :text, t ] }
         end

         production( :command ) do
            clause( 'CMD WORD' ) { |_, c| c }
            clause( 'WORD' ) { |w| w }
         end

         production( :text ) do
            clause( 'WORD' ) { |t| t }
            clause( 'SPACE' ) { |s| s }
         end

         finalize
      end

      attr_reader :f

      def initialize pdf
         @pdf = pdf
      end

      def parse file
         f = IO.read file
         ast = Parser.parse Lexer.lex( f.strip )
         ast.each do |tokens|
            method = tokens.shift.to_sym
            @pdf.send method, *tokens
         end
      end
   end
end

