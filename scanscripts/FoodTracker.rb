require './FoodItem.rb'
require './FoodSaver.rb'

# The Food Tracker Class is the CLI interface
# which holds a Hash Table of FoodItems.
class FoodTracker

  def initialize(saver)
    @table = Hash.new
    @scans = Hash.new
    @saver = saver

    sysout("Loading Food...")
    @table = @saver.load_item
    sysout("Loading Scan History...")
    @scans = @saver.load_scans

    sysout("Starting Food Tracker")
  end

  def command_line
    prompt = "(n)ew , (a)dd, (r)ead, (v)iew scan times, (q)uit \nput in a hash to remove one element of it, or add a new item to store it in the database.\n"
    while(true) do
      puts
      sysout( prompt )
      print ">> "

      input = gets.chomp
      abort("EOF, terminating program...") if input == nil
      input.downcase!

      case input
      when "a"
        add_item_cmd
      when "r"
        read_items
      when "n"
        new_item
      when "q"
        shutdown
      when "v"
        list_scans
      else
        new_item(input)
      end
    end
  end

  def list_scans
    @scans.each {|upc, array| puts @table[upc].name; puts array}
  end

  def new_item(upc=gets.chomp)
    scantime = DateTime.now

    if not @table.has_key?(upc)
      #create new food
      @table[upc] = FoodItem.new(upc,1)
      @saver.save_new_item(@table[upc])
      @scans[upc] = Array.new
    else
      add_item(@table[upc])
    end

    #add scan evidence to scan array
    @scans[upc].push(scantime)
    @saver.add_scan_timestamp(upc, scantime)
    puts("#{@table[upc].name}")
  end

  # Add any number of items
  def add_item_cmd
    puts("item: ")
    item = gets.chomp
    puts("number: ")
    number = gets.chomp.to_i
    add_item(@table[item], number)
  end

  # Add Item
  def add_item(item, number=1)
    item.add(number)
    @saver.update_item_amount(item.upc, item.number)
  end

  # Read items
  def read_items
    @table.each {|key,value| puts value}
  end

  # System IO for future debugging
  def sysout(string)
    puts ("[SYSTEM]: " + string)
  end

  # Shutdown sequence when cli recieves 'q'
  def shutdown
    sysout("System going for shutdown")
    #Do I/O (save to file for example)
    abort("Food Item Tracker Terminated")
  end
end
