namespace :lightbox do
  desc 'Enable table_it plugin for all existing projects'
  task populate_paperclip_columns: [:environment] do
    Attachment.all.each do |at|
      next unless at.image?
      at.file_file_name = at.filename
      at.file_content_type = at.content_type
      at.file_file_size = at.filesize
      at.file_updated_at = Time.now
      at.save
    end
  end
end
