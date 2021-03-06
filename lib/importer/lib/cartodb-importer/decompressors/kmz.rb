module CartoDB
  module Import
    class KMZ < CartoDB::Import::Decompressor
      #TODO: do we really need this still?
      register_decompressor :kmz

      def process!
        log "Importing zip file: #{@path}"
        @data_import = DataImport.find(:id=>@data_import_id)
        @data_import.log_update("decompressing file #{@path}")

        # generate a temp file for import
        tmp_dir = temporary_filename

        import_data = []
        Zip::ZipFile.foreach(@path) do |entry|
          name = entry.name.split('/').last
          orig = name
          next if name =~ /^(\.|\_{2})/

          # cleans spaces out of archived file names
          if name.include? ' '
            name = name.gsub(' ','_')
          end

          #fixes problem of different SHP archive files with different case patterns
          FileUtils.mv("#{path}/#{orig}", "#{path}/#{name.downcase}") unless name == orig.downcase
          name = name.downcase

          # temporary filename. no collisions.
          tmp_path = "#{tmp_dir}.#{name}"

          if CartoDB::Importer::SUPPORTED_FORMATS.include?(File.extname(name))
            unless @suggested_name.nil?
              suggested = @suggested_name
            else
              suggested = File.basename( name, File.extname(name)).sanitize
            end
            import_data << {
              :ext => File.extname(name),
              :suggested_name => suggested,
              :path => tmp_path
            }
            log "Found original @ext file named #{name} in path #{@path}"
          end
          entry.extract(tmp_path)
        end

        # construct return variables
        import_data
      end
    end
  end
end
