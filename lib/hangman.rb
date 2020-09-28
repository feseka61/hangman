require 'json'

def select_word(dict)
  word = ''
  until word.length >= 5 && word.length <= 12
    word = dict.sample.downcase
  end
  word
end

def make_board(word, tries)
  word_line = '_' * word.length
  tries_line = 'remaining life: ' + 'x ' * (6-tries) + '_ ' * tries
  board = ['-' * 30, tries_line, ' ','-' * (word_line.length + 4), '| ' + word_line + ' |', '-' * (word_line.length + 4), '-' * 30]
end

def save_game_file(game_save, save_name)
  Dir.mkdir('saves') unless Dir.exist? 'saves'

  filename = "saves/save_#{save_name}.JSON"

  File.open(filename, 'w') do |file|
    file.puts game_save 
  end
end

module HelpMan
  def check_guess(word, guess)
    if guess.length == 1
      if word.include?(guess)
        return 'correct'
      else
        return 'wrong'
      end
    elsif guess.length >= 5 && guess.length <= 12
      if word == guess
        return 'guessed'
      else
        return 'wrong'
      end
    elsif guess.length > 1 || guess.length > 12
      return 'exception'
    else
      return 'wrong'
    end
  end

  def change_board(board, result, guess, word, tries)
    word_line = board[4][2..-3]
    tries_line = 'remaining life: ' + 'x ' * (6-tries) + '_ ' * tries

    case result
    when 'correct'
      counter = 0
      word.each_char.with_index do |letter, i|  
        if guess == letter
          word_line[i] = guess 
          counter += 1
        end
      end
      puts "there is #{counter} of your guess!"
    when 'wrong'
      puts 'your guess is wrong!'
    when 'guessed'
      word_line = word
    else
      puts 'please enter proper input'
    end

    board = ['-' * 30, tries_line, ' ','-' * (word_line.length + 4), '| ' + word_line + ' |', '-' * (word_line.length + 4), '-' * 30]
  end

  def game_over?(board, result, tries, word)
    guessed_word = board[4][2..-3]
    if guessed_word == word
      puts 'You found it! Congratulations!'
      return true
    elsif result == 'guessed'
      puts 'You successfully guessed it! Well done!'
      return true
    elsif tries == 0
      puts 'You let the man hang!, Such a shame!'
      puts "The word is: #{word}"
      return true
    else
      return false
    end
  end
end

class Hangman
  include HelpMan
  attr_accessor :word, :board, :tries

  def initialize(word, board, tries)
    @word = word
    @board = board
    @tries = tries
  end

  def play
    game_over = false

    until game_over
      puts @board
      puts 'Please enter your guess. (type "save game" for saving the game)'
      guess = gets.chomp.downcase
      if guess == 'save game'
        $game_status = 'save'
        game_over = true
      else
        result = check_guess(@word, guess)
        @tries -= 1 if result == 'wrong' || result == 'exception'
        @board = change_board(@board, result, guess, @word, @tries)
        game_over = game_over?(@board, result, @tries, @word)
        sleep(1)
      end
    end
  end

  def save_game
    JSON.dump({
      :word => @word,
      :board => @board,
      :tries => @tries
    })
  end

  def self.load_game(game)
    data = JSON.load game
    self.new(data['word'], data['board'], data['tries'])
  end
end
#========================================================================================================
$game_status = 'end'

file = File.open('5desk.txt', 'r')
dict = file.readlines

puts 'Do you wish to load an existing game [y/n]'
ans = gets.chomp.downcase

if ans == 'y'
  saves_dir = Dir.children('saves')
  saves_dir.each_with_index do |save_file, i|
    puts "#{i + 1}. #{save_file}"
  end
  puts 'Please select from the list (eg: 1)'
  file_number = gets.chomp.to_i
  file_name = saves_dir[ file_number - 1]
  game_file = File.read("saves/#{file_name}")
  game = Hangman.load_game game_file
  game.play
elsif ans == 'n'
  puts 'Starting a new game'
  word = select_word(dict).chomp
  tries = 6
  board = make_board(word, tries)
  game = Hangman.new(word, board, tries)
  game.play
end

if $game_status == 'save'
  game_save = game.save_game
  puts 'Save name?'
  save_name = gets.chomp
  save_game_file(game_save, save_name)
end
