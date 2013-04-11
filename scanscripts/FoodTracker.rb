require './FoodItem'
require './FoodSaver'
require './FoodConfig'

# The Food Tracker Class is the CLI interface
# which holds a Hash Table of FoodItems.
class FoodTracker

  def initialize(saver)
    @table = Hash.new
    @scans = Hash.new
    @saver = saver
    @config = FoodConfig.new
    @purchase_mode = true

    sysout("Loading Food...")
    @table = @saver.load_item
    sysout("Loading Scan History...")
    @scans = @saver.load_scans
    sysout("Starting Food Tracker")
  end

  def command_line
    prompt = "(n)ew , (a)dd, (r)ead, (p)urchase mode toggle, (v)iew scan times, (q)uit \nput in a hash to remove one element of it, or add a new item to store it in the database.\n"
    while(true) do
      puts
      sysout( prompt )
      print ">> "

      input = gets.chomp
      input = @config.get_upc(input) #filter for redirects
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
        break
      when "v"
        list_scans
      when "p"
        @purchase_mode = !@purchase_mode
        sysout("Purchase mode #{@purchase_mode ? "on" : "off"}")
      else
        new_item(input)
      end
    end
  end

  def list_scans
    @scans.each {|upc, array| puts @table[upc].name; puts array.map{|x| "   #{x}" }}
  end

  def new_item(upc=gets.chomp, number=1)
    upc = @config.get_upc(upc)
    purchase_time = DateTime.now

    if @config.variety_packs.has_key?(upc)
      @config.variety_packs[upc].each do |item, amount|
        new_item(item, number*amount)
      end
    else
      if not @purchase_mode
        puts "fundraising is stocking the cabinet"

        if not @table.has_key?(upc)
          #create new food
          item = @config.dummy[upc]
          name =  item[:name] if not item.nil?
          @table[upc] = FoodItem.new(upc,0, 0, name)
          @saver.save_new_item(@table[upc])
        end
        add_item(upc, number)
        record_scan_time(upc, purchase_time, number)
      else
        if not @table.has_key?(upc)
          puts "This item is not in the database. Please contact fundraising@sse.se.rit.edu before buying the item."
        else
          puts "user is buying an item"
          add_item(upc, number)
          record_scan_time(upc, purchase_time, number)
        end
      end
    end
  end

  def record_scan_time(upc, time, number)
    @scans[upc] = Array.new if not @scans[upc]

    #add scan evidence to scan database
    if (@scans[upc])
      puts "adding scan"
      @scans[upc] << time
      @saver.add_scan_timestamp(upc, time, @purchase_mode, number)
    end
  end

  # Add any number of items
  def add_item_cmd
    puts("upc: ")
    upc = gets.chomp
    puts("number: ")
    number = gets.chomp.to_i
    new_item(upc, number)
  end

  # Add Item
  def add_item(upc, number=1)
    # save the item to the database
    @table[upc].add(number, @purchase_mode)
    num = @purchase_mode ? @table[upc].sold : @table[upc].stock
    @saver.update_item_amount(@table[upc].upc, num, @purchase_mode)
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
    puts("Food Item Tracker Terminated")
  end
end
