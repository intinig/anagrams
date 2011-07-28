# anagramops.rb - part of the anagram engine 
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

require "lookuptable.rb" # Lookup Table Singleton class

# Some useful operations needed for anagrams
module AnagramOperations
	# Gets the "prime signature" of a phrase
	# phrase: the phrase to analyze
	# locale: locale symbol
	# IMPORTANT: Phrase must be already chomped and downcased
	def AnagramOperations.sig_full(phrase, locale)
		sig_full = 1
		l = LookupTable.create(locale)
		phrase.scan(/\w/) do |c| # Only letters, no spaces
			sig_full *= l.prime_value(:full, c)
		end
		sig_full
	end
	
	# Gets the "left prime signature" of a phrase
	# phrase: the phrase to analyze
	# locale: locale symbol
	# IMPORTANT: Phrase must be already chomped and downcased
	def AnagramOperations.sig_left(phrase, locale)
		sig_left = 1
		l = LookupTable.create(locale)
		phrase.scan(/\w/) do |c|
			sig_left *= l.prime_value(:left, c) || 1
		end
		sig_left
	end

	# Gets the "right prime signature" of a phrase
	# phrase: the phrase to analyze
	# locale: locale symbol
	# IMPORTANT: Phrase must be already chomped and downcased
	def AnagramOperations.sig_right(phrase, locale)
		sig_right = 1
		l = LookupTable.create(locale)
		phrase.scan(/\w/) do |c|
			sig_right *= l.prime_value(:right, c) || 1
		end
		sig_right
	end
end
