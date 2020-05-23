require_relative 'user_notification_service.rb'

file_path = ARGV[0] || nil
user_id = ARGV[1] || nil
UserNotificationService.new(file_path, user_id).get_notifications_for_user
