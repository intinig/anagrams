#!/usr/bin/env ruby

# ars.rb - part of the anagram engine 
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

# ars.rb is the main script, it includes lots of functionality let's see them
# one by one.
#
# First of all you can call the script without any parameter, just the phrase
# you want to anagram, and you will get 100 different anagrams.
# i.e. $ ars.rb hello world
#
# The optional switches/parameters are :
#		--random							instead of generating the anagrams starting from the
# 												bigger words, using this switch the program
#												  randomizes the original dictionary before starting
# 												the anagram generation
#
#		 -w LENGTH
#		--word-length LENGTH	does not look for words longer than LENGTH
#
#		--locale LOCALE				tries to use the VAL locale (2 letters). If it
# 												doesn't find the corresponding dictionary it
#													defaults to :it
#
#		--generate-dictionary PATH-TO-DICTIONARY	this is an important switch, you
#																							should use it if you intend to 
#																							create the DB data by yourself.
#																							the dictionary file must be a
#																							simple text file with one word
#																							per line. The output is a
#																							sequence of SQL statements
#
#		--frequency PATH-TO-DICTIONARY	you have to run ars.rb with this switch
#																		to analyze the frequency of each letter.
#																		The output should be put in lookuptable.rb
#		-l NUMBER-OF-ANAGRAMS
#		--limit NUMBER-OF-ANAGRAMS			generates a maximum of NUMBER-OF-ANAGRAMS
#																		anagrams

# Main anagram class
require "anagrammer.rb"
# Used for commandline parsing
require "optparse"

if ARGV.size == 0 # Newbie?
	puts("ars.rb: you have to specify a sentence to anagram")
else 
	# Default parameters
	limit = 100
	dict_random = false
	locale = :it
	locale_string = "it"
	word_length = 0

	# Option Parser
	opts = OptionParser.new

	# Word length limit
	opts.on("-w VAL", "-w=VAL", "--word-length VAL", "--word-length=VAL", Integer) {|val| word_length = val}
	
	# Locale
	# TODO: locales should not be hardcoded here. The locale should be checked
	# at the first sql query, or lookupstring
	opts.on("--locale VAL", String) do |val|
		if val.length == 2
			locale = case
				when val == "it": :it
				when val == "en": :en
				else :it
			end
			locale_string = val
		end
	end
	
	# Random?
	opts.on("--random") { dict_random = true }
	
	# Limit
	opts.on("-l VAL", "-l=VAL", "--limit VAL", "--limit=VAL", Integer) { |val| limit = val}
	
	# Frequency generation
	opts.on("--frequency VAL", String) do |filename| 
		File.open(filename) do |file|
			frequency = Hash.new { |h, k| h[k] = 0 }
			total_chars = 0
			file.each_line do |line|
				# The destructive methods are used because this way it's faster
				# they're not chained because the destrutive methods return nil
				# if they didn't do anything
				line.chomp!
				line.downcase!
				line.scan(/./) do |x|
					frequency[x] += 1
					total_chars += 1
				end
			end
			# After getting the frequencies we sort the hash, that magically
			# becomes an array
			sorted_freq = frequency.sort {|a,b| a[1] <=> b[1]}
			lookupstring = ""
			sorted_freq.reverse.each do |key|
				puts "#{key[0]}: #{key[1]}"
				lookupstring += key[0]
			end
			puts("Total Chars: #{total_chars}")
			puts("Lookup String: #{lookupstring}")
		end
	end
	
	# Dictionary generation
	opts.on("--generate-dictionary VAL", String) do |filename|
		File.open(filename) do |file|
			file.each_line do |line|
				line.chomp!
				line.downcase!
				puts "INSERT INTO words_#{locale_string}(word, left_signature, right_signature) VALUES ('#{line}', '#{AnagramOperations.sig_left(line, locale)}', '#{AnagramOperations.sig_right(line, locale)}');"
			end
		end
	end
	
	#
	# TODO: Write a good-looking help
	#
	
	# Now there's the main loop. An anagram object is instanced and then 		
	# Anagram#each_anagram is used to walk the anagram tree
	rest = opts.parse(ARGV)
	unless rest.length == 0
		anagram = Anagram.new(rest.join(" "), locale, word_length, limit, dict_random)
		if anagram.anagrammable? 
			anagram.each_anagram {|x| puts x}
			puts("Total computed anagrams: #{anagram.count_anagrams}")
		else
			puts("sorry the sentence you typed is too big or too complex")
		end
	end
end