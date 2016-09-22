require 'terminal-table'
require 'nokogiri'
require 'colorize'

module Fastlane

  module Actions

    class PrettyJunitAction < Action

      def self.run(params)
        file_pattern = params[:file_pattern]
        UI.message "Searching for JUnit XML files with pattern \"#{file_pattern}\""

        matching_files = Dir.glob(file_pattern)
        UI.user_error! "No files found! Did your project compile?" unless matching_files.any? 
        UI.message "Processing files: #{matching_files.join(", ")}"

        all_results = []
        headings = ['', 'Context', 'Test', 'Duration']
        table = Terminal::Table.new(title: "Test Results", headings: headings) do |t|

          matching_files.each do |file|

            results = nil
            begin
              results = Helper::PrettyJunitHelper.parse_junit_xml(file)
              all_results << results
            rescue Exception => ex
              UI.crash! "An error occurred while trying to parse \"#{file}\": #{ex}"
            end

            results.passed.each do |result|
              t.add_row ['✅', result.context.green, result.name.green, result.duration.green]
            end
            results.skipped.each do |result|
              t.add_row ['❔', result.context, result.name, result.duration]
            end
            results.failed.each do |result|
              t.add_row ['❌', result.context.red, result.name.red, result.duration.red]
            end
          end
        end

        all_failed = all_results.map{ |r| r.failed }.flatten
        all_failed.each do |failed|
          UI.error "Failed #{failed.class_path}.#{failed.name} with message: \n#{failed.fail_message}\nStack trace:\n#{failed.stack_trace}\n"
        end

        UI.message "\n#{table}\n"

        all_failed.each do |failed|
          UI.error "Failed #{failed.class_path}.#{failed.name} with message:\n\n#{failed.fail_message}\nSee above for stack trace.\n"
        end

        failed_count = all_results.inject(0) { |sum, r| sum + r.failed.length }
        skipped_count = all_results.inject(0) { |sum, r| sum + r.skipped.length }
        passed_count = all_results.inject(0) { |sum, r| sum + r.passed.length }

        messages = []
        messages << "#{passed_count} passed".green
        messages << "#{skipped_count} skipped"
        messages << "#{failed_count} failed".red
        test_counts = "#{messages.join(', ')}"

        if failed_count == 0
          message = "All tests passed!".green
          UI.message "#{message} #{test_counts}"
        else
          message = "You have failing tests!".red
          UI.user_error! "#{message} #{test_counts}"
        end
      end

      def self.description
        "Pretty JUnit test results for your Android projects."
      end

      def self.details
        "Pretty prints JUnit test results for your Android projects. You should make sure that the previous test results are deleted before running the gradle action, and that the grade action does not fail the lane on test failure. To delete the files, you can use the delete_files plugin and pass in the same file pattern that you pass to this action. To prevent the gradle action from failing on test failure, you can hack around it by appending '|| true' to the end of the 'flags' argument."
      end

      def self.authors
        ["Gary Johnson"]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :file_pattern,
                                       description: "Glob file pattern to search for junit-style xml files")
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
