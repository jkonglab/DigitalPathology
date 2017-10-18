class QueryBuilder
  attr_reader :query_params, :params

  def initialize(params)
    @params = params.stringify_keys!
    @query_params = params
  end


  RESERVED_PARAMS = %w(s)

  def query
    return @query if @query.present?

    @query = {
      'processing_eq' => query_params['processing'].present? ? (query_params['processing'] == 'Complete' ? 0 : 1) : 0,
      'title_cont' => query_params['title']
    }

    reserved_params = [*Image.column_names, *query.keys, *RESERVED_PARAMS]
    meta_searchers = query_params.except(*reserved_params)

    if meta_searchers.present?
      array_matchers, value_matchers = meta_searchers.partition { |key, value| value.is_a?(Array) }
      @query[:meta_search] = value_matchers
      @query[:meta_array_containing] = array_matchers
    end

    @query
  end

  def to_ransack()
    ransack = Image.ransack(query)
    ransack.sorts = sort_order
    ransack
  end

  def sort_order
    if query['s'].present?
      query['s']
    else
      'images.created_at desc'
    end
  end

end
