# anagrammer.rb - part of the anagram engine 
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

require "anagramops.rb" # Anagram Operations helper module
require "mysql" # used only once. I'm thinking about abstracting the db, but I 
                # will stick to mysql for a while because I need performance
								# and don't want the overhead that comes with db abstraction
								# classes
require "yaml"  # YAML is used for storing db configuration in a separate file

# Anagram class
class Anagram
	attr_reader :phrase, :origphrase, :tree, :dictionary

	# Initializer
	# phrase: String you want to anagram
	# locale: two letter string of the language you want to use. The only 
	# supported languages right now are english(en) and italian(it)
	# word_length: length limit of the words extracted from the database
	# limit: number of different anagrams to be generated
	# random: if true the anagrams are generated after shuffling the dictionary
	def initialize(phrase, locale = :it, word_length = 0, limit = 100, random = false)
		# Locale attribute
		@locale = locale
		# Length limit
		@word_length = word_length
		# Anagrams limit
		@limit = limit
		# Number of generated anagrams 
		@anagrams = 0
		# Stores the original phrase
		@origphrase = phrase
		# Cleaned phrase
		@phrase = phrase.chomp.downcase.scan(/\w/).join
		if anagrammable? # The phrase isn't too complex for us
			# Dictionary of the words that are sub-anagrams of @phrase
			@dictionary = build_dictionary 
			if random # We want random so we shuffle dictionary in this block
				randomized_array = [] 
				until randomized_array.size == @dictionary.size
					random_index = rand @dictionary.size
					randomized_array.push random_index unless randomized_array.include? random_index
				end
				new_array = []
				randomized_array.size.times do |index|
					new_array.push @dictionary[randomized_array[index]]
				end
				@dictionary = new_array
			end
			# All the anagrams are contained in this tree structure
			@tree = get_branches(@dictionary, nil, AnagramOperations.sig_left(@phrase, @locale), AnagramOperations.sig_right(@phrase, @locale))
		end
	end
	
	# Generates the anagram tree
	# dict: dictionary structure
	# word: parent word
	# left, right: product of the remaining letters
	def get_branches(dict, word, left, right)
		local_tree = Hash.new # This will hold the whole tree
		if word.nil? # If we're not analyzing the original phrase
			left_pool = left   # Then we have all the letters to work with
			right_pool = right 
		else # otherwise we divide the pool by the signature of the word
			   # parameter, so we know how many letters are left
			left_pool = left / word[:left_signature]
			right_pool = right / word[:right_signature]
		end
		# Filtered (smaller) dictionary
		branches = filtered_dictionary(dict, left_pool, right_pool)
		if branches.size > 0 # Is it NOT empty?
			branches.each do |w|  # it is so we loop through its elements building
														# other trees
				break if @limit != 0 && @limit == @anagrams # ...unless we've hit
																										# the anagrams limit
				local_tree[w] = get_branches(branches, w, left_pool, right_pool)
			end
			local_tree
		# it's empty but the pool is empty too! Gotcha, we have an anagram
		elsif branches.size == 0 && left_pool == 1 && right_pool == 1
			@anagrams +=1
			local_tree
		# dead branch, return nil
		else
			return nil
		end
	end
	
	# Builds the default dictionary
	def build_dictionary
		# Extracts a string from the locale symbol
		locale_string = case
			when @locale == :it : "it"
			when @locale == :en : "en"
			else "it"
		end                  
		# This will hold the words that must not be queried from the db
		# because they appear in the original phrase
		excluded_words = ""                 
		# Split the original phrase to get the words, then (little hack) add
		# a where condition @for word_length
		origphrase.split.each {|word| excluded_words += "word != '#{word.chomp.downcase}' AND " if word.length > 2}
		excluded_words += "LENGTH(word) <= #{@word_length} AND " if @word_length > 0
		# We load the db configuration (stored in conf/database.yml)
		db_config = YAML.load(File.open("conf/database.yml"))
		# Then we create a db connection
		# TODO: No error checking, I'm a mad man
		mysql_connection = Mysql::new(db_config["hostname"], db_config["user"], db_config["password"], db_config["database"])
		# We query the db, because we're cool
		results = mysql_connection.query "
								SELECT 
									word, left_signature, right_signature 
								FROM 
									words_#{locale_string} 
								WHERE 
									#{excluded_words}
									(#{AnagramOperations.sig_left(phrase, @locale)} % left_signature = 0) 
								AND 
									(#{AnagramOperations.sig_right(phrase, @locale)} % right_signature = 0) 
								ORDER BY
									LENGTH(word)
								DESC"
		# At last we build the dictionary that will be the return value of 
		# the method. The dictionary is an array of hashes, while the 
		# anagramtree is a hash of hashes:
		dictionary = Array.new
		results.each_hash do |r|
			dictionary.push({:word => r["word"], :left_signature => r["left_signature"].to_i, :right_signature => r["right_signature"].to_i})
		end
		dictionary
	end

	# Returns a dictionary where non subanagrams words are removed
	def filtered_dictionary(orig_dict, pool_left, pool_right)
		# The wonderful find_all helps us in the task by returning
		# non modulo words. Believe me, before I discovered find_all
		# this method was a mess :)
		dict = orig_dict.find_all {|w| pool_left % w[:left_signature] == 0 && pool_right % w[:right_signature] == 0}
		dict
	end
	
	# Internal used by each_anagram
	# root: root tree
	# branch: the branch we're going to explore
	# phrase: the phrase we've built so far
	def walk_tree(root, branch, phrase)
		unless branch.nil? # This is not a dead branch
			if branch.empty? # If it's empty though we've reached a complete anagram
				yield "#{phrase} #{root[:word]}".lstrip # so we yield the new phrase
			else
				branch.each do |h, k| # It's not empty, we have to explore it
					walk_tree(h, k, phrase + " " + root[:word]) {|w| yield w.lstrip}
				end
			end
		end
	end			
		
	# Avoids too complex phrases by checking against the 64-bit signature limit
	def anagrammable? 
		AnagramOperations.sig_left(phrase, @locale) < 18446744073709551615 && AnagramOperations.sig_right(phrase, @locale) < 18446744073709551615
	end
	
	# Anagrams Iterator, walks the anagram tree
	def each_anagram
		# This is just a more garbled version of walk_tree with default values
		# I could remove it, but I keep it for ease of use
		@tree.each {|h, k| (k.empty? ? (yield h[:word].lstrip) : (walk_tree(h, k, "") {|w| yield w.lstrip})) unless k.nil?}
	end

	# How many anagrams have been processed?
	def count_anagrams
		@anagrams
	end

	# Outputs some stats
	def stats
		"=====\nStats\n=====\nOriginal Phrase: #{@origphrase}\nFull: #{sig_full}\nLeft: #{AnagramOperations.sig_left(phrase, @locale)}\nRight: #{AnagramOperations.sig_right(phrase, @locale)}"
	end

	public	:anagrammable?, :each_anagram, :count_anagrams, :stats
	private :build_dictionary, :filtered_dictionary, :get_branches, :walk_tree
	
end