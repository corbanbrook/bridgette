require 'rubygems'
require 'em-websocket'

class BridgeServer
  def self.start options
    EventMachine.run do 
      EventMachine::WebSocket.start :host => options[:host], :port => options[:port] do |socket|
        irc = nil

        socket.onopen  do 
          socket.send "Connection successful."
        end

        # messages coming from the web browser
        socket.onmessage  do |message| 
          # this server tries to be as simple and dumb as possible.   
          # only listening to commands to /bridge (.+) and passes 
          # through everything else
          case message
            when /^\/bridge\s(.+)\s(\d{2,4})$/
              options = {:host => $1, :port => $2.to_i}
              socket.send "Bridging TCP network: #{options[:host]} #{options[:port]}"
              puts    "Bridging TCP network: #{options[:host]} #{options[:port]}"
              begin 
                irc = EventMachine::connect options[:host], options[:port], IRC, socket
                bridged = true
              rescue
                puts $!;
                socket.send "[error] Bridge failed."
                puts "Bridge failed."
                bridged = false;
              end
              socket.send "Bridge successful." if bridged

            else # pass through
              irc.send message
          end
        end

        socket.onclose do 
          puts "WebSocket disconnected." 
        end
      end
    end
  end
end


module IRC 
  def initialize websocket
    @ws = websocket
  end

  def post_init
    @ws.send "BRIDGE CONNECTED"
  end

  def receive_data message
    puts "<- " + message
    @ws.send message
  end

  def send message 
    puts "-> " + message
    send_data message + "\r\n"
  end
end

BridgeServer::start :host => "0.0.0.0", :port => 7777
