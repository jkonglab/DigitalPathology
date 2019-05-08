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


    @query
  end

  def to_ransack(context=nil)
    if context
      if query_params['annotation_label'].present?
        ransack = context.where('id IN (?)', (Annotation.where("label ILIKE ?", "%#{query_params['annotation_label']['s']}%").pluck(:image_id))).ransack(query)
      else
        ransack = context.ransack(query)
      end
    else
      if query_params['annotation_label'].present?
        ransack = Image.where('id IN (?)', (Annotation.where("label ILIKE ?", "%#{query_params['annotation_label']['s']}%").pluck(:image_id))).ransack(query)
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
