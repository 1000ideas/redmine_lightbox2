require_dependency 'issue'

module RedmineLightbox2
  module IssuesPatch
    def self.included(base)
      base.class_eval do
        unloadable

        def download_zip
          issue = Issue.find(params[:id])

          filename = "issue_#{issue.id}_attachments.zip"
          temp_file = Tempfile.new(filename)

          Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip_file|
            issue.attachments.each do |att|

              puts zip_file.read(att.diskfile)
            end
          end

          zip_data = File.read(temp_file.path)
          send_file(zip_data, type: 'application/zip', filename: filename, disposition: 'attachment')
        end
      end
    end
  end
end
