class ApprovalMailer < Devise::Mailer
    default from: 'no-reply@dp.gsu.edu'
    layout 'mailer'

    def approval_notification(email)
      @email = email
      mail(to: email, subject: 'Your Account has been approved')
    end
end
