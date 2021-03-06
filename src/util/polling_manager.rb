#!/usr/bin/env ruby
# Util::PollingManager -- xmlconv2 -- 29.06.2004 -- hwyss@ywesee.com

require 'fileutils'
require 'uri'
require 'yaml'
require 'util/destination'
require 'util/transaction'

module XmlConv
	module Util
		class PollingMission
			attr_accessor :directory, :reader, :writer, :destination, 
                    :error_recipients, :debug_recipients, :backup_dir,
                    :glob_pattern, :partner
		end
		class PollingManager
			PROJECT_ROOT = File.expand_path('../..', File.dirname(__FILE__))
			CONFIG_PATH = File.expand_path('etc/polling.yaml', PROJECT_ROOT)
			def initialize(system)
				@system = system
			end
			def destination(str)
				uri = URI.parse(str)
				case uri
				when URI::HTTP
					dest = DestinationHttp.new
					dest.uri = uri
					dest
				else
					dest = DestinationDir.new
					dest.path = str
					dest
				end
			end
			def load_sources(&block)
				file = File.open(self::class::CONFIG_PATH)
				YAML.load_documents(file) { |mission|
					path = File.expand_path(mission.directory, PROJECT_ROOT)
					mission.directory = path
					block.call(mission)
				}
			ensure
				file.close if(file)
			end
			def file_paths(dir_path, pattern=nil)
				Dir.glob(File.expand_path(pattern || '*', dir_path)).collect { |entry|
					File.expand_path(entry, dir_path)
				}.compact
			end
			def poll(source)
				file_paths(source.directory, source.glob_pattern).each { |path|
					begin
						transaction = XmlConv::Util::Transaction.new
						transaction.input = File.read(path)
						transaction.partner = source.partner
						transaction.origin = 'file:' << path
						transaction.reader = source.reader
						transaction.writer = source.writer
						transaction.destination = destination(source.destination)
						transaction.debug_recipients = source.debug_recipients
						transaction.error_recipients = source.error_recipients
						@system.execute(transaction)
					ensure
						backup_dir = source.backup_dir
						FileUtils.mkdir_p(backup_dir)
						FileUtils.mv(path, backup_dir)
					end
				}
			end
			def poll_sources
				load_sources { |source|
					poll(source)
				}
			end
		end
	end
end
