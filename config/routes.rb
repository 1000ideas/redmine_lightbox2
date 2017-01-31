if Gem::Version.new("3.0") > Gem::Version.new(Rails.version) then
  #Redmine 1.x
  ActionController::Routing::Routes.draw do |map|
    map.connect 'attachments/download_inline/:id/:filename', :controller => 'attachments', :action => 'download_inline', :id => /\d+/, :filename => /.*/
    map.connect 'attachments/download_att/:id/:filename', :controller => 'attachments', :action => 'download_att', :id => /\d+/, :filename => /.*/
    map.connect 'attachments/:id/download_zip', :controller => 'attachments', :action => 'download_zip', :id => /\d+/
  end
else
  #Redmine 2.x
  RedmineApp::Application.routes.draw do
    get 'attachments/download_inline/:id/:filename', :controller => 'attachments', :action => 'download_inline', :id => /\d+/, :filename => /.*/
    get 'attachments/download_att/:id/:filename', :controller => 'attachments', :action => 'download_att', :id => /\d+/, :filename => /.*/
    get 'attachments/download_zip/:id', :controller => 'attachments', :action => 'download_zip', :id => /\d+/
  end
end
