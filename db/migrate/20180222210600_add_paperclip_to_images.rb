class AddPaperclipToImages < ActiveRecord::Migration[4.2][5.1]
  def change
  	add_attachment :images, :file
  end
end
