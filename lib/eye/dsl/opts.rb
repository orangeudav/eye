class Eye::Dsl::Opts < Eye::Dsl::PureOpts

  STR_OPTIONS = [ :pid_file, :working_dir, :stdout, :stderr, :stdall, :start_command, 
    :stop_command, :restart_command, :uid, :gid ]

  create_options_methods(STR_OPTIONS, String)

  BOOL_OPTIONS = [ :daemonize, :keep_alive, :control_pid, :auto_start, :stop_on_delete]

  create_options_methods(BOOL_OPTIONS, [TrueClass, FalseClass])

  INTERVAL_OPTIONS = [ :check_alive_period, :start_timeout, :restart_timeout, :stop_timeout, :start_grace,
    :restart_grace, :stop_grace, :childs_update_period ]

  create_options_methods(INTERVAL_OPTIONS, [Fixnum, Float])

  OTHER_OPTIONS = [ :environment, :stop_signals ]

  create_options_methods(OTHER_OPTIONS)



  def initialize(name = nil, parent = nil)
    super(name, parent)

    # ensure delete subobjects which can appears from parent config
    @config.delete :groups
    @config.delete :processes

    @config[:application] = parent.name if parent.is_a?(Eye::Dsl::ApplicationOpts)
    @config[:group] = parent.name if parent.is_a?(Eye::Dsl::GroupOpts)

    # hack for full name
    @full_name = parent.full_name if @name == '__default__'
  end

  def checks(type, opts = {})
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown checker type #{type}" unless Eye::Checker::TYPES[type]

    opts.merge!(:type => type)
    Eye::Checker.validate!(opts)
    
    @config[:checks] ||= {}
    @config[:checks][type] = opts
  end

  def triggers(type, opts = {})
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown trigger type #{type}" unless Eye::Trigger::TYPES[type]
    
    opts.merge!(:type => type)
    Eye::Trigger.validate!(opts)

    @config[:triggers] ||= {}
    @config[:triggers][type] = opts
  end

  # clear checks from parent
  def nochecks(type)
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown checker type #{type}" unless Eye::Checker::TYPES[type]
    @config[:checks].try :delete, type
  end

  # clear triggers from parent
  def notriggers(type)
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown trigger type #{type}" unless Eye::Trigger::TYPES[type]
    @config[:triggers].try :delete, type
  end

  def set_environment(value)
    raise Eye::Dsl::Error, "environment should be a hash, but not #{value.inspect}" unless value.is_a?(Hash)
    @config[:environment] ||= {}
    @config[:environment].merge!(value)
  end

  alias :env :environment

  def set_stdall(value)
    super

    set_stdout value
    set_stderr value
  end

end
