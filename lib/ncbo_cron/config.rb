require 'ostruct'

module NcboCron
  extend self
  attr_reader :settings

  @settings = OpenStruct.new
  @settings_run = false
  def config(&block)
    return if @settings_run
    @settings_run = true

    yield @settings if block_given?

    # Redis is used for two separate things in ncbo_cron:
    # 1) locating the queue for the submissions to be processed and
    # 2) managing the processing lock.
    @settings.redis_host ||= "localhost"
    @settings.redis_port ||= 6379
    puts "(CRON) >> Using Redis instance at #{@settings.redis_host}:#{@settings.redis_port}"

    # REPL for working with scheduler
    @settings.console ||= false
    # submission id to add to the queue
    @settings.queue_submission ||= nil
    # view queued jobs
    @settings.view_queue ||= false

    @settings.enable_processing ||= true
    @settings.enable_pull ||= true
    @settings.enable_flush ||= true
    @settings.enable_warmq ||= true
    # UMLS auto-pull
    @settings.pull_umls_url ||= ""
    @settings.enable_pull_umls ||= false

    # Schedulues
    @settings.cron_schedule ||= "30 */4 * * *"
    # Delete class graphs of archive submissions
    @settings.cron_flush ||= "00 23 * * 1-5"
    # Warmup long time running queries
    @settings.cron_warmq ||= "00 */4 * * *"
    # annotator cache and dictionary rebuild
    @settings.enable_annotator_dictionary_rebuild ||= true
    @settings.annotator_dictionary_rebuild_schedule ||= "0 0 */3 * *" # 3 days

    @settings.log_level ||= :info
    unless (@settings.log_path && File.exists?(@settings.log_path))
      log_dir = File.expand_path("../../../logs", __FILE__)
      FileUtils.mkdir_p(log_dir)
      @settings.log_path = "#{log_dir}/scheduler.log"
    end
    if File.exists?("/var/run/ncbo_cron")
      pid_path = File.expand_path("/var/run/ncbo_cron/ncbo_cron.pid", __FILE__)
    else
      pid_path = File.expand_path("../../../ncbo_cron.pid", __FILE__)
    end
    @settings.pid_path ||= pid_path

    # minutes between process queue checks (override seconds)
    @settings.minutes_between ||= nil
    # seconds between process queue checks
    @settings.seconds_between ||= nil

  end
end


