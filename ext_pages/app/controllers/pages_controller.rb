# TODO fresh_when
# lib/action_controller/metal/conditional_get.rb
# lib/action_dispatch/http/cache.rb

class PagesController < ExtPages.config.parent_controller.constantize
  after_action :update_cache

  def presenter_lists
    @contents
  end

  def show
    load_page
    if @page.html_cache_expired?
      load_contents
      render @page.view_path
    else
      render html: @page.html_cache.html_safe
    end
  end

  private

  def load_page
    @page = fetch_page
  end

  def load_contents
    @contents = @page.fetch_contents
  end

  def fetch_page
    if (hashid = params[:hashid]).present?
      Page.find(hashid).with_associations
    else
      Page::Template.fetch_or_create_by_view_path! "pages/#{params[:_page]}" do |page|
        page.layout = Page::Layout.find_or_create_by! view_path: "layouts/#{current_layout}"
      end
    end
  end

  def update_cache
    @page.update_html_cache! response.body if response.status == 200
  end
end
