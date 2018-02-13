module RailsAdmin
  module Main
    module IndexAction
      def index
        @objects ||= list_entries
        @scopes ||= @model_config.list.scopes
        compact = params[:compact].to_b

        unless @scopes.empty?
          if params[:scope].blank?
            unless @scopes.first.nil? || compact
              @objects = @objects.public_send(@scopes.first)
            end
          elsif @scopes.map(&:to_s).include?(params[:scope])
            @objects = @objects.public_send(params[:scope].to_sym)
          end
        end

        as_chart, as_file = params[:chart_data], params[:send_data]
        unless as_chart || as_file
          if (columns = @model_config.list.exclude_columns)
            @objects = @objects.select_without(*columns)
          elsif (columns = @model_config.list.include_columns)
            columns = (columns << @model_config.abstract_model.primary_key.to_sym).uniq
            @objects = @objects.select(*columns)
          end
        end

        exists = @model_config.list.with(controller: self, list: @objects).exists?
        @objects = @objects.none unless exists

        respond_to do |format|
          format.html do
            if as_chart
              template = :chart
            else
              template = @action.template_name
            end
            render template, status: @status_code || :ok
          end

          format.js do
            if compact
              primary_key_method = @association ? @association.associated_primary_key : @model_config.abstract_model.primary_key
              label_method = @model_config.object_label_method
              render json: @objects.collect { |o| {value: o.send(primary_key_method).to_s, label: o.send(label_method).to_s} }, root: false
            else
              render @action.template_name, layout: false
            end
          end

          format.json do
            if as_chart
              charts = ChartExtractor.new(self, @abstract_model, @objects).extract_charts
              render json: charts
            else
              output = @objects.to_json(@schema)
              if as_file
                send_data output, filename: "#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.json"
              else
                render json: output
              end
            end
          end

          format.xml do
            output = @objects.to_xml(@schema)
            if as_file
              send_data output, filename: "#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.xml"
            else
              render xml: output
            end
          end

          format.csv do
            header, encoding, output = CSVConverter.new(self, @abstract_model, @objects, @schema).to_csv(params[:csv_options].to_unsafe_h)
            if as_file
              send_data output,
                type: "text/csv; charset=#{encoding}; #{'header=present' if header}",
                disposition: "attachment; filename=#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.csv"
            elsif Rails.version.to_s >= '5'
              # TODO https://coderwall.com/p/kad56a/streaming-large-data-responses-with-rails
              # https://medium.com/table-xi/stream-csv-files-in-rails-because-you-can-46c212159ab7
              # http://smsohan.com/blog/2013/05/09/genereating-and-streaming-potentially-large-csv-files-using-ruby-on-rails/
              render plain: output
            else
              render text: output
            end
          end
        end
      end
    end
  end
end