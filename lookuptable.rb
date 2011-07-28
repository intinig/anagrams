# lookuptable.rb - part of the anagram engine 
# Copyright (C) 2004 Giovanni Intini <intinig@pme.it> 
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version. 
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details. 
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place, Suite 330, Boston, MA 02111-1307 USA

require "mathn"

class LookupTable
	private_class_method :new
	@@lookuptable = nil
	def initialize(locale = :it)
		@Lookup_table = {:full => Hash.new, :left => Hash.new, :right => Hash.new}
		if locale == :it
			@letter_sequence = "iaeortnsclmpgduvbzfhqkxywj"
		elsif locale == :en
			@letter_sequence = "esiarnotlcdupmghbyfvkwzxqj"
		end
		prime_number = Prime.new
		i = 0
		@letter_sequence.each_byte do |c| 
			i += 1
			@Lookup_table[:full][c.chr] = prime_number.succ
			if i % 2 == 0
				@Lookup_table[:left][c.chr] = @Lookup_table[:full][c.chr]
			else
				@Lookup_table[:right][c.chr] = @Lookup_table[:full][c.chr]
			end
		end
	end
	def prime_value(part, c)
		@Lookup_table[part][c]
	end
	def LookupTable.create(locale)
		@@lookuptable = new(locale) unless @@lookuptable
		@@lookuptable
	end
end