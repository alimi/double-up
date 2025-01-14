class EstablishMatchesForGroupingJob
  def initialize(config: nil)
    @loads_slack_channels = Slack::LoadsSlackChannels.new
    @loads_slack_channel_members = Slack::LoadsSlackChannelMembers.new
    @matches_participants = Matchmaking::MatchesParticipants.new(config: config)

    @config = config || Rails.application.config.x.matchmaking
  end

  def perform(grouping:)
    channel = channel_for_grouping(grouping)

    matches = @matches_participants.call(
      grouping: grouping,
      participant_ids: @loads_slack_channel_members.call(channel: channel.id)
    )
    matches.each do |match|
      HistoricalMatch.create(
        members: match.members,
        grouping: grouping,
        matched_on: Date.today,
        pending_notifications: [
          PendingNotification.create(strategy: "email"),
          PendingNotification.create(strategy: "slack")
        ]
      )
    end
  rescue => e
    ReportsError.report(e)
  end

  private

  def channel_for_grouping(grouping)
    grouping_sym = grouping.intern

    raise "No config found for grouping '#{grouping}'" unless @config.respond_to?(grouping_sym)

    channel_name = @config.send(grouping_sym)&.channel
    raise "No configured channel for grouping '#{grouping}'" unless channel_name

    @loads_slack_channels.call(types: "public_channel").find { |channel|
      channel.name_normalized == channel_name
    }
  end
end
