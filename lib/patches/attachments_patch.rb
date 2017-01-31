require_dependency 'attachment'
require 'zip'

module RedmineLightbox2
  module AttachmentsPatch
    def self.included(base) # :nodoc:
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        def download_inline
          send_file @attachment.diskfile, :filename => filename_for_content_disposition(@attachment.filename),
                    :type => detect_content_type(@attachment),
                    :disposition => 'inline'
        end

        def download_att
          send_file @attachment.diskfile, :filename => filename_for_content_disposition(@attachment.filename),
                    :type => detect_content_type(@attachment),
                    :disposition => 'attachment'
        end

        def download_zip
          attachments = @attachment.container.attachments

          filename = "#{@attachment.container.id}_zalaczniki.zip"
          temp_file = Tempfile.new(filename)

          Zip::OutputStream.open(temp_file.path) do |zip|
            attachments.each do |att|
              zip.put_next_entry(att.filename)
              zip.print(IO.read(att.diskfile))
            end
          end

          send_file(temp_file.path, type: 'application/zip', filename: filename, disposition: 'attachment')
          temp_file.close
        end

        def upload
          # Make sure that API users get used to set this content type
          # as it won't trigger Rails' automatic parsing of the request body for parameters
          unless request.content_type == 'application/octet-stream'
            render :nothing => true, :status => 406
            return
          end

          ext = params[:filename].split('.').last

          if image? ext
            temp = StringIO.new(request.raw_post)
            temp.singleton_class.class_eval { attr_accessor :original_filename, :content_type }
            temp.original_filename = params[:filename]
            temp.content_type = Mime::Type.lookup_by_extension(ext)
          end

          @attachment = Attachment.new(file: temp, raw_file: request.raw_post)
          @attachment.author = User.current
          @attachment.filename = params[:filename].presence || Redmine::Utils.random_hex(16)
          saved = @attachment.save

          respond_to do |format|
            format.js
            format.api {
              if saved
                render :action => 'upload', :status => :created
              else
                render_validation_errors(@attachment)
              end
            }
          end
        end

        private

        def image?(ext)
          ext =~ /(bmp|gif|jpg|jpe|jpeg|png)/i
        end
      end
    end
  end

  module AttachmentModelPatch
    def self.included(base)
      base.class_eval do
        Paperclip.interpolates :year do |attachment, style|
          attachment.instance.created_on.year
        end
        Paperclip.interpolates :month do |attachment, style|
          month = attachment.instance.created_on.month
          month.to_s.size == 1 ? "0#{month}" : "#{month}"
        end
        Paperclip.interpolates :disk_filename do |attachment, style|
          name = attachment.instance.disk_filename
          style.to_s.downcase == 'original' ? "#{name}" : "#{style.to_s.downcase}_#{name}"
        end
        has_attached_file :file, styles: { thumb: '200x100' },
                          url: "/files/:year/:month/:disk_filename",
                          path: ":rails_root:url"

        def raw_file=(incoming_file)
          @temp_file = incoming_file
          self.filesize = @temp_file.size
        end

        def files_to_final_location
          if @temp_file && (@temp_file.size > 0)
            self.disk_directory = target_directory
            self.disk_filename = Attachment.disk_filename(filename, disk_directory)
            if self.filename.split('.').last =~ /(bmp|gif|jpg|jpe|jpeg|png)/i
              self.digest = md5_image_file
            else
              self.digest = md5_non_image_file
            end
          end

          if content_type.blank? && filename.present?
            self.content_type = Redmine::MimeType.of(filename)
          end
          # Don't save the content type if it's longer than the authorized length
          if self.content_type && self.content_type.length > 255
            self.content_type = nil
          end
        end

        private

        def md5_image_file
          md5 = Digest::MD5.new
          if @temp_file.respond_to?(:read)
            buffer = ""
            while (buffer = @temp_file.read(8192))
              md5.update(buffer)
            end
          else
            md5.update(@temp_file)
          end
          md5.hexdigest
        end

        def md5_non_image_file
          path = File.dirname(diskfile)
          unless File.directory?(path)
            FileUtils.mkdir_p(path)
          end
          md5 = Digest::MD5.new
          File.open(diskfile, "wb") do |f|
            if @temp_file.respond_to?(:read)
              buffer = ""
              while (buffer = @temp_file.read(8192))
                f.write(buffer)
                md5.update(buffer)
              end
            else
              f.write(@temp_file)
              md5.update(@temp_file)
            end
          end
          md5.hexdigest
        end
      end
    end
  end
end
