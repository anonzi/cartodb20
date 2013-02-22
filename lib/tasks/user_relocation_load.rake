# encoding: utf-8
require_relative './relocator/load'

namespace :user do
  namespace :relocate do
    desc 'Load user data from CartoDB and upload it to S3'
    task :load, [:relocation_id] => [:environment] do |task, args|
      environment     = Rails.env
      connection      = Rails::Sequel.connection
      psql_command    = "psql -p #{connection.port}"
      relocation_id   = args[:relocation_id]
      database_owner  = Rails.configuration.database_configuration
                          .fetch(Rails.env)
                          .fetch('username')


      CartoDB::Relocator::Load.new(
        environment:    environment,
        connection:     connection,
        psql_command:   psql_command,
        database_owner: database_owner,
        relocation_id:  relocation_id
      ).run
    end # load
  end # relocate
end # user

