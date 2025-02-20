# frozen_string_literal: true

require "rake/testtask"

namespace :foreman_liudesk_cmdb do
  namespace :sync do
    desc "Force-sync CMDB data for all hosts"
    task all_hosts: :environment do
      User.as_anonymous_admin do
        ForemanLiudeskCMDB::LiudeskCMDBFacet.each do |facet|
          host = facet.host
          unless facet.asset_params_diff.empty?
            puts "Nothing to push for #{host.name}"
            next
          end

          puts "Pushing #{host.name} to LiudeskCMDB"
          result = ForemanLiudeskCMDB::SyncAsset::Organizer.call(host: host)

          if result.success?
            puts "#{host.name} pushed"
          else
            puts "Failed to push #{host.name}:\n  #{result.error}"
          end
        end
      end
    end

    desc "Sync CMDB data for hosts that are potentially out-of-date"
    task out_of_date: :environment do
      User.as_anonymous_admin do
        ForemanLiudeskCMDB::LiudeskCMDBFacet.each do |facet|
          next unless facet.out_of_date?

          host = facet.host
          puts "Pushing #{host.name} to LiudeskCMDB"
          result = ForemanLiudeskCMDB::SyncAsset::Organizer.call(host: host)

          if result.success?
            puts "#{host.name} pushed"
          else
            puts "Failed to push #{host.name}:\n  #{result.error}"
          end
        end
      end
    end

    desc "Update CMDB sync statuses for all hosts"
    task statuses: :environment do
      User.as_anonymous_admin do
        ids = ForemanLiudeskCMDB::LiudeskCMDBFacet.all.map { |facet| facet.host.id }

        ForemanLiudeskCMDB::RefreshCMDBStatusJob.perform_later(ids)
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
