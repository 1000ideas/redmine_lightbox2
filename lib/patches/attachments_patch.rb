require_dependency 'attachment'

module RedmineLightbox2
  module AttachmentsPatch
    def self.included(base) # :nodoc:
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        after_filter :add_thumbnail, only: [:upload]

        def download_inline
          send_file @attachment.diskfile, :filename => filename_for_content_disposition(@attachment.filename),
                    :type => detect_content_type(@attachment),
                    :disposition => 'inline'
        end

        private

        def add_thumbnail
          process_image
          attachment = Attachment.new(
            content_type: @attachment.content_type,
            filesize: @source.filesize,
            author_id: @attachment.author_id,
            filename: @attachment.filename
          )
          thumb_to_final_location(attachment)
          attachment.save
        end

        def process_image
          path = Rails.root.join('files', @attachment.disk_directory)
          unless File.directory?("#{path}/thumbnails")
            FileUtils.mkdir_p("#{path}/thumbnails")
          end
          @source = Magick::Image.read("#{path}/#{@attachment.disk_filename}").first
          @source = @source.resize_to_fill(200, 100)
          @source.write("#{path}/thumbnails/#{@attachment.disk_filename}")
        end

        def thumb_to_final_location(attachment)
          attachment.disk_directory = "#{@attachment.disk_directory}/thumbnails"
          attachment.disk_filename = Attachment.disk_filename(attachment.filename, attachment.disk_directory)
          md5 = Digest::MD5.new
          temp_file = ''
          File.open(attachment.diskfile, "wb") do |f|
            f.write(temp_file)
            md5.update(temp_file)
          end
          attachment.digest = md5.hexdigest
        end
      end
    end
  end
end