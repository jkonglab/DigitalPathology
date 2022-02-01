class DemoController < ApplicationController
    include ApplicationHelper
    respond_to :json, only: [:get_slice]
    def demo
        @demoID = 302
        @image = Image.find(302)
        @slices = Image.where(:parent_id => @image.id).order('slice_order asc')
        default_slice = (@slices.length.to_f/2).floor(0)-1
        @image_shown = @image.threed? && @image.parent_id.blank? ? @slices[default_slice] : @image
        puts "the image =>"
        puts @image
        puts "image_shown =>"
        puts @image_shown
        puts "slices =>"
        puts @slices
    end

    def get_slice
        puts "yo I am getting triggered"
        puts "@image.id =>"
        puts params[:demo_id]
        # puts @image.id
        # puts :demo_id
        # puts :slice
        @slice = Image.where(:parent_id => params[:demo_id]).order('slice_order asc')[params[:slice].to_i - 1]
        respond_with @slice
    end

    def show_3d
          @slices = Image.where(:parent_id => params[:demo_id]).order('slice_order asc')
      end
end