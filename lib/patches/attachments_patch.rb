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
      end
    end
  end
end
