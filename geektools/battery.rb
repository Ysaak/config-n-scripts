#!/usr/bin/env ruby
#coding: utf-8

# include option parsing library
require 'optparse'
options = {}

# grab command line arguments
parser = OptionParser.new do |opts|
  opts.banner = "Usage: battery.rb [options]"
  
  options[:color] = false
  opts.on( '-c', '--color', 'Display battery meter with color' ) do
    options[:color] = true
  end
  
  opts.on( '-h', '--help', 'Displays this help screen' ) do
    puts opts
    exit
  end
end

parser.parse!

class Battery
  def initialize() # gather relevant info
    @conn = `ioreg -n AppleSmartBattery | grep ExternalConnected | awk '{ print $5 }'` # is power connected
    @chrg = `ioreg -n AppleSmartBattery | grep IsCharging | awk '{ print $5 }'` # is battery chargin
    @time = `ioreg -n AppleSmartBattery | grep TimeRemaining | awk '{ print $5 }'` # time remaining on battery
    @max = `ioreg -n AppleSmartBattery | grep MaxCapacity | awk '{ print $5 }'` # maximum capacity
    @cur = `ioreg -n AppleSmartBattery | grep CurrentCapacity | awk '{ print $5 }'` # current capacity
  end # def initialize

  def build_meter(color) # built battery meter
    percent = self.build_percent # get capacity percentage
    if color then
      red = "\e[31m"
      yellow = "\e[33m"
      green = "\e[32m"
      clear = "\e[0m"
    else
      red = ""
      yellow = ""
      green = ""
      clear = ""
    end
    meter = ""
    
    for i in (1..10) # one bar per 10% battery, dashes for each empty 10%
      if percent >= 10 then
        i <= 2 ? meter << red : nil # first 2 bars red
        i <= 5 && i > 2 ? meter << yellow : nil # next 3 bars yellow
        i <= 10 && i > 5 ? meter << green : nil # remaining 5 green
        meter << "❚" + clear # clear color
      else
        meter << "·" # empty
      end # if percent >= 10
      percent -= 10 # decrement percentage for next loop
    end # for i in (1..10)
    return meter + clear
  end # def build_meter
  
  def build_time # determines time remaining on battery
    hour = @time.strip.to_i / 60 # hours left
    min = @time.strip.to_i - (hour * 60) # minutes left
    min < 10 ? min = "0#{min}" : nil # make sure minutes is two digits long

    if @conn.strip == "Yes" then # power cable connected
      if @chrg.strip == "Yes" then # is plugged in and charging
        batTime = "Charging: #{hour}:#{min}"
      else # is plugged in but not charging
        self.build_percent == 100 ? batTime = "Charged" : batTime = "Not Charging"
      end # if @chrg.strip == "Yes"
    else # power is not connected
      if @time.to_i < 1 || @time.to_i > 2000 then
        batTime = "Calculating"
      else
        batTime = "#{hour}:#{min}"
      end # if @time < 1 || @ time > 2000 
    end # if @conn.strip == "Yes"
    
    return batTime
  end # def build_time
  
  def build_percent # returns percentage of battery remaining
    return (@cur.to_f / @max.to_f * 100).round.to_i
  end # def build_percent
end # Class Battery

battery = Battery.new

puts battery.build_meter(options[:color]) + ' ' + battery.build_percent.to_s + '% (' + battery.build_time.to_s + ')'
