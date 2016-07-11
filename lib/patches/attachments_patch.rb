require_dependency 'attachment'

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
          name = attachment.instance.disk_filename.split('.').first
          style.to_s.downcase == 'thumb' ? "#{style.to_s.capitalize}_#{name}" : "#{name}"
        end
        has_attached_file :file, styles: { thumb: '200x100' },
                          url: "/files/:year/:month/:disk_filename.:extension",
                          path: ":rails_root:url"

        def raw_file=(incoming_file)
          @temp_file = incoming_file
          self.filesize = @temp_file.size
        end

        def files_to_final_location
          self.disk_directory = target_directory
          self.disk_filename = Attachment.disk_filename(filename, disk_directory)
          if @temp_file && (@temp_file.size > 0)
            md5 = Digest::MD5.new
            if @temp_file.respond_to?(:read)
              buffer = ""
              while (buffer = @temp_file.read(8192))
                md5.update(buffer)
              end
            else
              md5.update(@temp_file)
            end
            self.digest = md5.hexdigest
          end

          if content_type.blank? && filename.present?
            self.content_type = Redmine::MimeType.of(filename)
          end
          # Don't save the content type if it's longer than the authorized length
          if self.content_type && self.content_type.length > 255
            self.content_type = nil
          end
        end
      end
    end
  end
end