# frozen_string_literal: true

require_relative '../user_notification_service.rb'

describe UserNotificationService do
  before(:each) do
    @default_user_id = 'hackamorevisiting'
    @latest_created_at = 1_574_325_866_040
  end

  context 'invalid arguments' do
    it 'should raise an error when missing arguments' do
      expect do
        UserNotificationService.new('./notifications.json')
      end.to raise_error ArgumentError, /wrong number of arguments/
    end

    it 'should raise an error when any argument is nil' do
      expect do
        UserNotificationService.new('./test_files/notifications.json', nil)
      end.to raise_error ArgumentError, /Invalid arguments/
    end

    it 'should raise an error while file path does not exist' do
      expect do
        UserNotificationService.new('test.json', @default_user_id)
      end.to raise_error ArgumentError, /File path does not exist/
    end

    it 'should raise an error while file extension is invalid' do
      expect do
        UserNotificationService.new('./notification.rb', @default_user_id)
      end.to raise_error ArgumentError, /Invalid file extension. Expected .json, got .rb/
    end

    it 'should not raise an error while file path is valid' do
      expect do
        UserNotificationService.new('./test_files/notifications.json', @default_user_id)
      end.not_to raise_error
    end
  end

  context 'valid arguments' do
    it 'should return empty array for empty file' do
      output = UserNotificationService
               .new('./test_files/empty-file.json', @default_user_id)
               .get_notifications_for_user
      expect(output).to be_empty
    end

    it 'should return empty array for empty array' do
      output = UserNotificationService
               .new('./test_files/empty-array.json', @default_user_id)
               .get_notifications_for_user
      expect(output).to be_empty
    end

    it 'should return unique senders for duplicate senders of same questions' do
      target_id = 46
      noti_type = 2
      sender = 'makerchorse'

      obj = UserNotificationService
            .new('./test_files/duplicate-senders.json', @default_user_id)
      processed_input = obj.process_input
      sender_list = processed_input[target_id][noti_type]['sender_list']

      # Duplicate sender
      expect(sender_list.length).to eq(2)
      expect(sender_list[0]).to eq(sender)
      expect(sender_list[1]).to eq(sender)

      time_output_dict = obj.determine_output_by_type(processed_input)
      output = time_output_dict[@latest_created_at]

      expect(output.length).to eq(1)
      expect(output[0]).to eq("#{sender} commented on a question\n")
    end

    it 'should return all notifications created at the same time' do
      obj = UserNotificationService
            .new('./test_files/same-created-at-notifications.json', @default_user_id)
      processed_input = obj.process_input
      time_output_dict = obj.determine_output_by_type(processed_input)
      output = time_output_dict[@latest_created_at]

      expect(output.length).to eq(2)
    end
  end
end
