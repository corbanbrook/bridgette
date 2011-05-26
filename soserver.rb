require 'rubygems'
require 'em-websocket'

class BridgeServer
  def self.start options
    EventMachine.run do 
      players = []

      EventMachine::WebSocket.start :host => options[:host], :port => options[:port] do |socket|
        playerIndex = nil

        socket.onopen  do 
          socket.send "Connection successful."
          playerIndex = players.length;
          players << {'x' => nil, 'y'=> nil}
        end

        # messages coming from the web browser
        socket.onmessage  do |message| 
          # this server tries to be as simple and dumb as possible.   
          # only listening to commands to /bridge (.+) and passes 
          # through everything else
          case message
            when /^\/position\s(\d+)\s(\d+)$/
              players[playerIndex]['x'] = $1
              players[playerIndex]['y'] = $2
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
          end
        end

        socket.onclose do 
          puts "WebSocket disconnected." 
        end
      end
    end
  end
end

BridgeServer::start :host => "0.0.0.0", :port => 7777
