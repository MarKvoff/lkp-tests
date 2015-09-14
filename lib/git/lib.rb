LKP_SRC ||= ENV["LKP_SRC"] || File.dirname(File.dirname File.realpath $PROGRAM_NAME)

require "#{LKP_SRC}/lib/simple_cache_method"
require 'git'

module Git
	class Lib
		def command_lines(cmd, opts = [], chdir = true, redirect = '')
			command_lines = command(cmd, opts, chdir)

			begin
				command_lines.split("\n")
			rescue Exception => e
				# to deal with "GIT error: cat-file ["commit", "9f86262dcc573ca195488de9ec6e4d6d74288ad3"]: invalid byte sequence in US-ASCII"
				# - one possibility is the encoding of string is wrongly set (due to unknown reason), e.g. UTF-8 string's encoding is set as US-ASCII
				#   thus to force_encoding to utf8_string and compare to error check of utf8_string, if same, will consider as wrong encoding info
				utf8_command_lines = command_lines.clone.force_encoding("UTF-8")
				if utf8_command_lines == utf8_command_lines.encode("UTF-8", "UTF-8", undef: :replace)
					utf8_command_lines.split("\n")
				else
					STDERR.puts "GIT error: #{cmd} #{opts}: #{e.message}"
					STDERR.puts "GIT env: LANG = #{ENV['LANG']}, LANGUAGE = #{ENV['LANGUAGE']}, LC_ALL = #{ENV['LC_ALL']}, "\
					            "encoding = #{command_lines.encoding}"

					command_lines.encode("UTF-8", "binary", invalid: :replace, undef: :replace).split("\n")
				end
			end
		end

		public :command_lines
		public :command

		alias_method :orig_command, :command
		def command(cmd, opts = [], chdir = true, redirect = '', &block)
			begin
				orig_command(cmd, opts, chdir, redirect, &block)
			rescue Exception => e
				STDERR.puts "GIT error: #{cmd} #{opts}: #{e.message}"
				STDERR.puts "GIT dump: #{self.inspect}"
				raise
			end
		end
	end
end
