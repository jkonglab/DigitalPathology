class Algorithm < ActiveRecord::Base
	has_many :runs

	PARAMETER_TYPE_LOOKUP={
		"numeric" => 1,
		"boolean" => 2
	}

	LANGUAGE_LOOKUP={
		"matlab" => 1,
		"python" => 2
	}

	LANGUAGE_LOOKUP_INVERSE={
		1 => "matlab",
		2 => "python"
	}

	OUTPUT_TYPE_LOOKUP={
		"contour" => 1,
		"scalar" => 2,
		"points" => 3
	}

end