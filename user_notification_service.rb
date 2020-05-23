# frozen_string_literal: true

require 'json'
require 'time'

class UserNotificationService
  attr_accessor :file_path, :user_id

  POST_ANSWER = 1
  POST_COMMENT = 2
  UPVOTE_ANSWER = 3
  SENDER_TYPE = 'User'
  TARGET_TYPE = 'Question'
  DATE_TIME_FORMAT = '%Y-%m-%d %H:%M:%S'

  def initialize(file_path, user_id)
    raise ArgumentError, 'Invalid arguments' if file_path.nil? || user_id.nil?
    unless File.exist?(file_path)
      raise ArgumentError, 'File path does not exist'
    end

    file_extension = File.extname(file_path)
    unless file_extension == '.json'
      raise ArgumentError, "Invalid file extension. Expected .json, got #{file_extension}"
    end

    @file_path = file_path
    @user_id = user_id
  end

  def get_notifications_for_user
    processed_input = process_input
    time_output_dict = determine_output_by_type(processed_input)
    print_sorted_output(time_output_dict)
  end

  def process_input
    notification_arr =
      begin
        json_from_file = File.read(@file_path)
        JSON.parse(json_from_file)
      rescue JSON::ParserError
        # Handle invalid file
        []
      end
    merge_input_notifications(notification_arr)
  end

  def determine_output_by_type(result)
    time_output_dict = {}
    result.each do |_question, q_item|
      q_item.each do |noti_type, n_item|
        output_str = ''
        created_at = n_item['created_at']
        # Unique sender list
        sender_str = n_item['sender_list'].uniq.join(', ')

        case noti_type
        when POST_ANSWER
          output_str = "#{sender_str} answered a question\n"
        when POST_COMMENT
          output_str = "#{sender_str} commented on a question\n"
        when UPVOTE_ANSWER
          output_str = "#{sender_str} upvoted a question\n"
        else
          # Future implementation for new types
          next
        end

        # Handle output created at the same time
        # { created_at: [output1, output2] }
        output_list = time_output_dict.fetch(created_at, [])
        output_list.unshift(output_str)
        time_output_dict[created_at] = output_list
      end
    end
    time_output_dict
  end

  private def merge_input_notifications(notification_arr)
    # Dictionary Structure
    # {
    #   question_id: {
    #     noti_type: {
    #       'sender_list': [sender1, sender2],
    #       'created_at': latest_date
    #     }
    #   }
    # }
    result = {}
    notification_arr.each do |noti|
      # Retrieve only notifications for input user_id
      # Notification should not be sent to myself if I trigger the notification
      next if noti['user_id'] != @user_id || noti['sender_id'] == @user_id

      question_id = noti['target_id']
      result[question_id] = result.fetch(question_id, {})

      noti_type = noti['notification_type_id']
      result[question_id][noti_type] = result[question_id].fetch(noti_type, {})

      sender_list = result[question_id][noti_type].fetch('sender_list', [])
      sender_list.unshift(noti['sender_id'])
      result[question_id][noti_type]['sender_list'] = sender_list

      created_at = noti['created_at']
      latest_created_at = result[question_id][noti_type].fetch('created_at', 0)
      # Update the latest created_at
      if latest_created_at < created_at
        result[question_id][noti_type]['created_at'] = created_at
      end
    end
    result
  end

  private def print_sorted_output(time_output_dict)
    sorted_hash = Hash[time_output_dict.sort_by { |k, _v| k }]
    sorted_hash.each do |created_at, output_list|
      formatted_created_at = Time.at(created_at / 1000.0).strftime(DATE_TIME_FORMAT)
      output_list.each do |output|
        puts "[#{formatted_created_at}] #{output}"
      end
    end
  end
end
