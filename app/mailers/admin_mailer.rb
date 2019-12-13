class AdminMailer < Devise::Mailer
    default from: 'no-reply@dp.gsu.edu'
    layout 'mailer'

    def new_user_waiting_for_approval(email)
      @email = email
      mail(to: 'jkong@gsu.edu', subject: 'New User Awaiting Admin Approval')
    end
end
