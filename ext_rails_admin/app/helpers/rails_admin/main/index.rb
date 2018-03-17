module RailsAdmin
  module Main
    class Index < Base[:@objects]
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

      def show_all?
        total_count, page_count, total_pages, current_page = paginate_options.slice(:total_count, :page_count, :total_pages, :current_page).values
        total_count <= 100 && page_count < total_count && current_page != total_pages
      end

      def paginate_options
        @_paginate_options ||= begin
          per_page = (params[:per] || list_config.items_per_page).to_i
          page_count = @objects.size
          current_page = (params[:page] || 1).to_i
          if (total_count = list_config.total_count)
            if total_count < page_count # means that the count estimate is off
              total_pages = current_page + 1
            end
          else
            total_count = @objects.total_count.to_i
          end
          total_pages ||= (total_count.to_f / per_page).ceil
          pluralized_name = @model_config.pluralize(total_count < page_count ? page_count : total_count).downcase
          current_count = (current_page == 1) ? page_count : (page_count + (current_page - 1) * per_page)
          if list_config.from_first?
            first_item = if current_page == 1
              if (value = @objects.first.try(@sort || sort_by_default)).respond_to? :utc
                value = value.utc
              end
              value
            else
              params[:first]
            end
          end
          {
            page_count: page_count,
            current_count: current_count,
            total_count: total_count,
            pluralized_name: pluralized_name,
            current_page: current_page,
            total_pages: total_pages,
            first_item: first_item
          }
        end
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
