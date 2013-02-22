# encoding: utf-8
require 'stringio'
require 'open3'
require 'uuidtools'
require 'json'
require 'pg'
require_relative './helpers'
require_relative '../../../services/data-repository/filesystem/s3/backend'
require_relative '../../../services/data-repository/filesystem/local'

module CartoDB
  module Relocator
    class Load
      include DataRepository
      include Helpers

      def initialize(arguments)
        @environment          = arguments.fetch(:environment)
        @connection           = arguments.fetch(:connection)
        @psql_command         = arguments.fetch(:psql_command)
        @relocation_id        = arguments.fetch(:relocation_id)
        @database_owner       = arguments.fetch(:database_owner)

        @tmp_dir              = File.join(File.dirname(__FILE__), '..',
                                '..', '..', 'tmp', 'relocator')
        @local_filesystem     = Filesystem::Local.new(@tmp_dir)
        @s3_filesystem        = Filesystem::S3::Backend.new

        @dump_path            = "#{relocation_id}/user_db.sql"
        @user_attributes_path = "#{relocation_id}/user.json"
      end #initialize

      def run
        to_stdout("Continuing relocation with ID: #{relocation_id}")
        to_stdout("Downloading data from Amazon S3")
        download_from_s3(dump_path)
        to_stdout("Data downloaded from Amazon S3")

        to_stdout("Downloading user attributes from Amazon S3")
        download_from_s3(user_attributes_path)

        to_stdout("Creating user with downloaded attributes")
        create_user

        to_stdout("Creating user database #{user.database_name}")
        create_user_database

        to_stdout("Loading data from filesystem to #{user.database_name}")
        load_database
        to_stdout("Renaming database user")
        rename_database_user

        to_stdout("Setting password for database user")
        set_database_user_password

        to_stdout("Finished relocation with ID: #{relocation_id}")
      end #run

      private

      attr_reader :local_filesystem, :s3_filesystem, :relocation_id,
                  :dump_path, :user, :user_attributes_path, :psql_command, 
                  :connection, :environment, :database_owner 

      def create_user
        @user = User.new
        def user.after_create; end

        json_attributes = local_filesystem.fetch(user_attributes_path)
                            .readlines.join
        JSON.parse(json_attributes).each { |k, v| @user.send(:"#{k}=", v) }

        raise 'Invalid user' unless user.valid?
        user.save
        user.database_name = "cartodb_#{environment}_user_#{user.id}_db"
        user.save
      end #create_user


      def create_database_user
        connection.run(create_database_user_sql)
      end #create_database_user

      def create_user_database
        connection.run(create_user_database_sql(owner))
      rescue => exception 
        puts 'Error!'
      end #create_user_database

      def load_database
        dump_file =  "#{@tmp_dir}/#{dump_path}"
        command   = "#{psql_command} #{user.database_name} < #{dump_file}"

        Open3.popen3(command) do |stdin, stdout, stderr, process| 
          print_and_raise(stderr) unless process.value.to_s =~ /exit 0/
        end
      end #load_database

      def rename_database_user
        connection.run(rename_database_user_sql)
      end #rename_database_user

      def set_database_user_password
        connection.run(set_database_user_password_sql)
      end #set_database_user_password

      def download_from_s3(path)
        url = url_for(path)
        local_filesystem.store(path, s3_filesystem.fetch(url))
      end #download_from_s3

      def create_database_user_sql
        "CREATE USER #{token} PASSWORD '#{user.database_password}'"
      end #create_database_user_sql

      def rename_database_user_sql
        "ALTER USER #{token} RENAME TO #{database_username}"
      end #rename_database_user_sql

      def set_database_user_password_sql
        "ALTER USER #{database_username} PASSWORD #{user.database_password}"
      end #set_database_user_password_sql

      def create_user_database_sql(owner)
        "CREATE DATABASE #{user.database_name}
        WITH TEMPLATE = template_postgis
        OWNER = #{owner}
        ENCODING = 'UTF8'
        CONNECTION LIMIT=-1"
      end #create_user_database_sql
    end # Load
  end # Relocator
end # CartoDB

