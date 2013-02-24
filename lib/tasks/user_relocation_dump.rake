# encoding: utf-8
require_relative './relocator/dump'

namespace :user do
  namespace :relocation do
    desc 'Dump user data from CartoDB and upload it to S3'
    task :dump, [:user_id] => [:environment] do |task, args|
      pg_dump_command =   "pg_dump"
      user_id         =   args[:user_id]
      environment     =   Rails.env
      connection      =   Rails::Sequel.connection

      CartoDB::Relocator::Dump.new(
        pg_dump_command:  pg_dump_command,
        user_id:          user_id,
        environment:      environment,
        connection:       connection
      ).run
    end # dump
  end # relocate
end # user

