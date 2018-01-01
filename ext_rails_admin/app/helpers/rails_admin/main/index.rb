module RailsAdmin
  module Main
    class Index < Base[:@objects]
      def filter_box
        @_filter_box ||= FilterBox.new(view)
      end

      def sortable_options(property)
        selected = (@sort == property.name.to_s)
        if property.sortable
          index_params = params.except(:sort_reverse, :page, :per, :first)
            .merge(sort: property.name)
            .merge(selected && @sort_reverse != "true" ? {sort_reverse: "true"} : {})
          sort_location = index_path(index_params)
          sort_direction = (@sort_reverse == 'true' ? "headerSortUp" : "headerSortDown" if selected)
        end
        {
          class: [
            property.sortable && "header pjax" || nil,
            (property.sortable && sort_direction) ? sort_direction : nil,
          ],
          'data-href': (property.sortable && sort_location),
        }
      end

      def paginate_options
        per_page = (params[:per] || list_config.items_per_page).to_i
        page_count = @objects.size
        if (total_count = list_config.total_count)
          total_pages = (total_count.to_f / per_page).ceil
        else
          total_count = @objects.total_count.to_i
        end
        pluralized_name = @model_config.pluralize(total_count).downcase
        current_page = (params[:page] || 1).to_i
        current_count = current_page == 1 ? page_count : page_count + (current_page - 1) * per_page
        if list_config.freeze_first?
          first_item = if current_page == 1
            if (value = @objects.first.try(@sort || sort_by_default)).respond_to? :utc
              value = value.utc
            end
            value
          else
            params[:first]
          end
        end
        [page_count, current_count, total_count, pluralized_name, total_pages, first_item]
      end

      def inline_create_action
        @model_config.create.inline_create? && params[:page].blank?
      end

      def description
        @_description ||= RailsAdmin.config(@abstract_model.model_name).description
      end

      def properties
        @_properties ||= list_config.visible_fields
      end

      def params
        @_params ||= begin
          params = super.to_unsafe_h.slice(:model_name, :scope, :query, :f, :sort, :sort_reverse, :page, :per, :first)
          params.delete(:query) if params[:query].blank?
          params.delete(:sort_reverse) unless params[:sort_reverse].to_b
          @sort_reverse = params[:sort_reverse]
          @sort = params[:sort]
          params.delete(:sort) if params[:sort] == sort_by_default
          params
        end
      end

      private

      def list_config
        @_list_config ||= @model_config.list.with(controller: controller, view: view, object: @abstract_model.model.new, list: @objects)
      end

      def sort_by_default
        @_sort_by_default ||= list_config.sort_by.to_s
      end
    end
  end
end