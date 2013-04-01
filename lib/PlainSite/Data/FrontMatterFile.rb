#coding:utf-8
module PlainSite;end
module PlainSite::Data
  # require 'active_support/core_ext/hash' # Silly
  # require 'active_support/hash_with_indifferent_access' # Fat
  require 'safe_yaml'
  class InvalidFrontMatterFileException<Exception;end

  class FrontMatterFile
    # YAML Front Matter File
    # Example file content:
    #   ---
    #   title: Hello,world!
    #   tags: [C,Java,Ruby,Haskell]
    #   ---
    #   File content Here!
    #
    attr_reader :path
    DELIMITER='---'

    def initialize(path)
      # The String file path
      @path=path
      @content_pos=0
    end

    def headers
      File.open(@path) do |f|
        line=f.readline.strip
        break if line!=DELIMITER
        header_lines=[]
        begin
          while (line=f.readline.strip)!=DELIMITER
            header_lines.push line
          end
          @headers = YAML.safe_load(header_lines.join "\n")
          unless Hash===@headers
            raise InvalidFrontMatterFileException,"Front YAML must be Hash,not #{@headers.class},in file: #{path}"
          end
          @content_pos=f.pos
          @headers['path'] = @path
          return @headers
        rescue YAML::SyntaxError => e
          raise  InvalidFrontMatterFileException,"YAML SyntaxError:#{e.message},in file: #{path}"
        rescue EOFError => e
          raise InvalidFrontMatterFileException,"Unclosed YAML in file: #{path}"
        end
      end

      return {"path" => @path }
    end

    # Intended no cache, listen directory changes not work on platforms other than linux
    def content
      self.headers # init @content_pos
      File.open(path) do |f|
        f.seek @content_pos,IO::SEEK_SET
        @content=f.read.strip.freeze
      end
    end


  end
end # end PlainSite::Data
