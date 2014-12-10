module ActiveRecord
	module ConnectionAdapters
		class PostgreSQLColumn
			class CompositeTypeParser
        class Splitter < StringScanner
          OPEN_PAREN = /\(/.freeze
          CLOSE_PAREN = /\)/.freeze
          UNQUOTED_RE = /[^,)]*/.freeze
          SEP_RE = /[,)]/.freeze
          QUOTE_RE = /"/.freeze
          QUOTE_SEP_RE = /"[,)]/.freeze
          QUOTED_RE = /(\\.|""|[^"])*/.freeze
          REPLACE_RE = /\\(.)|"(")/.freeze
          REPLACE_WITH = '\1\2'.freeze

          # Split the stored string into an array of strings, handling
          # the different types of quoting.
          def parse
            return @result if @result
            values = []
            skip(OPEN_PAREN)
            if skip(CLOSE_PAREN)
              values << nil
            else
              until eos?
                if skip(QUOTE_RE)
                  values << scan(QUOTED_RE).gsub(REPLACE_RE, REPLACE_WITH)
                  skip(QUOTE_SEP_RE)
                else
                  v = scan(UNQUOTED_RE)
                  values << (v unless v.empty?)
                  skip(SEP_RE)
                end
              end
            end
            values
          end
        end

				def self.parse_data(string)
					Splitter.new(string).parse
				end
			end
		end
	end
end
