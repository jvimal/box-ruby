# log in using the login example, so we don't have to duplicate code
$: << File.dirname(__FILE__) # for 1.9
require 'login'

# get the root of the folder structure
root = @account.root

# list all of the folders in the root directory with their index
root.folders.each_with_index do |folder, i|
  puts "##{ i } -- #{ folder.name }"
end

# let the user pick one to show the contents of
puts "Pick a folder number above to show: "
index = gets

begin
  # grab the folder they selected
  # to_i or [] will throw an exception if the index is invalid or out of range respectively
  folder = root.folders[index.to_i]
rescue
  # they picked an invalid folder!
  puts "You picked an invalid folder, please try again."
  exit
end

# the folder they picked was valid
puts "Excellent choice, here are the contents of that folder"

# show the selected folder
puts "FOLDER: #{ folder.name } (#{ folder.id })"

# loop through and show each of the sub files and folders
(folder.files + folder.folders).each do |item|
  puts "\t#{ item.type.upcase }: #{ item.name } (#{ item.id })"
end
