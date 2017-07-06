require 'byebug/core'

if Rails.env.development?
  Byebug.start_server 'localhost', 1048
end