require 'fileutils'
require 'sinatra'
require 'sinatra-websocket'

set :server, 'thin'
set :sockets, []

$working_file = "./content.txt"
$backup_dir = "./backups"

FileUtils.mkdir_p $backup_dir
FileUtils.touch $working_file

$message = File.read $working_file
$dirty = false

get '/' do
  if !request.websocket?
    haml :index
  else
    request.websocket do |ws|
      ws.onopen do
        ws.send($message)
        settings.sockets << ws
      end
      ws.onmessage do |msg|
        EM.next_tick {
          settings.sockets.each{|s| s.send(msg)}
          $message = msg
          $dirty = true
        }
      end
      ws.onclose do
        warn("websocket closed")
        settings.sockets.delete(ws)
      end
    end
  end
end



Thread.new do
  while true do
    if $dirty then
      FileUtils.cp($working_file, "#{$backup_dir}/#{Time.now.to_i}.txt")
      File.write($working_file, $message)
      $dirty = false
    end
    sleep 300 # sleep for 5 minutes
  end
end



__END__
@@ index
!!! 5
%html
  %head
    %meta{:charset => "utf-8"}
    %title Notepad
    %meta{:name => "viewport", :content => "width=device-width; initial-scale=1.0; maximum-scale=1.0;"}
  %body
    %textarea#main
    :javascript
      var ws;
      function changed(msg) {
        console.log(`sent: ${msg}`);
        ws.send(msg);
      }
      window.onload = function(){
        (function(){
          var set = function(el){
            return function(msg){ el.value = msg; }
          }(document.getElementById('main'));

          document.getElementById('main').addEventListener('input', (e) => changed(e.target.value));
          ws           = new WebSocket('ws://' + window.location.host + window.location.pathname);
          ws.onopen    = function()  { console.log('websocket opened'); };
          ws.onclose   = function()  { console.log('websocket closed'); }
          ws.onmessage = function(m) { console.log(`received: ${m.data}`); set(m.data); };
        })();
      }
    :css
      * {
        padding: 0;
        margin: 0;
      }
      textarea {
        padding: 30px;
        width: calc(100vw - 60px);
        height: calc(100vh - 60px);
        overflow-y: scroll;
        resize: none;
        border: none;
      }
