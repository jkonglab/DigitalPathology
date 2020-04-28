class QueryBuilder
  attr_reader :query_params, :params

  def initialize(params)
    @params = params.stringify_keys
    @query_params = params
  end

  def query
    return @query if @query.present?

    reserved_params = ['title']
    @query = @query_params

    @query.keys.each do |key|
      if !reserved_params.include?(key) 
        @query[key+'_eq'] = @query[key]
      end
    end

    @query['title_cont'] = query_params['title']

    if query_params['processing'].present?
      @query['processing_eq'] = query_params['processing'] == 'Complete' ? 0 : 1
    end
    
    if query_params['image_type'].present?
        if query_params['image_type'] == '2D'
            @query['image_type_eq'] = 0
        elsif query_params['image_type'] == '3D'
            @query['image_type_eq'] = 1
        elsif query_params['image_type'] == '4D'
            @query['image_type_eq'] = 2
        end
    end

    @query
  end

  def to_ransack(context=nil)
    annotation_params = ["annotation_label", "annotation_class"]
    where_string = 'OR'
    i = 0
    annotation_params.each do |key|
        if query_params[key].present? and  query_params[key].fetch(:s, false) and query_params[key]['s'].present?
            i = i+1
        end
    end
    if i > 1
        where_string = 'AND'
    end
    if context
        if i>0
            ransack = context.where('id IN (?)', (Annotation.where("label = ? #{where_string} annotation_class = ?", "#{query_params['annotation_label']['s']}", "#{query_params['annotation_class']['s']}").pluck(:image_id))).ransack(query)
        else
            ransack = context.ransack(query)
        end
    else
        if i>0
            ransack = Image.where('id IN (?)', (Annotation.where("label = ? #{where_string} annotation_class = ?", "#{query_params['annotation_label']['s']}", "#{query_params['annotation_class']['s']}").pluck(:image_id))).ransack(query)
        else
            ransack = Image.ransack(query)
        end
    end
    ransack.sorts = sort_order
    ransack
  end

  def sort_order
    if query_params['s'].present?
      query_params['s']
    else
      'created_at desc'
    end
  end

end
