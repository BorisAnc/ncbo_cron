require 'ostruct'

module NcboCron
  extend self
  attr_reader :settings

  @settings = OpenStruct.new
  @settings_run = false
  def config(&block)
    return if @settings_run
    @settings_run = true

    # Redis is used for two separate things in ncbo_cron:
    # 1) locating the queue for the submissions to be processed and
    # 2) managing the processing lock.
    @settings.redis_host ||= "localhost"
    @settings.redis_port ||= 6379
    puts "(CR) >> Using Redis instance at #{@settings.redis_host}:#{@settings.redis_port}"

    # Daemon
    @settings.daemonize ||= true
    # REPL for working with scheduler
    @settings.console ||= false
    # submission id to add to the queue
    @settings.queue_submission ||= nil
    # view queued jobs
    @settings.view_queue ||= false
    @settings.enable_processing ||= true
    @settings.enable_pull ||= true
    @settings.enable_flush ||= true
    # Don't remove graphs from deleted ontologies by default when flushing classes
    @settings.remove_zombie_graphs ||= false
    @settings.enable_warmq ||= true
    @settings.enable_mapping_counts ||= true
    # enable ontology analytics
    @settings.enable_ontology_analytics ||= true
    # enable ontologies report
    @settings.enable_ontologies_report ||= true
    # enable SPAM deletion
    @settings.enable_spam_deletion ||= true
    # UMLS auto-pull
    @settings.pull_umls_url ||= ""
    @settings.enable_pull_umls ||= false

    # Schedules
    # 30 */4 * * * - run every 4 hours, starting at 00:30
    @settings.cron_schedule ||= "30 */4 * * *"
    # Pull schedule.
    # 00 18 * * * - run daily at 6 a.m. (18:00)
    @settings.pull_schedule ||= "00 18 * * *"
    # run weekly on monday at 11 a.m. (23:00)
    @settings.pull_schedule_long ||= "00 23 * * 1"
    @settings.pull_long_ontologies ||= []
    # Delete class graphs of archive submissions.
    # 00 22 * * 2 - run once per week on tuesday at 10 a.m. (22:00)
    @settings.cron_flush ||= "00 22 * * 2"
    # Warmup long time running queries.
    # 00 */3 * * * - run every 3 hours (beginning at 00:00)
    @settings.cron_warmq ||= "00 */3 * * *"
    # Create mapping counts schedule
    # 30 0 * * 6 - run once per week on Saturday at 12:30AM
    @settings.cron_mapping_counts ||= "30 0 * * 6"
    # Ontology analytics refresh schedule
    # 15 0 * * 1 - run once a week on Monday at 12:15AM
    @settings.cron_ontology_analytics ||= "15 0 * * 1"
    # Ontologies report generation schedule
    # 30 1 * * * - run daily at 1:30AM
    @settings.cron_ontologies_report ||= "30 1 * * *"
    # Ontologies Report file location
    @settings.ontology_report_path = "../../reports/ontologies_report.json"
    # 30 2 * * * - run daily at 2:30AM
    @settings.cron_spam_deletion ||= "30 2 * * *"

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
    @settings.minutes_between ||= 5
    # seconds between process queue checks
    @settings.seconds_between ||= nil

    # Override defaults
    yield @settings if block_given?
  end
end
