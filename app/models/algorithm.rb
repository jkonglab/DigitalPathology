class Algorithm < ActiveRecord::Base
	has_many :runs

	PARAMETER_TYPE_LOOKUP={
		"integer" => 1,
		"boolean" => 2,
		"string" => 3,
		"color" => 4,
		"select" => 5,
		"array" => 6,
		"float" => 7,
		"file" => 8
	}

	LANGUAGE_LOOKUP={
		"matlab" => 1,
		"python" => 2,
		"julia" => 3,
		"python3" => 4
	}

	LANGUAGE_LOOKUP_INVERSE={
		1 => "matlab",
		2 => "python",
		3 => "julia",
		4 => "python3"
	}

	OUTPUT_TYPE_LOOKUP={
		"3d_volume" => 0,
		"contour" => 1,
		"scalar" => 2,
		"points" => 3,
		"percentage" => 4,
		"image" => 5,
        "landmarks"=>6
	}

	REVERSE_OUTPUT_TYPE_LOOKUP={
		0 => '3d_volume',
		1 => 'contour',
		2 => 'scalar',
		3 => 'points',
		4 => 'percentage',
		5 => 'image',
        6 => 'landmarks'
	}

	INPUT_TYPE_LOOKUP={
		"2D" => 0,
		"3D" => 1
	}

	REVERSE_INPUT_TYPE_LOOKUP={
		0 => '2D',
		1 => '3D'
	}
	
	before_destroy :destroy_children


	def destroy_children
		self.runs.destroy_all
	end

	def title_with_type
		if self.input_type == Algorithm::INPUT_TYPE_LOOKUP["3D"] 
			"3D Algorithm: #{self.title}" 
		else 
			"2D Algorithm: #{self.title}"
		end
  	end

  	def parameters=(value)
  		value = value.present? ? JSON.parse(value) : []
  		super(value)
  	end

  	def multioutput_options=(value)
  		value = value.present? ? JSON.parse(value) : []
  		super(value)
	end
	  
	def custom_titles
		"#{self.title.slice! "CPU::"}"
		"#{self.title.slice! "- Step 3"}"
		return self.title
	end

end
