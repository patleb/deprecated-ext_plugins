namespace :ext_pages do
  desc 'synchronize templates'
  task :synchronize_templates => :environment do
    ActiveRecord::Base.transaction do
      pages = []
      PagesYml.load.pages_types.each do |name, type|
        pages << template = (Page::Template.find_or_create_by! view_path: "pages/#{name}" do |page|
          page.layout = Page::Layout.find_or_create_by! view_path: "layouts/#{PagesYml.pages_layout}"
        end)
        template.pages.create!(type: type.name) unless template.pages.exists?
      end
      Page::Template.where.not(id: pages.map(&:id)).each(&:nuke!)
    end
  end
end
