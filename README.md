Eye
===

Process monitoring tool. Alternative for God and Bluepill. With Bluepill like config syntax. Requires MRI Ruby >= 1.9.2. Uses Celluloid and Celluloid::IO.


Recommended installation on the server (system wide):

    $ sudo /usr/local/ruby/1.9.3/bin/gem install eye
    $ sudo ln -sf /usr/local/ruby/1.9.3/bin/eye /usr/local/bin/eye


Config example, shows some typical processes and most of the options (see in exampes/ folder):

examples/test.eye
```ruby
Eye.load("./eye/*.rb") # load submodules

Eye.config do
  logger "/tmp/eye.log" # eye logger
  logger_level Logger::DEBUG
end

Eye.application "test" do
  working_dir File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))
  stdall "trash.log" # stdout,err logs for processes by default
  env "APP_ENV" => "production" # global env for each processes
  triggers :flapping, :times => 10, :within => 1.minute

  group "samples" do
    env "A" => "1" # merging to app env 
    chain :grace => 5.seconds, :action => :restart # restarting with 5s interval, one by one.

    # eye daemonized process
    process("sample1") do
      pid_file "1.pid" # will be expanded with working_dir
      start_command "ruby ./sample.rb"
      daemonize true
      stdall "sample1.log"

      checks :cpu, :below => 30, :times => [3, 5]
    end

    # self daemonized process
    process("sample2") do
      pid_file "2.pid"
      start_command "ruby ./sample.rb -d --pid 2.pid --log sample2.log"
      stop_command "kill -9 {PID}"

      checks :memory, :below => 300.megabytes, :times => 3
    end
  end

  # daemon with 3 childs
  process("forking") do
    pid_file "forking.pid"
    start_command "ruby ./forking.rb start"
    stop_command "ruby forking.rb stop"
    stdall "forking.log"

    start_timeout 5.seconds
    stop_grace 5.seconds
  
    monitor_children do
      restart_command "kill -2 {PID}" # for this child process
      checks :memory, :below => 300.megabytes, :times => 3
    end
  end
  
  process :event_machine do |p|
    p.pid_file        = 'em.pid'
    p.start_command   = 'ruby em.rb'
    p.stdout          = 'em.log'
    p.daemonize       = true
    p.stop_signals    = [:QUIT, 2.seconds, :KILL]
    
    p.checks :socket, :addr => "tcp://127.0.0.1:33221", :every => 10.seconds, :times => 2, 
                      :timeout => 1.second, :send_data => "ping", :expect_data => /pong/
  end

  process :thin do
    pid_file "thin.pid"
    start_command "bundle exec thin start -R thin.ru -p 33233 -d -l thin.log -P thin.pid"
    stop_signals [:QUIT, 2.seconds, :TERM, 1.seconds, :KILL]

    checks :http, :url => "http://127.0.0.1:33233/hello", :pattern => /World/, :every => 5.seconds, 
                  :times => [2, 3], :timeout => 1.second
  end

end
```

### Start monitoring and load config:

    $ eye l(oad) examples/test.eye

load folder with configs:

    $ eye l examples/
    $ eye l examples/*.rb

Load also uses for config synchronization and load new application into runned eye daemon. Light operation, so i recommend to use with every deploy (and than restart processes).
(for processes with option `stop_on_delete`, `load` becomes a tool for full config synchronization, which stopps deleted from config processes).


Process statuses:
  
    $ eye i(nfo)

```
test                       
  samples                          
    sample1 ....................... up  (21:52, 0%, 13Mb, <4107>)
    sample2 ....................... up  (21:52, 0%, 12Mb, <4142>)
  event_machine ................... up  (21:52, 3%, 26Mb, <4112>)
  forking ......................... up  (21:52, 0%, 41Mb, <4203>)
    child-4206 .................... up  (21:52, 0%, 41Mb, <4206>)
    child-4211 .................... up  (21:52, 0%, 41Mb, <4211>)
    child-4214 .................... up  (21:52, 0%, 41Mb, <4214>)
  thin ............................ up  (21:53, 2%, 54Mb, <4228>)
```

### Commands:
    
    start, stop, restart, delete, monitor, unmonitor

Command params (with restart for example):

    $ eye r(estart) all
    $ eye r test
    $ eye r samples
    $ eye r sample1
    $ eye r sample*
    $ eye r test:samples
    $ eye r test:samples:sample1
    $ eye r test:samples:sample*
    $ eye r test:*sample*

Check config syntax:

    $ eye c(heck) examples/test.eye

Log tracing:

    $ eye trace 
    $ eye tr test
    $ eye tr sample

Quit monitoring:

    $ eye q(uit)

Config explain (for debug):

    $ eye explain examples/test.eye
