#--
# Copyleft meh. [http://meh.doesntexist.org | meh@paranoici.org]
#
# This file is part of ruby-mbox.
#
# ruby-mbox is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ruby-mbox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with ruby-mbox. If not, see <http://www.gnu.org/licenses/>.
#++

require 'stringio'

require 'mbox/mail'

class Mbox
	def self.open (path, options = {})
		Mbox.new(File.new(path, 'r'), options).tap {|mbox|
			mbox.name = File.basename(name)
		}
	end

	include Enumerable

	attr_reader   :options
	attr_accessor :name

	def initialize (what, options = {})
		@input = if what.respond_to? :to_io
			what.to_io
		elsif what.is_a? String
			StringIO.new(what)
		else
			raise ArgumentError, 'I do not know what to do.'
		end

		@options = { separator: /^From [^\s]+ .{24}/ }.merge(options)
	end

	def each (opts = {})
		while mail = Mail.parse(@input, options.merge(opts))
			yield mail
		end
	end

	def [] (index, opts = {})
		seek index

		if @input.eof?
			raise IndexError, "#{index} is out of range"
		end

		Mail.parse(@input, options.merge(opts))
	end

	def seek (to, whence = IO::SEEK_SET)
		if whence == IO::SEEK_SET
			@input.seek(0)
		end

		last   = ''
		index  = -1

		while line = @input.readline rescue nil
			if line.match(options[:separator]) && last.chomp.empty?
				index += 1

				if index >= to
					@input.seek(-line.length, IO::SEEK_CUR)

					break
				end
			end

			last = line
		end

		self
	end

	def length
		@input.seek(0)

		last   = ''
		length = 0

		while line = @input.readline rescue nil
			if line.match(options[:separator]) && last.chomp.empty?
				length += 1
			end

			last = line
		end

		length
	end

	alias size length

	def has_unread?
		any? &:unread?
	end

	def inspect
		"#<Mbox:#{name} length=#{length}>"
	end
end
