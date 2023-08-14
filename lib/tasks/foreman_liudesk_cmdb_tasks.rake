# frozen_string_literal: true

require "rake/testtask"

namespace :foreman_liudesk_cmdb do
  namespace :sync do
    desc "Example Task"
    task full: :environment do
      User.as_anonymous_admin do
        Host::Managed.where(managed: true).each do |host|
          unless host.liudesk_cmdb_facet.asset_params_diff.empty?
            puts "Nothing to push for #{host.name}"
            next
          end

          puts "Pushing #{host.name} to LiudeskCMDB"
          result = ForemanLiudeskCMDB::SyncAsset::Organizer.call(host: host)

          if result.success?
            puts "#{host.name} pushed"
          else
            puts "Failed to push #{host.name}: #{result.error}"
          end
        end
      end
    end
  end
end

# Tests
namespace :test do
  desc "Test ForemanLiudeskCMDB"
  Rake::TestTask.new(:foreman_liudesk_cmdb) do |t|
    test_dir = File.join(File.dirname(File.dirname(__dir__)), "test")
    t.libs << ["test", test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
    t.warning = false
  end

  namespace :foreman_liudesk_cmdb do
    task :coverage do
      ENV["COVERAGE"] = "1"

      Rake::Task["test:foreman_liudesk_cmdb"].invoke
    end
  end
end

namespace :foreman_liudesk_cmdb do
  task rubocop: :environment do
    begin
      require "rubocop/rake_task"
      RuboCop::RakeTask.new(:rubocop_foreman_liudesk_cmdb) do |task|
        task.patterns = ["#{ForemanLiudeskCMDB::Engine.root}/app/**/*.rb",
                         "#{ForemanLiudeskCMDB::Engine.root}/lib/**/*.rb",
                         "#{ForemanLiudeskCMDB::Engine.root}/test/**/*.rb"]
      end
    rescue StandardError
      puts "Rubocop not loaded."
    end

    Rake::Task["rubocop_foreman_liudesk_cmdb"].invoke
  end
end

Rake::Task[:test].enhance ["test:foreman_liudesk_cmdb"]
# Rake::Task[:coverage].enhance ["coverage:foreman_liudesk_cmdb"]
