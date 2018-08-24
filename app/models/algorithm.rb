class Algorithm < ActiveRecord::Base
	has_many :runs

	PARAMETER_TYPE_LOOKUP={
		"integer" => 1,
		"boolean" => 2,
		"string" => 3,
		"color" => 4,
		"select" => 5,
		"array" => 6,
		"float" => 7
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
		3 => "julia"
	}

	OUTPUT_TYPE_LOOKUP={
		"3d_volume" => 0,
		"contour" => 1,
		"scalar" => 2,
		"points" => 3,
		"percentage" => 4
	}

	INPUT_TYPE_LOOKUP={
		"2D" => 0,
		"3D" => 1
	}

	def title_with_type
		if self.input_type == Algorithm::INPUT_TYPE_LOOKUP["3D"] 
			"3D Algorithm: #{self.title}" 
		else 
			"2D Algorithm: #{self.title}"
		end
  	end

end