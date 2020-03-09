module ApplicationHelper
    def execute_statement(sql)
        results = ActiveRecord::Base.connection.execute(sql)
        if results.present?
            return results
        else
            return nil
        end
    end

    def link_to_add_fields(name, f, type)
      new_object = f.object.send "build_#{type}"
      id = "new_#{type}"
      fields = f.send("#{type}_fields", new_object, child_index: id) do |builder|
        render(type.to_s + "_fields", f: builder)
      end
      link_to(name, '#', class: "add_fields", data: {id: id, fields: fields.gsub("\n", "")})
    end

    def convert_to_svg_contour(contour, image)
        svg_data_string = ""

        contour.each do |point|
          point_x = point[0].to_i
          point_y = point[1].to_i
          vector_width = (((point_x).to_f / image.width) * 100)
          vector_height = (((point_y).to_f / image.height) * 100)

          if svg_data_string.length == 0
            svg_data_string += "M" + vector_width.to_s + ' ' + vector_height.to_s
          else
            svg_data_string += ' L' + vector_width.to_s + ' ' + vector_height.to_s
          end
        end

        svg_data_string += "Z"

        svg_data = ["path", {
          "fill"=> "none",
          "d"=> svg_data_string,
          "stroke"=> "lime",
          "stroke-width"=> 3,
          "stroke-linejoin"=> "round",
          "stroke-linecap"=> "round",
          "vector-effect"=> "non-scaling-stroke"
        }]

        return svg_data
      end

    def convert_to_svg_rect(points, width, height, image)
        svg_data = ["rect", {
          "fill"=> "none",
          "x"=> (((points[0].to_i).to_f / image.width) * 100),
          "y"=> (((points[1].to_i).to_f / image.height) * 100),
          "width"=> (((width.to_i).to_f / image.width) * 100),
          "height"=> (((height.to_i).to_f / image.height) * 100),
          "stroke"=> "lime",
          "stroke-width"=> 3,
          "stroke-linejoin"=> "round",
          "stroke-linecap"=> "round",
          "vector-effect"=> "non-scaling-stroke"
        }]
        return svg_data
    end
    
    def convert_to_svg_circle(points, radius, image)
        svg_data = ["circle", {
          "fill"=> "none",
          "cx"=> (((points[0].to_i).to_f / image.width) * 100),
          "cy"=> (((points[1].to_i).to_f / image.height) * 100),
          "r"=> (((radius.to_i).to_f / image.width) * 100),
          "stroke"=> "lime",
          "stroke-width"=> 3,
          "stroke-linejoin"=> "round",
          "stroke-linecap"=> "round",
          "vector-effect"=> "non-scaling-stroke"
        }]
        return svg_data
    end

      def resource_name
        :user
      end

      def resource
        @resource
      end

      def devise_mapping
        @devise_mapping ||= Devise.mappings[:user]
      end
end
